# Init directory
set rootDir [file dirname [file dirname [info script]]]

# Lecture des arguments : seul le path du fichier XML est donné en argument
set confXML                 [lindex $argv 0]

set moduleLocalName serverAcqSensorV2

# Global var for regulation
set regul(alarme) 0

# Load lib
lappend auto_path [file join $rootDir lib tcl]
package require piLog
package require piServer
package require piTools
package require piXML

# Source extern files
source [file join $rootDir ${::moduleLocalName} src serveurMessage.tcl]
source [file join $rootDir ${::moduleLocalName} src module_ADS1015.tcl]
source [file join $rootDir ${::moduleLocalName} src module_CO2.tcl]
source [file join $rootDir ${::moduleLocalName} src module_DIRECT.tcl]
source [file join $rootDir ${::moduleLocalName} src module_I2C.tcl]
source [file join $rootDir ${::moduleLocalName} src module_MCP230XX.tcl]
source [file join $rootDir ${::moduleLocalName} src module_NETWORK.tcl]
source [file join $rootDir ${::moduleLocalName} src module_USBSERIAL.tcl]

# Initialisation d'un compteur pour les commandes externes envoyées
set TrameIndex 0
set SubscriptionIndex 0

# On initialise les variables globales appelable depuis l'extérieur
set ::sensor(firsReadDone) 0

# On initialise la conf XML
array set configXML {
    verbose         debug
    simulator       off
    nbSensor        10
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


# Cette procédure permet d'afficher dans le fichier de log les erreurs qui sont apparues
proc bgerror {message} {
    ::piLog::log [clock milliseconds] error_critic "bgerror in [info script] $::argv -$message- "
    foreach elem [split $::errorInfo "\n"] {
        ::piLog::log [clock milliseconds] error_critic " * $elem"
    }
}

# Load server
::piLog::log [clock millisecond] "info" "starting serveur port $::piServer::portNumber(${::moduleLocalName})"
::piServer::start messageGestion $::piServer::portNumber(${::moduleLocalName})
::piLog::log [clock millisecond] "info" "serveur is started"

proc stopIt {} {
    ::piLog::log [clock milliseconds] "info" "Start stopping ${::moduleLocalName}"
    set ::forever 0
    ::piLog::log [clock milliseconds] "info" "End stopping ${::moduleLocalName}"
    
    # Arrêt du server de log
    ::piLog::closeLog
}

# On vient initialiser tous les modules 
for {set i 1} {$i <= $configXML(nbSensor)} {incr i} {
    set module          $configXML(sensor,$i,type)
    set indexModule     $configXML(sensor,$i,index)
    
    ::piLog::log [clock milliseconds] "info" "Sensor $i : Module $module is used (index $indexModule) . So init it"
    ::${module}::init $indexModule  
        
}


# On charge le simulateur uniquement si c'est définit le fichier XML
if {$configXML(simulator) != "off"} {
    source [file join $rootDir ${::moduleLocalName} src simulator.tcl]
    
    # Initialisation du simulateur 
    ::simulateur::init
}


# Initialisation pour tous les capteurs des valeurs
set sensorTypeList [list SHT DS18B20 WATER_LEVEL PH EC OD ORP]

for {set index 1} {$index <= $::configXML(nbSensor)} {incr index} {

    # On ajoute un repère pour factoriser par numéro de capteur
    set ::sensor($index,value,1) "DEFCOM"   ;# Valeur de la premiere donnée du capteur
    set ::sensor($index,value,2) "DEFCOM"   ;# Valeur de la deuxième donnée du capteur
    set ::sensor($index,value)   "DEFCOM"   ;# Assemblage des deux valeurs du capteurs
    set ::sensor($index,value,time) ""      ;# Heure de lecture de la donnée
    set ::sensor($index,type) ""            ;# Type du capteur (SHT, DS18B20 ...)
}


# Boucle de lecture des capteurs
set indexForSearchingSensor 0
proc readSensors {} {

    # On vient lire chaque capteur 
    for {set i 1} {$i <= $::configXML(nbSensor)} {incr i} {
    
        set module          $::configXML(sensor,$i,type)
        set indexModule     $::configXML(sensor,$i,index)
        
        # On vient lire le capteur
        set value [::${module}::read $indexModule $i]
        
        
        if {$value == "NA"} {
            set ::sensor($i,value)   ""
            set ::sensor($i,value,1) ""
        } else {
            set ::sensor($i,value)      $value
            set ::sensor($i,value,1)    $value
            set ::sensor($i,type)       $module
            set ::sensor($i,value,time) [clock milliseconds]
        }
    
    }

    # Une fois l'ensemble lu, on l'indique
    set ::sensor(firsReadDone) 1
    
    # On recherche après 2.5 seconde
    after 2500 readSensors
}

# On lit la valeur des capteurs
readSensors

vwait forever

# tclsh /opt/bulckypi/serverAcqSensorV2/serverAcqSensorV2.tcl /etc/bulckypi/01_defaultConf_RPi/serverAcqSensorV2/conf.xml
# tclsh "D:\CBX\06_bulckyCore\serverAcqSensorV2\serverAcqSensorV2.tcl" "D:\CBX\06_bulckyCore\serverAcqSensorV2\confExample\conf.xml"
# tclsh "D:\CBX\06_bulckyCore\serverAcqSensorV2\serverAcqSensorV2.tcl" "D:\CBX\06_bulckyCore\_conf\00_defaultConf_Win\serverAcqSensorV2\conf.xml"