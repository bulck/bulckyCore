# Init directory
set rootDir [file dirname [file dirname [info script]]]

# Lecture des arguments : seul le path du fichier XML est donné en argument
set confXML                 [lindex $argv 0]

set moduleLocalName serverHisto

# Load lib
lappend auto_path [file join $rootDir lib tcl]
package require piLog
package require piServer
package require piTools
package require piXML
package require piTime

# Chargement des fichiers externes
source [file join $rootDir ${::moduleLocalName} src plugAcq.tcl]
source [file join $rootDir ${::moduleLocalName} src sensorAcq.tcl]
source [file join $rootDir ${::moduleLocalName} src serveurMessage.tcl]
source [file join $rootDir ${::moduleLocalName} src sql.tcl]

# Initialisation d'un compteur pour les commandes externes envoyées
set TrameIndex 0
# On initialise la conf XML
array set configXML {
    verbose     debug
    pathMySQL   "c:/cultibox/xampp/mysql/bin/mysql.exe"
    logPeriode  60
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
# On affiche les infos dans le fichier de debug
foreach element [array names configXML] {
    ::piLog::log [clock milliseconds] "info" "$element : $configXML($element)"
}

# Cette procédure permet d'afficher dans le fichier de log les erreurs qui sont apparues
proc bgerror {message} {
    ::piLog::log [clock milliseconds] error_critic "bgerror in [info script] $::argv -$message- "
    foreach elem [split $::errorInfo "\n"] {
        ::piLog::log [clock milliseconds] error_critic " * $elem"
    }
}

# Load server
::piLog::log [clock millisecond] "info" "starting serveur"
::piServer::start messageGestion $::piServer::portNumber(${::moduleLocalName})
::piLog::log [clock millisecond] "info" "serveur is started"

proc stopIt {} {
    ::piLog::log [clock milliseconds] "info" "Start stopping ${::moduleLocalName}"
    set ::forever 0
    ::piLog::log [clock milliseconds] "info" "End stopping ${::moduleLocalName}"
    
    # Arrêt du server de log
    ::piLog::closeLog
    
    exit
}


# On sort les infos sur le fichier XML
::piLog::log [clock milliseconds] "info" "logperiode : $configXML(logPeriode)"
::piLog::log [clock milliseconds] "info" "pathMySQL  : $configXML(pathMySQL)"

# Le chemin vers l'exe de mySql
::sql::init $configXML(pathMySQL)

# On demande le port du serveur d'acquisition
::sensorAcq::init $configXML(logPeriode)

# On lance la boucle de mise à jour des capteurs
::sensorAcq::loop

# On demande le port du serveur de prise
::plugAcq::init

# On lance la boucle de mise à jour du serveur de prise
::plugAcq::loop

vwait forever

# tclsh "C:\cultibox\04_CultiPi\01_Software\01_cultiPi\serverHisto\serverHisto.tcl" 6003 "C:\cultibox\04_CultiPi\02_conf\00_defaultConf_Win\serverHisto\conf.xml" 6001