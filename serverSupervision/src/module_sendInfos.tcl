package require http

namespace eval ::sendInfos {
    variable XMLprocess
    variable processID 0
    variable localIP 0
    variable localMAC 0
}

proc sendInfos::start {arrayIn} {
    variable XMLprocess
    variable processID

    # Save params
    array set XMLprocess [list \
        $processID,IDAfter    0 \
        $processID,localIP     "0" \
        $processID,localMAC    "0" \
    ]

    ::piLog::log [clock milliseconds] "info" "sendInfos::start !"
        
    # On démarre la boucle de vérification
    set XMLprocess($processID,IDAfter) [after 1000 [list ::sendInfos::check $processID]]
    
    incr processID
}

proc sendInfos::stop {} {
    variable XMLprocess
    variable processID
    
    for {set i 0} {$i < $processID} {incr i} {
        if  {$XMLprocess($i,IDAfter) != ""} {
            after cancel $XMLprocess($i,IDAfter)
        }
    }

}

proc sendInfos::getIP {} {

    # find out localhost's IP address
    # courtesy David Gravereaux, Heribert Dahms
    set TheServer [socket -server none -myaddr [info hostname] 0]
    set MyIP [lindex [fconfigure $TheServer -sockname] 0]
    close $TheServer

    return $MyIP

}

proc sendInfos::getMac {} {

    proc mac.section { iface_ptn ipv4_ptn allow deny section } {
        if { [llength $section] > 0 } {
            set mac_ptn {([0-9a-fA-F][0-9a-fA-F][\-:]){5}[0-9a-fA-F][0-9a-fA-F]}
            set mac ""
            set ip4 ""
            set iface ""
            set lno 0
            foreach s $section {
                if { $lno == 0 } {
                    if { [regexp $iface_ptn $s - i] } {
                        set iface $i
                    }
                }
                if { [regexp $mac_ptn $s m] } {
                    set mac $m
                }
                if { $ipv4_ptn ne "" && [regexp -nocase -- $ipv4_ptn $s - - i] } {
                    set ip4 $i
                }
                if { ($ip4 ne "" || $ipv4_ptn eq "" ) \
                         && $mac ne "" && $iface ne "" } {
                    foreach ptn $allow {
                        if { [regexp $ptn $iface] } {
                            set denied 0
                            foreach ptn $deny {
                                if { [regexp $ptn $iface] } {
                                    set denied 1
                                    break
                                }
                            }
                            if { ! $denied } {
                                return $mac
                            }
                        }
                    }
                }
                incr lno
            }
        }
        return ""
    }


    proc mac.gather { cmd iface_ptn ipv4_ptn allow deny } {
        set macs {}

        set section {}
        if { [catch {eval [linsert $cmd 0 exec]} res] == 0 } {
            foreach l [split $res "\n\r"] {
                if { [string trim $l] ne "" } {
                    if { ![string is space [string index $l 0]] } {
                        set mac [mac.section $iface_ptn $ipv4_ptn $allow $deny $section]
                        if { $mac ne "" } {
                            lappend macs $mac
                        }
                        set section {}
                        lappend section $l
                    } else {
                        lappend section [string trim $l]
                    }
                }
            }
            set mac [mac.section $iface_ptn $ipv4_ptn $allow $deny $section]
            if { $mac ne "" } {
                lappend macs $mac
            }
        }
        return $macs
    }


    proc mac { { type "bound" } } {
        global tcl_platform

        switch -nocase -glob -- $type {
            "bound" {
                if { $tcl_platform(platform) eq "windows" } {
                    return [mac.gather \
                                [concat [auto_execok ipconfig] /all] \
                                {(.*?):$} \
                                {.*ip.*?:\s*((\d{1,3}.){3}\d{1,3})} \
                                {{[Ee]thernet.*} {[Ww]ireless.*}} \
                                {}]
                } else {
                    return [mac.gather \
                                [concat [auto_execok ifconfig] -a] \
                                {^(\w+\d+)} \
                                {^(inet\s+addr:|inet\s+)((\d{1,3}.){3}\d{1,3})} \
                                {{eth\d+} {wlan\d+} {en\d+}} \
                                {}]
                }
            }
            "eth*" {
                if { $tcl_platform(platform) eq "windows" } {
                    return [mac.gather \
                                [concat [auto_execok ipconfig] /all] \
                                {(.*?):$} \
                                "" \
                                {{[Ee]thernet.*}} \
                                {{[Bb]luetooth}}]
                } else {
                    return [mac.gather \
                                [concat [auto_execok ifconfig] -a] \
                                {^(\w+\d+)} \
                                "" \
                                {{eth\d+} {en\d+}} \
                                {}]
                }
            }
            "wire*" -
            "wifi" {
                if { $tcl_platform(platform) eq "windows" } {
                    return [mac.gather \
                                [concat [auto_execok ipconfig] /all] \
                                {(.*?):$} \
                                "" \
                                {{[Ww]ireless.*}} \
                                {}]
                } else {
                    return [mac.gather \
                                [concat [auto_execok ifconfig] -a] \
                                {^(\w+\d+)} \
                                "" \
                                {{wlan\d+} {en\d+}} \
                                {}]
                }
            }
        }
    }
    return "[lindex [mac ethernet] 0]"
}


# Cette procédure vérifie que le ping 8.8.8.8 est bien fonctionnel. Dans le cas inverse, le système doit redémarrer
proc sendInfos::check {processID} {
    variable XMLprocess
    
    # On vient lire l'adresse IP et l'adresse MAC
    set newIP [sendInfos::getIP]
    set mac   [sendInfos::getMac]
    
    # Si l'adresse IP est différente, on envoit l'information
    if {$newIP != $XMLprocess($processID,localIP)} {
        ::piLog::log [clock milliseconds] "info" "sendInfos::check send new IP to send"
        
        set url {http://my.bulck.fr/cpi_register.php}
        
        ::http::geturl $url -query [::http::formatQuery user_cpi_mac $mac user_cpi_ip $newIP]
        
        # On sauvegarde l'info 
        set XMLprocess($processID,localMAC) $mac
        set XMLprocess($processID,localIP)  $newIP
    }
   
    set XMLprocess($processID,IDAfter) [after 1000 [list ::sendInfos::check $processID]]
}