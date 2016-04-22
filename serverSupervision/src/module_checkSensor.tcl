namespace eval ::checkSensor {
    variable XMLprocess
    variable processID 0
    variable nbDayPerMonth [list 0 31 28 31 30 31 30 31 31 30 31 30 31]
}

proc checkSensor::start {arrayIn} {
    variable XMLprocess
    variable processID

    # Save params
    array set XMLprocess [list \
        $processID,IDAfter    0 \
        $processID,eMail     "NA" \
        $processID,sensor    "1" \
        $processID,sensorOutput  1 \
        $processID,sensorName  "NA" \
        $processID,valueSeuil    "25" \
        $processID,timeSeuilInS  "120" \
        $processID,alertIf       "up" \
        $processID,startAlertInS 0 \
        $processID,messageSend   0 \
    ]
    
    for {set i 0} {$i < [llength $arrayIn]} {incr i 2} {
        set XMLprocess($processID,[lindex $arrayIn $i]) [lindex $arrayIn [expr $i + 1]]
    }
    
    # On affiche les éléments du process 
    foreach elemName [array names XMLprocess -glob "$processID,*"] {
        ::piLog::log [clock milliseconds] "info" "checkSensor::start $elemName : $XMLprocess($elemName)"
    }

    # On prend un abonnement sur la donnée à monitorer
    set ::sensor($XMLprocess($processID,sensor),value) ""
    checkSensor::takeAbonnement $XMLprocess($processID,sensor)

    # On démarre la boucle de vérification
    set XMLprocess($processID,IDAfter) [after 1000 [list ::checkSensor::check $processID]]

    incr processID
}

proc checkSensor::takeAbonnement {sensor} {
    set retErr [::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(serverSupervision) [incr ::TrameIndex] subscription ${sensor},value 2000"]

    if {$retErr != 0} {
        ::piLog::log [clock milliseconds] "warning" "::checkSensor::start : subscription is not done"
        after 1500 "checkSensor::takeAbonnement $sensor"
    }

}

proc checkSensor::stop {} {
    variable XMLprocess
    variable processID
    
    for {set i 0} {$i < $processID} {incr i} {
        if  {$XMLprocess($i,IDAfter) != ""} {
            after cancel $XMLprocess($i,IDAfter)
        }
    }
}

# Cette procédure vérifie que le capteur ne dépasse pas le seuil
proc checkSensor::check {processID} {
    variable XMLprocess
   
    set sensorValue $::sensor($XMLprocess($processID,sensor),value)
    set noValue 0
   
    if {$sensorValue == "" || $sensorValue == "NULL" || $sensorValue == "DEFCOM" || $sensorValue == "NA" } {
        ::piLog::log [clock milliseconds] "warning" "::checkSensor::check : No value for sensor ::sensor($XMLprocess($processID,sensor),value) value : $sensorValue"
        
        set noValue 1
    }
   
    # On vérifie si la valeur est supérieur ou pas au seuil 
    # Deux cas : on a choisit d'envoyer une alerte si la valeur est supérieure
    if {$XMLprocess($processID,alertIf) == "up" && $noValue == 0} {
    
        if {$sensorValue > $XMLprocess($processID,valueSeuil)} {
            # La valeur du capteur est supérieur au seuil définit
            if {$XMLprocess($processID,startAlertInS) == 0} {
                # On enregistre l'heure de départ du dépassement de seuil
                set XMLprocess($processID,startAlertInS) [clock seconds]
            } else {
                ::piLog::log [clock milliseconds] "debug" "checkSensor::check start count alert"
            }
            
            # Si la valeur est supérieur au seuil depuis trop longtemps, envoyer un message à l'utilisateur
            set nbSecAlert [expr [clock seconds] - $XMLprocess($processID,startAlertInS)]
            if {$nbSecAlert >= $XMLprocess($processID,timeSeuilInS)} {
                # Si on a pas envoyé déjà un message 
                if {$XMLprocess($processID,messageSend) == 0} {
                    # Si on a pas envoyé déjà un message 
                    ::piLog::log [clock milliseconds] "info" "checkSensor::check sensor value is too high, send mail (sensor : $XMLprocess($processID,sensor),value , value $sensorValue , time $nbSecAlert)"
                    
                    # On envoi une alerte
                    ::checkSensor::sendAlert $processID
                    
                    # On sauvegarde l'envoi du message
                    set XMLprocess($processID,messageSend) 1 
                } else {
                    ::piLog::log [clock milliseconds] "debug" "checkSensor::check message already sended"
                }
            } else {
                ::piLog::log [clock milliseconds] "debug" "checkSensor::check alert in [expr $XMLprocess($processID,timeSeuilInS) - $nbSecAlert]"
            }
            
        } else {
            ::piLog::log [clock milliseconds] "info" "checkSensor::check value is normal"
        
            # La valeur du capteur est inférieure au seuil 
            set XMLprocess($processID,startAlertInS) 0
            
            # Si un message d'alerte a été envoyé , renvoyer un message pour dire que tout va bien
            if {$XMLprocess($processID,messageSend) == 1} {
            
                ::piLog::log [clock milliseconds] "info" "checkSensor::check back to normal"

                ::checkSensor::sendRetToNormal $processID

                set XMLprocess($processID,messageSend) 0
            }
            
        }
    
    } elseif {$XMLprocess($processID,alertIf) == "down" && $noValue == 0} {
        # Si on a choisit d'envoyer une alerte si la valeur est inférieure
        
        if {$sensorValue < $XMLprocess($processID,valueSeuil)} {
            # La valeur du capteur est inférieure au seuil définit
            if {$XMLprocess($processID,startAlertInS) == 0} {
                # On enregistre l'heure de départ du dépassement de seuil
                set XMLprocess($processID,startAlertInS) [clock seconds]
            } else {
                ::piLog::log [clock milliseconds] "debug" "checkSensor::check start count alert"
            }
            
            # Si la valeur est inférieure au seuil depuis trop longtemps, envoyer un message à l'utilisateur
            set nbSecAlert [expr [clock seconds] - $XMLprocess($processID,startAlertInS)]
            if {$nbSecAlert >= $XMLprocess($processID,timeSeuilInS)} {
                # Si on a pas envoyé déjà un message 
                if {$XMLprocess($processID,messageSend) == 0} {
                    # Si on a pas envoyé déjà un message 
                    # On envoi une alerte
                    ::checkSensor::sendAlert $processID
                    
                    # On sauvegarde l'envoi du message
                    set XMLprocess($processID,messageSend) 1 
                } else {
                    ::piLog::log [clock milliseconds] "debug" "checkSensor::check message already sended"
                }
                
            } else {
                ::piLog::log [clock milliseconds] "debug" "checkSensor::check alert in [expr $XMLprocess($processID,timeSeuilInS) - $nbSecAlert]"
            }
            
        } else {
            # La valeur du capteur est supérieure au seuil 
            set XMLprocess($processID,startAlertInS) 0
            
            # Si un message d'alerte a été envoyé , renvoyer un message pour dire que tout va bien
            if {$XMLprocess($processID,messageSend) == 1} {
                ::checkSensor::sendRetToNormal $processID

                set XMLprocess($processID,messageSend) 0
            }
        }
    } elseif {$XMLprocess($processID,alertIf) == "DEFCOM"} {
        # Si on a choisit d'envoyer une alerte si la valeur est en défaut de communication
        
        if {$noValue == 1} {
            # La valeur du capteur est en défaut de communication
            if {$XMLprocess($processID,startAlertInS) == 0} {
                # On enregistre l'heure de départ du dépassement de seuil
                set XMLprocess($processID,startAlertInS) [clock seconds]
            }
            
            # Si la valeur est en défaut de communication depuis trop longtemps, envoyer un message à l'utilisateur
            set nbSecAlert [expr [clock seconds] - $XMLprocess($processID,startAlertInS)]
            if {$nbSecAlert >= $XMLprocess($processID,timeSeuilInS)} {
                # Si on a pas envoyé déjà un message 
                if {$XMLprocess($processID,messageSend) == 0} {
                    # Si on a pas envoyé déjà un message 
                    # On envoi une alerte
                    ::checkSensor::sendAlert $processID
                    
                    # On sauvegarde l'envoi du message
                    set XMLprocess($processID,messageSend) 1 
                }
            }
        } else {
            # La valeur du capteur est redevenue normale
            set XMLprocess($processID,startAlertInS) 0
            
            # Si un message d'alerte a été envoyé , renvoyer un message pour dire que tout va bien
            if {$XMLprocess($processID,messageSend) == 1} {
                ::checkSensor::sendRetToNormal $processID

                set XMLprocess($processID,messageSend) 0
            }
        }
    }

    ::piLog::log [clock milliseconds] "debug" "checkSensor::check send new checkSensor in 5 secondes"

    set XMLprocess($processID,IDAfter) [after 5000 [list ::checkSensor::check $processID]]
}

proc checkSensor::sendAlert {processID} {
    variable XMLprocess

    # On calcul les données a mettre dans le mail 
    set nbSecAlert [expr [clock seconds] - $XMLprocess($processID,startAlertInS)]
    set seuil $XMLprocess($processID,valueSeuil)
    set capteur $XMLprocess($processID,sensor)
    
    set hostnameValue [exec hostname]
    set title "$hostnameValue : Alerte"
    
    # SI le nom du capteur est définit , on l'ajoute dans le message 
    set sensorName ""
    if {$XMLprocess($processID,sensorName) != ""} {
        set sensorName $XMLprocess($processID,sensorName)
    }

    if {$XMLprocess($processID,alertIf) == "up"} {
        set msgAlert "La valeur du capteur $capteur $sensorName est supérieure au seuil de $seuil depuis $nbSecAlert secondes."
    } elseif {$XMLprocess($processID,alertIf) == "down"} {
        set msgAlert "La valeur du capteur $capteur $sensorName est inférieure au seuil de $seuil depuis $nbSecAlert secondes."
    } else {
        set msgAlert "La valeur du capteur en défaut de communication depuis $nbSecAlert secondes."
    }
    
    set message "Alerte générée le [clock format [clock seconds] -format "%Y/%m/%d %H:%M:%S"] : "
    
    set message "${message}\\n${msgAlert}"
    
    set message "${message}\\nVous recevrez un nouvel eMail lorsque tout sera rentré dans l'ordre"
    
    set message "${message}\\nMessage envoyé automatiquement"
    
    # On envoi le message
    ::piServer::sendToServer $::piServer::portNumber(serverMail) "$::piServer::portNumber(serverSupervision) [incr ::TrameIndex] sendMail $XMLprocess($processID,eMail) \"${title}\" \"${message}\""
}

proc checkSensor::sendRetToNormal {processID} {
    variable XMLprocess

    # On calcul les données a mettre dans le mail 
    set seuil $XMLprocess($processID,valueSeuil)
    set capteur $XMLprocess($processID,sensor)

    set hostnameValue [exec hostname]
    set title "$hostnameValue : Alerte"
    
    # Si le nom du capteur est définit , on l'ajoute dans le message 
    set sensorName ""
    if {$XMLprocess($processID,sensorName) != ""} {
        set sensorName $XMLprocess($processID,sensorName)
    }
    
    set message "Retour à la normal généré le [clock format [clock seconds] -format "%Y/%m/%d %H:%M:%S"] : "
    
    set message "${message}\\nLa valeur du capteur $capteur $sensorName est redevenue normale."

    set message "${message}\\nMessage envoyé automatiquement"
    
    # On envoi le message
    ::piServer::sendToServer $::piServer::portNumber(serverMail) "$::piServer::portNumber(serverSupervision) [incr ::TrameIndex] sendMail $XMLprocess($processID,eMail) \"${title}\" \"${message}\""
}
