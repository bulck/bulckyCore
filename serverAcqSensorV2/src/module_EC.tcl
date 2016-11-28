
# set fh [open //./COM23  RDWR]
# set fh [open /dev/ttyUSB0  RDWR]
# fconfigure $fh -blocking 0 -mode 38400,n,8,1
# puts -nonewline $fh "i\r"
# puts -nonewline $fh "r\r"
# flush $fh 
# read $fh
# close $fh


namespace eval ::EC {

}

# Cette proc est utilisée pour initialiser les modules
proc ::EC::init {index} {

    # P,2 for a K1.0 E.C Sensor
}

proc ::EC::serial_receiver {chan sensorIdx} {
    if { [eof $chan] } {
        ::piLog::log [clock milliseconds] "error" "::EC::serial_receiver Fermeture port "
        catch {close $chan}
        return
    }
    after 200
    set data [string trim [::read $chan]]
    
    ::piLog::log [clock milliseconds] "debug" "::EC::serial_receiver recu $data "
    
    # On parse le résultat
    set result [split [string map {"?" ""} $data] ","]
    set goodValue [lindex $result 0]
    
    if {[string is double $goodValue] && $goodValue != 0 && $goodValue < 1000} {
        set goodValue [expr round($goodValue)]
        set ::sensor($sensorIdx,value)      $goodValue
        set ::sensor($sensorIdx,value,1)    $goodValue
        set ::sensor($sensorIdx,type)       $::configXML(sensor,$sensorIdx,nom)
        set ::sensor($sensorIdx,value,time) [clock milliseconds]
    }
    
    close $chan
}

proc ::EC::read {index sensor} {

    set comPort   $::configXML(sensor,${sensor},comPort)
    set version   $::configXML(sensor,${sensor},version)

    set speedComPort 38400
    if {$version == "EZO"} {
        set speedComPort 9600
    }
    
    if {$comPort == ""} {
        ::piLog::log [clock milliseconds] "error" "::EC::read Port com non définit"
        return "NA"
    }

    # Ouverture d'un port COM
    set err [catch {
        set fh [open $comPort RDWR]
        fconfigure $fh -blocking 0 -mode $speedComPort,n,8,1
        fileevent $fh readable [list ::EC::serial_receiver $fh $sensor]
    } msg]

    if {$err != 0} {
        ::piLog::log [clock milliseconds] "error" "::EC::read Ouverture port $comPort $index erreur :$msg "
        return "NA"
    }
    
    # demande de la prochaine la valeur
    set err [catch {
        puts -nonewline $fh "r\r";flush $fh
    } msg]
    if {$err != 0} {
        ::piLog::log [clock milliseconds] "error" "::EC::read Envoie commande $comPort $index erreur :$msg "
        return "NA"
    }
    
    return "OK"
}
