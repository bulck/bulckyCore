# Init directory
set rootDir [file dirname [file dirname [info script]]]

# Lecture des arguments : seul le path du fichier XML est donné en argument
set confXML                 [lindex $argv 0]

set moduleLocalName serverSupervision

# Load lib
lappend auto_path [file join $rootDir lib tcl]
package require piLog
package require piServer
package require piTools
package require piTime
package require piXML

# Chargement des fichiers externes
source [file join $rootDir ${::moduleLocalName} src serveurMessage.tcl]
source [file join $rootDir ${::moduleLocalName} src module_checkPing.tcl]
source [file join $rootDir ${::moduleLocalName} src module_report.tcl]
source [file join $rootDir ${::moduleLocalName} src module_checkSensor.tcl]
source [file join $rootDir ${::moduleLocalName} src module_sendInfos.tcl]

# Initialisation d'un compteur pour les commandes externes envoyées
set TrameIndex 0

# On initialise la conf XML
array set configXML {
    verbose             debug
    nbProcess           0
}

# Chargement de la conf XML
set RC [catch {
    array set configXML [::piXML::convertXMLToArray $confXML]
} msg]
if {$RC != 0} {
    ::piLog::log [clock milliseconds] "error" "$msg"
}

# On initialise la connexion avec le server de log
::piLog::openLog $::piServer::portNumber(serverLog) ${::moduleLocalName} $configXML(verbose)

::piLog::log [clock milliseconds] "info" "starting ${::moduleLocalName} - PID : [pid]"
::piLog::log [clock milliseconds] "info" "port ${::moduleLocalName} : $::piServer::portNumber(${::moduleLocalName})"
::piLog::log [clock milliseconds] "info" "confXML : $confXML"
# On affiche les infos dans le fichier de debug
foreach element [array names configXML] {
    ::piLog::log [clock milliseconds] "debug" "$element : $configXML($element)"
}

# Load server
::piLog::log [clock millisecond] "info" "starting serveur"
::piServer::start messageGestion $::piServer::portNumber(${::moduleLocalName})
::piLog::log [clock millisecond] "info" "serveur is started"

proc stopIt {} {
    ::piLog::log [clock milliseconds] "info" "Start stopping ${::moduleLocalName}"
    
    checkPing::stop
    
    set ::forever 0
    ::piLog::log [clock milliseconds] "info" "End stopping ${::moduleLocalName}"
    
    # Arrêt du server de log
    ::piLog::closeLog
    
    exit
}

# Pour chaque process, on crée les fonctions associées
foreach confFileName [glob -nocomplain -directory [file dirname $confXML] *.xml] {

    if {[file exists $confFileName] && [file tail $confFileName] !=  "conf.xml"} {
        # On charge le fichier de conf
        array set process_xml [::piXML::convertXMLToArray $confFileName]
        
        # Si il n'y a pas d'action définit, ce n'est pas normal
        if {[array names process_xml -exact action] == ""} {
            ::piLog::log [clock milliseconds] "error" "Can not create supervision process : file - $confFileName - Action is not defined"
            
        } else { 
            # En fonction de l'action a réaliser, on initialise le process
            $process_xml(action)::start [array get process_xml]
        }

        array unset process_xml
        
    } else {
        if {[file tail $confFileName] !=  "conf.xml"} {
            ::piLog::log [clock milliseconds] "error" "Can not create supervision process : file - $confFileName - doesnot exists"
        }
    }

}

# On lance le process d'envoi des infos 
sendInfos::start "nop"

vwait forever

# tclsh "D:\CBX\06_bulckyCore\serverSupervision\serverSupervision.tcl" "D:\CBX\06_bulckyCore\serverSupervision\confExample\conf.xml"
# tclsh /opt/cultipi/serverSupervision/serverSupervision.tcl /etc/cultipi/01_defaultConf_RPi/./serverSupervision/conf.xml
