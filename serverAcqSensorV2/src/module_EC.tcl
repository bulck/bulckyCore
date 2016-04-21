
# set fh [open //./COM23  RDWR]
# fconfigure $fh -blocking 0 -mode 38400,n,8,1
# puts $fh "i"
# flush $fh 
# read $fh
# close $fh

namespace eval ::EC {

}

# Cette proc est utilisée pour initialiser les modules
proc ::EC::init {index} {

    # P,2 for a K1.0 E.C Sensor
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
    } msg]

    if {$RC != 0} {
        ::piLog::log [clock milliseconds] "error" "::EC::read Ouverture port $comPort $index erreur :$msg "
        return "NA"
    }
    
    # Lecture de la valeur précédente
    set err [catch {
        set value [read $fh]
    } msg]
    if {$RC != 0} {
        ::piLog::log [clock milliseconds] "error" "::EC::read Lecture valeure $comPort $index erreur :$msg "
        return "NA"
    }

    # demande de la prochaine la valeur
    set err [catch {
        puts $fh "r"
        flush $fh 
    } msg]
    if {$RC != 0} {
        ::piLog::log [clock milliseconds] "error" "::EC::read Envoie commande $comPort $index erreur :$msg "
        return "NA"
    }
    
    close $fh

    # On parse le résultat
    set result [split [string map {"?" ""} $value] ","]
    set goodValue [lindex $result 0]
    
    if {[string is double $goodValue]} {
        return $goodValue
    } else {
        return "NA"
    }

}
