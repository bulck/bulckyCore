
proc messageGestion {message networkhost} {

    # Trame standard : [FROM] [INDEX] [commande] [argument]
    set serverForResponse   [::piTools::lindexRobust $message 0]
    set indexForResponse    [::piTools::lindexRobust $message 1]
    set commande            [::piTools::lindexRobust $message 2]

    switch ${commande} {
        "stop" {
            ::piLog::log [clock milliseconds] "info" "Asked stop"
            stopIt
        }
        "pid" {
            ::piLog::log [clock milliseconds] "info" "Asked pid"
            ::piServer::sendToServer $serverForResponse "$::piServer::portNumber(${::moduleLocalName}) $indexForResponse _pid ${::moduleLocalName} [pid]" $networkhost
        }
        "getRepere" {
            # Pour toutes les variables demandées
            set indexVar 3
            set returnList ""
            while {[set variable [::piTools::lindexRobust $message $indexVar]] != ""} {
                # La variable est le nom de la variable à lire
                
                ::piLog::log [clock milliseconds] "debug" "Asked getRepere $variable"
                
                if {[info exists ::$variable] == 1} {
                
                    eval set returnValue $$variable

                    lappend returnList $returnValue
                } else {
                    ::piLog::log [clock milliseconds] "error" "Asked variable $variable - variable doesnot exists"
                }
                
                incr indexVar
            }

            ::piLog::log [clock milliseconds] "info" "response : $serverForResponse $indexForResponse _getRepere - $returnList - to $networkhost"
            ::piServer::sendToServer $serverForResponse "$serverForResponse $indexForResponse _getRepere $returnList" $networkhost
            
        }
        "setRepere" {
            set variable [::piTools::lindexRobust $message 3]
            set value [::piTools::lindexRobust $message 4]
            
            set ::${variable} $value

            ::piLog::log [clock milliseconds] "info" "Asked setRepere : force $variable to $value"
        }
        "subscriptionEvenement" {
            # Le numéro de prise est indiqué 
            set variable [::piTools::lindexRobust $message 3]
            set repere   [::piTools::lindexRobust $message 4]
            ::piLog::log [clock milliseconds] "info" "Asked subscriptionEvenement $variable - parametre $repere"
            
            # Les seuls abonnements autorisé sont plug(n,value)
            if {$variable == "plug"} {
                
                set plugNumber [lindex [split $repere ","] 0]
            
                if {[array names ::plug -exact "$plugNumber,value"] != ""} {
                
                    # On ajoute le numéro de port à la liste des abonnés
                    lappend ::plug(subscription,$plugNumber) $serverForResponse
                
                } else {
                    ::piLog::log [clock milliseconds] "error" "$plugNumber,value doesnot exists in ::plug"
                }
            } else {
                ::piLog::log [clock milliseconds] "error" "Couldnot rekognize Asked subscriptionEvenement $variable - parametre $repere"
            }
        }
        "updateSubscriptionEvenement" {
            ::piLog::log [clock milliseconds] "info" "Asked update subscriptionEvenement"
            
            # On met à jour la liste qui indique quelles sont les prises mise à jour
            set plugNumber 1
            while {1} {
                if {[array names ::plug -exact "$plugNumber,value"] != ""} {
                    lappend ::plug(updated)  $plugNumber
                } else {
                    break;
                }
                incr plugNumber
            }
            
        }
        "_getPort" {
            set ::port([::piTools::lindexRobust $message 3]) [::piTools::lindexRobust $message 4]
            ::piLog::log [clock milliseconds] "debug" "getPort response : module [::piTools::lindexRobust $message 3] port [::piTools::lindexRobust $message 4]"
        }
        "_getRepere" {
            # On parse le retour de la commande
            set indexCapteur  [::piTools::lindexRobust $message 3]
            set valeurCapteur [::piTools::lindexRobust $message 4]
            
            # On sauvegarde la valeur du capteur
            set ::sensor(${indexCapteur}) $valeurCapteur
            
            ::piLog::log [clock milliseconds] "debug" "getRepere response : capteur $indexCapteur valeur -$valeurCapteur-"
        }
        "_subscription" -
        "_subscriptionEvenement" {
            # On parse le retour de la commande
            set variable  [::piTools::lindexRobust $message 3]
            set valeur [::piTools::lindexRobust $message 4]
            
            # On enregistre le retour de l'abonnement
            set ::${variable} $valeur
            
            ::piLog::log [clock milliseconds] "debug" "subscription response : variable $variable valeur -$valeur-"
            
            set splitted [split ${variable} "(,)"]
            set variableName [lindex $splitted 0]
            set sensorIndex [lindex $splitted 1]
            set variableType [lindex $splitted 2]
            if {$variableName == "::sensor" && $variableType == "value"} {
                updateSensorVal $sensorIndex
            } elseif {$variableType != "value"} {
                ::piLog::log [clock milliseconds] "debug" "_subscription response : this not a value : $variableType - msg : $message"
            } else {
                ::piLog::log [clock milliseconds] "error" "_subscription response : not recognize type $variableName  - msg : $message"
            }
        }
        default {
            # Si on reçoit le retour d'une commande, le nom du serveur est le notre
            if {$serverForResponse == $::piServer::portNumber(${::moduleLocalName})} {
            
                if {[array names ::TrameSended -exact $indexForResponse] != ""} {
                    
                    switch [lindex $::TrameSended($indexForResponse) 0] {
                        "update_plug_value" {
                            set plugumber [lindex $::TrameSended($indexForResponse) 1]
                        
                            set ::plug($plugumber,updateStatus) $commande
                            set ::plug($plugumber,updateStatusComment) ${message}
                        
                            ::piLog::log [clock milliseconds] "info" "I2C Update plug $plugumber updateStatus : -$commande- updateStatusComment : -${message}-"
                        
                            # On supprime cette donnée de la mémoire
                            unset ::TrameSended($indexForResponse)
                        }
                        default {
                            ::piLog::log [clock milliseconds] "error" "Not recognize keyword response -${message}-"
                        }                    
                    }
                    
                } else {
                    ::piLog::log [clock milliseconds] "error" "Not requested response -${message}-"
                }
            
                
            } else {
                ::piLog::log [clock milliseconds] "error" "Received -${message}- but not interpreted"
            }
        }
    }
}