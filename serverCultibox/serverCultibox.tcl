# Init directory
set rootDir [file dirname [file dirname [info script]]]

# Read argv
set port(serverCultibox)    [lindex $argv 0]
set confXML                 [lindex $argv 1]
set port(serverLogs)        [lindex $argv 2]
set port(serverCultiPi)     [lindex $argv 3]

# Load lib
lappend auto_path [file join $rootDir lib tcl]
package require piLog
package require piServer
package require piTools
package require piTime
package require piXML

# Chargement des fichiers externes
source [file join $rootDir serverCultibox src serveurMessage.tcl]
source [file join $rootDir serverCultibox src sensorAcq.tcl]

# Initialisation d'un compteur pour les commandes externes envoyées
set TrameIndex 0

# On initialise la conf XML
array set configXML {
    verbose     debug
    updateFreq  6
}

# Chargement de la conf XML
set RC [catch {
    array set configXML [::piXML::convertXMLToArray $confXML]
} msg]
if {$RC != 0} {
    ::piLog::log [clock milliseconds] "error" "$msg"
}

# On initialise la connexion avec le server de log
::piLog::openLog $port(serverLogs) "serverCultibox" $configXML(verbose)

::piLog::log [clock milliseconds] "info" "starting serverCultibox - PID : [pid]"
::piLog::log [clock milliseconds] "info" "port serverCultibox : $port(serverCultibox)"
::piLog::log [clock milliseconds] "info" "confXML : $confXML"
::piLog::log [clock milliseconds] "info" "port serverLogs : $port(serverLogs)"
::piLog::log [clock milliseconds] "info" "port serverCultiPi : $port(serverCultiPi)"
# On affiche les infos dans le fichier de debug
foreach element [array names configXML] {
    ::piLog::log [clock milliseconds] "info" "$element : $configXML($element)"
}


proc bgerror {message} {
    ::piLog::log [clock milliseconds] error_critic "bgerror in $::argv - pid [pid] -$message-"
}

# Load server
::piLog::log [clock millisecond] "info" "starting serveur"
::piServer::start messageGestion $port(serverCultibox)
::piLog::log [clock millisecond] "info" "serveur is started"

proc stopIt {} {
    ::piLog::log [clock milliseconds] "info" "Start stopping serverCultibox"
    set ::forever 0
    ::piLog::log [clock milliseconds] "info" "End stopping serverCultibox"
    
    # Arrêt du server de log
    ::piLog::closeLog
}



proc updateHour {} {

    set actualHour [clock seconds]
    
    set year    [string trimleft [clock format $actualHour -format "%y"] "0"]
    set month   [string trimleft [clock format $actualHour -format "%m"] "0"]
    set day     [string trimleft [clock format $actualHour -format "%d"] "0"]
    set hour    [string trimleft [clock format $actualHour -format "%H"] "0"]
    set min     [string trimleft [clock format $actualHour -format "%M"] "0"]
    set sec     [string trimleft [clock format $actualHour -format "%S"] "0"]
    
    # Mise à jour de l'heure
    # /usr/local/sbin/i2cset -y 1 0x31 10 0 1 15 4 11 10 23 25 1 i
    set RC [catch {
        exec /usr/local/sbin/i2cset -y 1 0x31 0 11 0 1 $year $month $day $hour $min $sec 1 i
    } msg]
    if {$RC != 0} {
        ::piLog::log [clock milliseconds] "error" "updateHour : Cultibox does not respond :$msg "
    } else {
        ::piLog::log [clock milliseconds] "debug" "updateHour : Hour is updated"
    }
    
    after 2000 updateHour
}

proc updateSensorVal {sensor value1 value2} {

    # On calcul le numéro du registre
    set registre [expr 10 + $sensor - 1]
    set val11 [expr int ( floor ($value1 / 256) )]
    set val12 [expr $value1 % 256]
    
    set val21 [expr int ( floor ($value2 / 256) )]
    set val22 [expr $value2 % 256]
    
    # Mise à jour des valeurs de capteurs
    # Capteur 1 : 0 6 Mots envoyés Registre 0 10 , SHT 2 , T Haut 1 , T Bas 25 , H Haut 2 , H Bas 36
    # /usr/local/sbin/i2cset -y 1 0x31 9 0 10 2 1 25 2 36 1 i
    set RC [catch {
        exec /usr/local/sbin/i2cset -y 1 0x31 0 10 0 $registre $::sensor($sensor,type) $val11 $val12 $val21 $val22 1 i
    } msg]
    if {$RC != 0} {
        ::piLog::log [clock milliseconds] "error" "updateHour : Cultibox does not respond :$msg "
    } else {
        ::piLog::log [clock milliseconds] "debug" "updateHour : Sensor value is updated is updated"
    }
    
    after 2000 updateHour

}

# On demande le port du serveur d'acquisition
::sensorAcq::init $configXML(updateFreq)

# On lance la boucle de mise à jour des capteurs
::sensorAcq::loop

# On lance la mise à l'heure de la Cultibox
updateHour


vwait forever

# tclsh "D:\CBX\cultipiCore\serverCultibox\serverCultibox.tcl" 6004 "C:\cultibox\04_CultiPi\02_conf\00_defaultConf_Win\serverCultibox\conf.xml" 6003 6000
# tclsh /opt/cultipi/serverCultibox/serverCultibox.tcl 6004 /etc/cultipi/01_defaultConf_RPi/./serverCultibox/conf.xml 6003 6000
