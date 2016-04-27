# Init directory
set rootDir [file dirname [file dirname [info script]]]

# Lecture des arguments : seul le path du fichier XML est donné en argument
set confXML                 [lindex $argv 0]

set moduleLocalName serverPlugUpdate

# Global var for regulation
set regul(alarme) 0
# Variable qui mémorise les prise qui ont été mises à jour
set plug(updated) ""

# Load lib
lappend auto_path [file join $rootDir lib tcl]
package require piLog
package require piServer
package require piTools
package require piTime
package require piXML

# Chargement des fichiers externes
source [file join $rootDir ${::moduleLocalName} src emeteur.tcl]
source [file join $rootDir ${::moduleLocalName} src pluga.tcl]
source [file join $rootDir ${::moduleLocalName} src plugXX.tcl]
source [file join $rootDir ${::moduleLocalName} src sensor.tcl]
source [file join $rootDir ${::moduleLocalName} src serveurMessage.tcl]
source [file join $rootDir ${::moduleLocalName} src regulation.tcl]
source [file join $rootDir ${::moduleLocalName} src forcePlug.tcl]
source [file join $rootDir ${::moduleLocalName} src address_module.tcl]

# Chargement des différents modules de pilotage
source [file join $rootDir ${::moduleLocalName} src module_direct.tcl]
source [file join $rootDir ${::moduleLocalName} src module_wireless.tcl]
source [file join $rootDir ${::moduleLocalName} src module_CULTIPI.tcl]
source [file join $rootDir ${::moduleLocalName} src module_DIMMER.tcl]
source [file join $rootDir ${::moduleLocalName} src module_MCP230XX.tcl]
source [file join $rootDir ${::moduleLocalName} src module_XMAX.tcl]
source [file join $rootDir ${::moduleLocalName} src module_PCA9685.tcl]
source [file join $rootDir ${::moduleLocalName} src module_BULCKY.tcl]

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
    puts "${::moduleLocalName} [clock milliseconds] error $msg"
}

# On initialise la connexion avec le server de log
::piLog::openLog $::piServer::portNumber(serverLog) ${::moduleLocalName} $configXML(verbose)

::piLog::log [clock milliseconds] "info" "starting ${::moduleLocalName} - PID : [pid]"
::piLog::log [clock milliseconds] "debug" "port ${::moduleLocalName} : $::piServer::portNumber(${::moduleLocalName})"
::piLog::log [clock milliseconds] "debug" "confXML : $confXML"
# On affiche les infos dans le fichier de debug
foreach element [array names configXML] {
    ::piLog::log [clock milliseconds] "debug" "$element : $configXML($element)"
}

# Cette procédure permet d'afficher dans le fichier de log les erreurs qui sont apparues
proc bgerror {message} {
    ::piLog::log [clock milliseconds] error_critic "bgerror in [info script] $::argv -$message- "
    foreach elem [split $::errorInfo "\n"] {
        ::piLog::log [clock milliseconds] error_critic " * $elem"
    }
}


# Load server
::piLog::log [clock millisecond] "debug" "starting serveur"
::piServer::start messageGestion $::piServer::portNumber(${::moduleLocalName})
::piLog::log [clock millisecond] "debug" "serveur is started"

proc stopIt {} {
    ::piLog::log [clock milliseconds] "debug" "Start stopping ${::moduleLocalName}"
    set ::forever 0
    ::piLog::log [clock milliseconds] "info" "End stopping ${::moduleLocalName}"
    
    # Arrêt du server de log
    ::piLog::closeLog
}

# Load plug adress
set confPath [file dirname $confXML]
set plugaFileName [file join $confPath plg pluga]


# Parse pluga filename and send adress to module if needed
set EMETEUR_NB_PLUG_MAX [readPluga $plugaFileName]

# Chargement des paramètres de chaque prise
plugXX_load $confPath

# Pour chaque module utilisé, on l'initialise
foreach module [array names ::moduleSlaveUsed] {
    if {$module != "info" && $module != "NA" } {
        ::piLog::log [clock milliseconds] "info" "Module $module is used. So init it"
        ::${module}::init $::moduleSlaveUsed(${module})
    }
}

# initialisation de la partie émetteur
::piLog::log [clock milliseconds] "info" "emeteur_init"
emeteur_init
    
# Si le programme est déactivé
if {[::piTools::readArrayElem [array get ::configXML] programm_activ "on"] == "off"} {
    ::piLog::log [clock milliseconds] "info" "Programme desactive"
} else {


    # Initialisation de la partie lecture capteur
    ::piLog::log [clock milliseconds] "info" "::sensor::init"
    ::sensor::init

    # Boucle de régulation
    ::piLog::log [clock milliseconds] "info" "emeteur_update_loop"
    emeteur_update_loop

    # Boucle de lecture des capteurs
    ::piLog::log [clock milliseconds] "info" "::sensor::loop"
    ::sensor::loop
}


# Une fois la boucle de régulation démarrée , on peut activer le pilotage des prises (seulement si des prises wireless sont configurées)
if {[array names moduleSlaveUsed -exact wireless] != ""} {
    ::wireless::start
}

# Pour les client qui ont un abonnement événementiel aux données
emeteur_subscriptionEvenement

vwait forever

# tclsh "D:\CBX\06_bulckyCore\serverPlugUpdate\serverPlugUpdate.tcl" "D:\CBX\06_bulckyCore\serverPlugUpdate\confExample\conf.xml"
# tclsh /opt/cultipi/serverPlugUpdate/serverPlugUpdate.tcl /etc/cultipi/01_defaultConf_RPi/./serverPlugUpdate/conf.xml
