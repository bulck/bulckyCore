# Init directory
set rootDir [file dirname [file dirname [info script]]]

# Read argv
set port(serverSupervision)  [lindex $argv 0]
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
source [file join $rootDir serverSupervision src serveurMessage.tcl]
source [file join $rootDir serverSupervision src module_checkGoogle.tcl]

# Initialisation d'un compteur pour les commandes externes envoyées
set TrameIndex 0

# On initialise la conf XML
array set configXML {
    verbose             debug
    checkGoogle,start   0
    checkGoogle,IP      8.8.8.8
    checkGoogle,timeMax 30
}

# Chargement de la conf XML
set RC [catch {
    array set configXML [::piXML::convertXMLToArray $confXML]
} msg]
if {$RC != 0} {
    ::piLog::log [clock milliseconds] "error" "$msg"
}

# On initialise la connexion avec le server de log
::piLog::openLog $port(serverLogs) "serverSupervision" $configXML(verbose)

::piLog::log [clock milliseconds] "info" "starting serverSupervision - PID : [pid]"
::piLog::log [clock milliseconds] "info" "port serverSupervision : $port(serverSupervision)"
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
::piServer::start messageGestion $port(serverSupervision)
::piLog::log [clock millisecond] "info" "serveur is started"

proc stopIt {} {
    ::piLog::log [clock milliseconds] "info" "Start stopping serverSupervision"
    checkGoogle::stop
    set ::forever 0
    ::piLog::log [clock milliseconds] "info" "End stopping serverSupervision"
    
    # Arrêt du server de log
    ::piLog::closeLog
}

# On démarre la vérification google
if {$configXML(checkGoogle,start) != 0} {
    checkGoogle::start $configXML(checkGoogle,IP) $configXML(checkGoogle,timeMax)
}

vwait forever

# tclsh "D:\CBX\cultipiCore\serverSupervision\serverSupervision.tcl" 6004 "D:\CBX\cultipiCore\serverSupervision\confExample\conf.xml" 6003 6000
# tclsh /opt/cultipi/serverSupervision/serverSupervision.tcl 6004 /etc/cultipi/01_defaultConf_RPi/./serverSupervision/conf.xml 6003 6000
