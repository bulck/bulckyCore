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
source [file join $rootDir ${::moduleLocalName} src module_USBSERIAL.tcl]
source [file join $rootDir ${::moduleLocalName} src module_MCP230XX.tcl]

# Initialisation d'un compteur pour les commandes externes envoyées
set TrameIndex 0
set SubscriptionIndex 0

# On initialise les variables globales appelable depuis l'extérieur
set ::sensor(firsReadDone) 0

# On initialise la conf XML
array set configXML {
    verbose         debug
    simulator       off
    nb_maxSensor    10
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
}

# On vient initialiser tous les modules 
for {set i 1} {$i <= $configXML(nbSensor)} {incr i} {
    set module          $configXML(sensor,$i,type)
    set indexModule     $configXML(sensor,$i,index)
    
    ::piLog::log [clock milliseconds] "info" "Module $module is used. So init it"
    ::$module::init $indexModule  
        
}


# On charge le simulateur uniquement si c'est définit le fichier XML
if {$configXML(simulator) != "off"} {
    source [file join $rootDir ${::moduleLocalName} src simulator.tcl]
    
    # Initialisation du simulateur 
    ::simulateur::init
}


# Initialisation pour tous les capteurs des valeurs
set sensorTypeList [list SHT DS18B20 WATER_LEVEL PH EC OD ORP]

for {set index 1} {$index <= $configXML(nbSensor)} {incr index} {

    # Si ce capteur peut exister
    if {[array names ::sensor -exact "${sensorType},$index,adress"] != ""} {
    
        set ::sensor($sensorType,$index,value,1) ""
        set ::sensor($sensorType,$index,value,2) ""
        set ::sensor($sensorType,$index,updateStatus) "INIT"
        set ::sensor($sensorType,$index,commStatus) "DEFCOM"
        set ::sensor($sensorType,$index,majorVersion) ""
        set ::sensor($sensorType,$index,minorVersion) ""
        set ::sensor($sensorType,$index,connected) 0
        set ::sensor($sensorType,$index,nbProblemRead) 0
    }
    
    # On ajoute un repère pour factoriser par numéro de capteur
    set ::sensor($index,value,1) "" ;# Valeur de la premiere donnée du capteur
    set ::sensor($index,value,2) "" ;# Valeur de la deuxième donnée du capteur
    set ::sensor($index,value) ""   ;# Assemblage des deux valeurs du capteurs
    set ::sensor($index,value,time) ""   ;# Heure de lecture de la donnée
    set ::sensor($index,type) ""    ;# Type du capteur (SHT, DS18B20 ...)
}


# Boucle de lecture des capteurs
set indexForSearchingSensor 0
proc readSensors {} {

    # On vient lire chaque capteur 
    for {set i 1} {$i <= $configXML(nbSensor)} {incr i} {
    
        set module          $configXML(sensor,$i,type)
        set indexModule     $configXML(sensor,$i,index)
        
        # On vient lire le capteur
        ::$module::read $indexModule
    
    }

    set sensorTypeList [list SHT DS18B20 WATER_LEVEL PH EC OD ORP]
    
    foreach sensorType $sensorTypeList {
    
        for {set index 1} {$index  <= $::configXML(nb_maxSensor)} {incr index} {
        
            # Si ce capteur peut exister
            if {[array names ::sensor -exact "${sensorType},$index,adress"] != ""} {
            
                # On vérifie s'il est connecté
                if {$::sensor($sensorType,$index,connected) == 1} {
                
                    # Pour lire la valeur d'un capteur, on s'y prend à deux fois :
                    # - On écrit la valeur du registre qu'on veut lire
                    # - On lit le registre
                    set moduleAdress $::sensor($sensorType,$index,adress)
                    set register     $::SENSOR_GENERIC_HP_ADR

                    set valueHP ""
                    set valueLP ""
                    set RC [catch {
                        exec /usr/local/sbin/i2cset -y 1 $moduleAdress $::SENSOR_GENERIC_HP_ADR
                        set valueHP [exec /usr/local/sbin/i2cget -y 1 $moduleAdress]
                        
                        exec /usr/local/sbin/i2cset -y 1 $moduleAdress $::SENSOR_GENERIC_LP_ADR
                        set valueLP [exec /usr/local/sbin/i2cget -y 1 $moduleAdress]
                    } msg]

                    if {$RC != 0} {
                        set ::sensor($sensorType,$index,updateStatus) "DEFCOM"
                        set ::sensor($sensorType,$index,updateStatusComment) ${msg}
                        set ::sensor($index,value,1) ""
                        
                        # On demande un reboot du logiciel dans ce cas au bout du cinquieme probleme
                        incr ::sensor($sensorType,$index,nbProblemRead)
                        
                        ::piLog::log [clock milliseconds] "warning" "default when reading valueHP of sensor $sensorType index $index (adress module : $moduleAdress - register $register) (try $::sensor($sensorType,$index,nbProblemRead) / 5) message:-$msg-"

                    } else {
                        set computedValue [expr ($valueHP * 256 + $valueLP) / 100.0]
                        
                        # Seulement si la valeur est cohérente
                        if {$computedValue < 100 && $computedValue > -30} {
                            set ::sensor($sensorType,$index,value,1) $computedValue
                            set ::sensor($sensorType,$index,updateStatus) "OK"
                            set ::sensor($sensorType,$index,updateStatusComment) [clock milliseconds]
                            ::piLog::log [clock milliseconds] "debug" "sensor $sensorType,$index (@ $moduleAdress - reg $register) value 1 : $computedValue (raw $valueHP $valueLP)"
                            
                            # On sauvegarde dans le repère global
                            set ::sensor($sensorType,$index,nbProblemRead) 0
                            set ::sensor($index,value,1)    $computedValue
                            set ::sensor($index,value)      "$computedValue NULL"
                            set ::sensor($index,type)       $sensorType
                            set ::sensor($index,value,time) [clock milliseconds]
                        } else {
                            ::piLog::log [clock milliseconds] "warning" "Value 1 is not coherente : expr ($valueHP * 256 + $valueLP) / 100.0 : $computedValue"
                        }
                        
                    }
                    
                    if {$sensorType == "SHT" && $::sensor($sensorType,$index,nbProblemRead) == 0} {
                    
                        set moduleAdress $::sensor($sensorType,$index,adress)
                        set register     $::SENSOR_GENERIC_HP2_ADR

                        set valueHP ""
                        set valueLP ""
                        set RC [catch {
                            exec /usr/local/sbin/i2cset -y 1 $moduleAdress $::SENSOR_GENERIC_HP2_ADR
                            set valueHP [exec /usr/local/sbin/i2cget -y 1 $moduleAdress]
                            
                            exec /usr/local/sbin/i2cset -y 1 $moduleAdress $::SENSOR_GENERIC_LP2_ADR
                            set valueLP [exec /usr/local/sbin/i2cget -y 1 $moduleAdress]
                        } msg]

                        if {$RC != 0} {
                            set ::sensor($sensorType,$index,updateStatus) "DEFCOM"
                            set ::sensor($sensorType,$index,updateStatusComment) ${msg}
                            set ::sensor($index,value,2) ""
                            ::piLog::log [clock milliseconds] "warning" "default when reading valueHP of sensor $sensorType index $index (@ $moduleAdress - reg $register) message:-$msg-"
                        } else {
                       
                            set computedValue [expr ($valueHP * 256 + $valueLP) / 100.0]

                            # Seulement si la valeur est cohérente
                            if {$computedValue < 100 && $computedValue > -30} {
                                set ::sensor($sensorType,$index,value,2) $computedValue
                                set ::sensor($sensorType,$index,updateStatus) "OK"
                                set ::sensor($sensorType,$index,updateStatusComment) [clock milliseconds]
                                ::piLog::log [clock milliseconds] "debug" "sensor $sensorType,$index (@ $moduleAdress - reg $register) value 2 : $computedValue (raw $valueHP $valueLP)"
                                
                                # On sauvegarde dans le repère global
                                set ::sensor($index,value,2) $computedValue
                                set ::sensor($index,value) "$::sensor($index,value,1) $::sensor($index,value,2)"
                            } else {
                                ::piLog::log [clock milliseconds] "warning" "Value 2 is not coherente : expr ($valueHP * 256 + $valueLP) / 100.0 : $computedValue"
                            }
                        }
                    }
                    
                    # On demande un reboot du logiciel dans ce cas au bout du cinquième problème
                    if {$::sensor($sensorType,$index,nbProblemRead) > 5} {
                        ::piLog::log [clock milliseconds] "error" "Ask software cultipi reboot"
                        ::piServer::sendToServer $::piServer::portNumber(serverCultipi) "$::piServer::portNumber(${::moduleLocalName}) [incr ::TrameIndex] stop"
                        set ::sensor($sensorType,$index,nbProblemRead) 0
                    }
                }
            }
        }
    }
    
    # Lecture des capteurs en direct
    for {set sensorDirect 1} {$sensorDirect <= $::configXML(nb_maxSensor)} {incr sensorDirect} {
    
        set pin $::configXML(direct_read,$sensorDirect,input)

        # Si la valeur est demandé dans le fichier de config
        if {$pin != "NA"} {
            
            # On lit la valeur
            set value [::direct_read::read_value $pin]
            
            # SI la valeur est valide, on la sauvegarde
            if {[string is integer $value] && $value != ""} {
            
                # Si l'utilisateur a prédéfinie des valeurs, on les appliques
                if {$::configXML(direct_read,$sensorDirect,value) != "NA" &&
                    $value == $::configXML(direct_read,$sensorDirect,statusOK)} {
					set value $::configXML(direct_read,$sensorDirect,value)
                } else {
                    set value 0
                }
                # On sauvegarde dans le repère global
                set ::sensor($sensorDirect,value,1) $value
                set ::sensor($sensorDirect,value)   "$value NULL"
                set ::sensor($sensorDirect,type)    $::configXML(direct_read,$sensorDirect,type)
                set ::sensor($sensorDirect,value,time) [clock milliseconds]

            }
        }
        
        # L'utilisateur peut demander la lecture de deux capteurs
        set pin $::configXML(direct_read,$sensorDirect,input2)
    
        # Si la valeur est demandé dans le fichier de config
        if {$pin != "NA"} {
            
            # On lit la valeur
            set value [::direct_read::read_value $pin]
            
            # Si la valeur est valide, on la sauvegarde
            if {[string is integer $value] && $value != ""} {
                # Si l'utilisateur a prédéfinie des valeurs, on les appliques
                if {$::configXML(direct_read,$sensorDirect,value2) != "NA" && 
                    $value == $::configXML(direct_read,$sensorDirect,statusOK2)} {
                    set value $::configXML(direct_read,$sensorDirect,value2)
                } else {
                    set value 0
                }
           
                # On sauvegarde dans le repère global
                set sensor1Value $::sensor($sensorDirect,value,1)
                set ::sensor($sensorDirect,value,1) [expr $sensor1Value + $value]
                set ::sensor($sensorDirect,value)   "[expr $sensor1Value + $value] NULL"
                set ::sensor($sensorDirect,type)    $::configXML(direct_read,$sensorDirect,type)
                set ::sensor($sensorDirect,value,time) [clock milliseconds]

            }
        }
        
    }
    
    # Lecture du capteur de CO²
    ::sensor_co2::read_value

    
    # Une fois l'ensemble lu, on l'indique
    set ::sensor(firsReadDone) 1
    
    # On recherche après 2.5 seconde
    after 2500 readSensors
}

# On lit la valeur des capteurs
readSensors

vwait forever

# tclsh /opt/cultipi/serverAcqSensor/serverAcqSensor.tcl /etc/cultipi/01_defaultConf_RPi/serverAcqSensor/conf.xml
# tclsh "D:\CBX\06_bulckyCore\serverAcqSensor\serverAcqSensor.tcl" "D:\CBX\06_bulckyCore\serverAcqSensor\confExample\conf.xml"
# tclsh "D:\CBX\06_bulckyCore\serverAcqSensor\serverAcqSensor.tcl" "D:\CBX\06_bulckyCore\serverAcqSensor\confExample\conf_irrigation.xml"