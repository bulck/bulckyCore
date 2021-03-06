# Pour que �a marche, ajouter dans la conf :
#  <item name="direct_read,1,input" input="1" />
#  <item name="direct_read,1,value" value="1" />
#  <item name="direct_read,1,input2" input="2" />
#  <item name="direct_read,1,value2" value="2" />
#  <item name="direct_read,1,type" type="CUVE" />

namespace eval ::direct_read {
    variable pin
    set pin(1,GPIO) 16
    set pin(1,init) 0
    set pin(2,GPIO) 20
    set pin(2,init) 0
    set pin(3,GPIO) 21
    set pin(3,init) 0
    set pin(4,GPIO) 26
    set pin(4,init) 0
    set pin(5,GPIO) 19
    set pin(5,init) 0
    set pin(6,GPIO) 13
    set pin(6,init) 0
    set pin(7,GPIO) 6
    set pin(7,init) 0
    set pin(8,GPIO) 5
    set pin(8,init) 0
    
    # Pin 1 bis
    set pin(10,GPIO) 23
    set pin(10,init) 0
    # Pin 2 bis
    set pin(11,GPIO) 24
    set pin(11,init) 0

    set errorMessage(read,1) ""
    set errorMessage(read,2) ""
    set errorMessage(read,3) ""
    set errorMessage(read,4) ""
    set errorMessage(read,5) ""
    set errorMessage(read,6) ""
    set errorMessage(read,7) ""
    set errorMessage(read,8) ""
    
}

# Cette proc est utilis�e pour initialiser les variables
proc ::direct_read::init {nb_maxSensor} {

    for {set i 1} {$i <= $nb_maxSensor} {incr i} {
        if {[array get ::configXML direct_read,$i,input] == ""} {
            set ::configXML(direct_read,$i,input) "NA"
        } elseif {$::configXML(direct_read,$i,input) == ""} {
            set ::configXML(direct_read,$i,input) "NA"
        }
        if {[array get ::configXML direct_read,$i,value] == ""} {
            set ::configXML(direct_read,$i,value) "NA"
        } elseif {$::configXML(direct_read,$i,value) == ""} {
            set ::configXML(direct_read,$i,value) "NA"
        }
        
        if {[array get ::configXML direct_read,$i,statusOK] == ""} {
            set ::configXML(direct_read,$i,statusOK) "1"
        } elseif {$::configXML(direct_read,$i,statusOK) == ""} {
            set ::configXML(direct_read,$i,statusOK) "NA"
        }
        
        if {[array get ::configXML direct_read,$i,input2] == ""} {
            set ::configXML(direct_read,$i,input2) "NA"
        } elseif {$::configXML(direct_read,$i,input2) == ""} {
            set ::configXML(direct_read,$i,input2) "NA"
        }
        
        if {[array get ::configXML direct_read,$i,value2] == ""} {
            set ::configXML(direct_read,$i,value2) "NA"
        } elseif {$::configXML(direct_read,$i,value2) == ""} {
            set ::configXML(direct_read,$i,value2) "NA"
        }
        
        if {[array get ::configXML direct_read,$i,statusOK2] == ""} {
            set ::configXML(direct_read,$i,statusOK2) "1"
        } elseif {$::configXML(direct_read,$i,statusOK2) == ""} {
            set ::configXML(direct_read,$i,statusOK2) "NA"
        }
        
        if {[array get ::configXML direct_read,$i,type] == ""} {
            set ::configXML(direct_read,$i,type) "NA"
        } elseif {$::configXML(direct_read,$i,type) == ""} {
            set ::configXML(direct_read,$i,type) "NA"
        }
    }
}

# Cette proc est utlis�e pour initialiser la pin en sortie
proc ::direct_read::initPin {pinIndex} {
    variable pin

    # On d�finit la pin en sortie
    set RC [catch {
        exec gpio -g mode $pin($pinIndex,GPIO) in
    } msg]
    if {$RC != 0} {::piLog::log [clock milliseconds] "error" "::direct_read::initPin Not able to defined pin $pin($pinIndex,GPIO) as input -$msg-"}
    
    set pin($pinIndex,init) 1
    
}


proc ::direct_read::read_value {input} {
    variable pin
    variable errorMessage

    
    # S'il elle n'est pas initialis�e, on le fait
    if {$pin($input,init) == 0} {
        initPin $input
    }

    set value "NA"
    set RC [catch {
        set value [exec gpio -g read $pin($input,GPIO)]
    } msg]

    if {$RC != 0} {
        if {$errorMessage(read,$input) == ""} {
            ::piLog::log [clock milliseconds] "error" "::direct_read::read_value default when reading value of input $input (GPIO : $pin($input,GPIO)) message:-$msg-"
        }
        set errorMessage(read,$input) "error is already send"
    } else {
        ::piLog::log [clock milliseconds] "debug" "::direct_read::read_value input $input (GPIO : $pin($input,GPIO)) value $value"
        set errorMessage(read,$input) ""
    }
    
    return $value
}
