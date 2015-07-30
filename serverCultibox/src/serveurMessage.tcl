
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
            # Pour toutes les variables demand�es
            set indexVar 3
            set returnList ""
            while {[set variable [::piTools::lindexRobust $message $indexVar]] != ""} {
                # La variable est le nom de la variable � lire
                
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
            # Le num�ro de prise est indiqu� 
            set variable [::piTools::lindexRobust $message 3]
            set repere   [::piTools::lindexRobust $message 4]
            ::piLog::log [clock milliseconds] "info" "Asked subscriptionEvenement $variable - parametre $repere"
            
            # Les seuls abonnements autoris� sont plug(n,value)
            if {$variable == "plug"} {
                
                set plugNumber [lindex [split $repere ","] 0]
            
                if {[array names ::plug -exact "$plugNumber,value"] != ""} {
                
                    # On ajoute le num�ro de port � la liste des abonn�s
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
            
            # On met � jour la liste qui indique quelles sont les prises mise � jour
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
            set variable    [::piTools::lindexRobust $message 3]
            set valeur      [::piTools::lindexRobust $message 4]
            set time        [::piTools::lindexRobust $message 5]
            
            # On enregistre le retour de l'abonnement
            set ${variable} $valeur
            
            # On traite imm�diatement cette info
            set splitted [split ${variable} "(,)"]
            set variableName [lindex $splitted 0]
            switch $variableName {
                "::sensor" {
                    switch [lindex $splitted 2] {
                        "type" {
                            # Si c'est le type de capteur
                            ::piLog::log [clock milliseconds] "debug" "_subscription response : save sensor type : $message"
                            set ::sensor([lindex $splitted 1],type) $valeur
                        }
                        "value" {
                            set valeur1      [::piTools::lindexRobust $message 4]
                            set valeur2      [::piTools::lindexRobust $message 5]
                            set time         [::piTools::lindexRobust $message 6]
                            # Si c'est la valeur
                            if {$valeur1 == "DEFCOM"} {
                                ::piLog::log [clock milliseconds] "debug" "_subscription response : send value to cultibox : DEFCOM so not saved - msg : $message"
                            } else {
                                set ::sensor([lindex $splitted 1],value,1) $valeur1
                                set ::sensor([lindex $splitted 1],value,2) $valeur2
                                # Update sensor value in cultibox
                                updateSensorVal [lindex $splitted 1] $valeur1 $valeur2
                            }
                            
                        } 
                        default {
                            ::piLog::log [clock milliseconds] "error" "_subscription response : not recognize type [lindex $splitted 2]  - msg : $message"
                        }
                    }
                }
                "::plug" {
                    # Si c'est l'�tat d'une prise, on enregistre imm�diatement
                    ::piLog::log [clock milliseconds] "error" "_subscription response : save plug [lindex $splitted 1] $valeur time $time - msg : $message"
                }
                default {
                    ::piLog::log [clock milliseconds] "error" "_subscription response : unknow variable name $variableName - msg : $message"
                }
            }

            # ::piLog::log [clock milliseconds] "debug" "subscription response : variable $variable valeur -$valeur-"
        }
        default {
            # Si on re�oit le retour d'une commande, le nom du serveur est le notre
            if {$serverForResponse == $::piServer::portNumber(${::moduleLocalName})} {
            
                if {[array names ::TrameSended -exact $indexForResponse] != ""} {
                    
                    switch [lindex $::TrameSended($indexForResponse) 0] {
                        "update_plug_value" {
                            set plugumber [lindex $::TrameSended($indexForResponse) 1]
                        
                            set ::plug($plugumber,updateStatus) $commande
                            set ::plug($plugumber,updateStatusComment) ${message}
                        
                            ::piLog::log [clock milliseconds] "info" "I2C Update plug $plugumber updateStatus : -$commande- updateStatusComment : -${message}-"
                        
                            # On supprime cette donn�e de la m�moire
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