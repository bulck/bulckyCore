# Pour lancer l'automatisation : tclsh /home/sdf/Bureau/program/progam.tcl
# Pour arreter : Ctrl + C

# Lecture des arguments : seul le path du fichier XML est donné en argument
set confXML                 [lindex $argv 0]

set moduleLocalName serverTrigger

# Load lib
set rootDir [file dirname [file dirname [info script]]]

# Load lib
lappend auto_path [file join $rootDir lib tcl]
package require piLog
package require piServer
package require piTools
package require piXML

source [file join $rootDir ${::moduleLocalName} src serveurMessage.tcl]


# Initialisation d'un compteur pour les commandes externes envoyées
set TrameIndex 0
# On initialise la conf XML
array set configXML {
    verbose     debug
}

if {[file exists $confXML] != 1} {
    # Le fichier de conf n'exists pas, on meurt tranquillement
    puts "[clock milliseconds] info ${::moduleLocalName} Conf file ($confXML) does not exists. Bye Bye !"
    exit
}

# Chargement de la conf XML
set RC [catch {
    array set configXML [::piXML::convertXMLToArray $confXML]
} msg]
if {$RC != 0} {
    puts "[clock milliseconds] info ${::moduleLocalName} [clock milliseconds] error $msg"
}

# On initialise la connexion avec le server de log
::piLog::openLog $::piServer::portNumber(serverLog) ${::moduleLocalName} $configXML(verbose)

::piLog::log [clock milliseconds] "info" "starting ${::moduleLocalName} - PID : [pid]"
::piLog::log [clock milliseconds] "info" "port ${::moduleLocalName} : $::piServer::portNumber(${::moduleLocalName})"
::piLog::log [clock milliseconds] "info" "confXML : $confXML"
# On affiche les infos dans le fichier de debug
foreach element [lsort [array names configXML]] {
    ::piLog::log [clock milliseconds] "debug" "$element : $configXML($element)"
}

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

# On commence par prendre un abonnement sur tous les capteurs dont on a besoin
for {set state 1} {$state <= $configXML(nbEtat)} {incr state} {

    if {$configXML(etat,${state},condition,type) == "sensor"} {
        
        set sensorIndex $configXML(etat,2,condition,sensor)
        
        # On prend un abonnement
        set retErr 1
        while {$retErr != 0} {
            set retErr 0

            incr retErr [::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(${::moduleLocalName}) [incr ::TrameIndex] subscription ${sensorIndex},value,1 100"]
            if {$retErr == 0} {
                incr retErr [::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(${::moduleLocalName}) [incr ::TrameIndex] subscription ${sensorIndex},value,2 100"]
            }
            
            # On initialise la variable
            set ::sensor(${sensorIndex},value,1) ""
            set ::sensor(${sensorIndex},value,2) ""

            if {$retErr != 0} {
                ::piLog::log [clock milliseconds] "warning" "Coudnot take subscription of sensor $sensorIndex "
                
                # Si on a pas réussi, on attend un peu
                after 1000
            } else {
                ::piLog::log [clock milliseconds] "debug" "Oh Yeah ! take subscription of sensor $sensorIndex "
            }
            after 200
            update
        }
    }
}



set actualState 1

while {$actualState <= $configXML(nbEtat)} {

    # On initialise avec le premier état
    ::piLog::log [clock milliseconds] "info" "Initialisation state $actualState"
    for {set act 1} {$act <=  $configXML(etat,${actualState},nbAction)} {incr act} {
        switch $configXML(etat,${actualState},action,${act},type) {
            "plug" {
                set priseNumero [lindex $configXML(etat,${actualState},action,${act},value) 0]
                set priseEtat [lindex $configXML(etat,${actualState},action,${act},value) 1]
                ::piLog::log [clock milliseconds] "info" "Set plug $priseNumero to $priseEtat"
                ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $priseNumero $priseEtat 86399" localhost
            }
            default {
                ::piLog::log [clock milliseconds] "error" "Action $configXML(etat,${actualState},action,${act},type) is not recognized"
            }
        }
    }

    # Attente condition
    switch $configXML(etat,${actualState},condition,type) {
        "time_ms" {
            set time $configXML(etat,${actualState},condition,value)
            ::piLog::log [clock milliseconds] "info" "Wait $time before next action"
            after $time
        } 
        "sensor" {
            set sensorT $configXML(etat,${actualState},condition,sensor)
            set neededValue $configXML(etat,${actualState},condition,value)
            
            set count 0 
            while {$::sensor(${sensorT},value,1) != $neededValue} {
                after 10
                update
                incr count
                if {[expr $count % 100] == 0} {
                    ::piLog::log [clock milliseconds] "info" "Wait sensor $sensorT to be $neededValue"
                }
            }
        }
        default {
            ::piLog::log [clock milliseconds] "error" "Condition $configXML(etat,${actualState},condition,type) is not recognized"
        }
    }
    
    incr actualState

}


update

vwait forever

# Lancement 
# tclsh D:\CBX\06_bulckyCore\serverTrigger\serverTrigger.tcl" "D:\CBX\06_bulckyCore\serverTrigger\confExample\conf.xml" 
# tclsh /home/sdf/Bureau/cultipiCore/serverIrrigation/serverIrrigation.tcl "/home/sdf/Bureau/cultipiCore/serverIrrigation/confExample/conf.xml" 