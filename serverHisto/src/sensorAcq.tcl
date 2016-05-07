
namespace eval ::sensorAcq {
    variable periodeAcq  [expr 1000 * 300]
    #variable periodeAcq  [expr 1000 * 5]
    variable bandeMorteAcq 0.01
}

# Utiliser pour initialiser la partie sensor
proc ::sensorAcq::init {logPeriode} {
    variable periodeAcq 

    for {set i 1} {$i < 32} {incr i} {
        set ::sensor(${i},value) ""
        set ::sensor(${i},value,1) ""
        set ::sensor(${i},value,2) ""
        set ::sensor(${i},type) ""
    }
    
    set ::subscriptionRunned(sensorAcq) 0

    set periodeAcq  [expr 1000 * $logPeriode]

}


proc ::sensorAcq::loop {} {

    variable periodeAcq
    variable bandeMorteAcq
    
    # On prend un abonnement sur les 32 premiers capteurs
    if {$::subscriptionRunned(sensorAcq) == 0} {
        # On lui demande les repères nécessaires (les 32 premiers) par abonnement
        set retErr 0
        for {set i 1} {$i < 32} {incr i} {
            incr retErr [::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(serverHisto) [incr ::TrameIndex] subscription ${i},value $periodeAcq $bandeMorteAcq"]
            incr retErr [::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(serverHisto) [incr ::TrameIndex] subscription ${i},type $periodeAcq"]
            
            # Les lignes suivantes marchent aussi !
            #::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(serverHisto) [incr ::TrameIndex] getRepere ${i},value,1"
            #::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(serverHisto) [incr ::TrameIndex] getRepere ${i},value,2"
            
            if {$retErr != 0} {
                break
            }
            
        }

        if {$retErr == 0} {
            set ::subscriptionRunned(sensorAcq) 1
            
            # On calcul le temps pour relancer la commande la minute d'après
            set seconds [string trimleft [clock format [clock seconds] -format "%S"] "0"]
            if {$seconds == ""} {set seconds 0}
            ::piLog::log [clock milliseconds] "debug" "::sensorAcq::loop : Premiere sauvegarde dans [expr (61 - $seconds)] secondes"
            after [expr (61 - $seconds) * 1000] ::sensorAcq::loop
            return 0
            
        } else {
            ::piLog::log [clock milliseconds] "warning" "::sensorAcq::loop : subscriptions are not done"
            
            after 1500 ::sensorAcq::loop
            
            return 0
        }
    } else {
    
        # Les abonnements sont pris 
        # Toute les minutes on sauvegarde les valeurs 
        
        ::sql::saveSensorsValues
        
        # On calcul le temps pour relancer la commande la minute d'après
        set seconds [string trimleft [clock format [clock seconds] -format "%S"] "0"]
        if {$seconds == ""} {set seconds 0}
        
        ::piLog::log [clock milliseconds] "debug" "::sensorAcq::loop : Prochaine sauvegarde dans [expr (61 - $seconds)] secondes"
        
        after [expr (61 - $seconds) * 1000] ::sensorAcq::loop
        
        
    }
}


proc ::sensorAcq::saveType {index type} {

    set toNotRegister 0

    switch $type {
        "temperature" -
        2 -
        SHT {
            set type 2
        }
        3 -
        DS18B20 {
            set type 3
        }
        6 -
        "niveau_cuve" -
        WATER_LEVEL {
            set type 6
        }
        8 -
        PH {
            set type 8
        }
        9 -
        EC {
            set type 9
        }
        ":" -
        OD {
            set type ":"
        }
        ";" -
        ORP {
            set type ";"
        }
        10 -
        "co2" {
            set type "10"
        }
        11 - 
        "pression_pompe" -
        "pression" {
            set type "11"
        }
        12 - 
        "humidite" {
            set type "12"
        }
        "DEFCOM" {
            set toNotRegister 1
            ::piLog::log [clock milliseconds] "debug" "_subscription response : type $type index $index not registered (DEFCOM)"
        }
        default {
            set toNotRegister 1
            ::piLog::log [clock milliseconds] "error" "_subscription response : unknow type $type"
        }
    }
    
    if {$toNotRegister == 0} {
        ::sql::updateSensorType $index $type
        ::piLog::log [clock milliseconds] "debug" "_subscription response : sensor type $type index $index registered"
    }
}
