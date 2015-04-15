# Init directory
set rootDir [file dirname [file dirname [info script]]]

# Read argv
set port(serverCultibox)  [lindex $argv 0]
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


# Initialisation d'un compteur pour les commandes externes envoyées
set TrameIndex 0

# On initialise la conf XML
array set configXML {
    verbose     debug
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

# Mise à jour des valeurs de capteurs
# Capteur 1 : 6 Mots envoyés Registre 10 , SHT 2 , T Haut 1 , T Bas 25 , H Haut 2 , H Bas 36
# /usr/local/sbin/i2cset -y 1 0x31 7 10 2 1 25 2 36 1 i
# Mise à jour de l'heure
# /usr/local/sbin/i2cset -y 1 0x31 8 1 15 4 11 10 23 25 1 i
/usr/local/sbin/i2cset -y 1 0x31 7

# /usr/local/sbin/i2cset -y 1 0x20 0x09 0x0F
# /usr/local/sbin/i2cget -y 1 0x20 0x09

vwait forever

# tclsh "C:\cultibox\04_CultiPi\01_Software\01_cultiPi\serverCultibox\serverCultibox.tcl" 6004 "C:\cultibox\04_CultiPi\02_conf\00_defaultConf_Win\serverCultibox\conf.xml" 6003 6000
# tclsh /opt/cultipi/serverCultibox/serverCultibox.tcl 6004 /etc/cultipi/01_defaultConf_RPi/./serverCultibox/conf.xml 6003 6000
