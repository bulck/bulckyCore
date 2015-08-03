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
        $processID,valueSeuil    "25" \
        $processID,timeSeuilInS  "120" \
        $processID,alertIf       "up" \
        $processID,startAlertInS 0 \
        $processID,messageSend   0 \
    ]
    
    for {set i 0} {$i < [llength $arrayIn]} {incr i 2} {
        set XMLprocess($processID,[lindex $arrayIn $i]) [lindex $arrayIn [expr $i + 1]]
    }
    
    # On affiche les �l�ments du process 
    foreach elemName [array names XMLprocess -glob "$processID,*"] {
        ::piLog::log [clock milliseconds] "info" "checkSensor::start $elemName : $XMLprocess($elemName)"
    }

    # On prend un abonnement sur la donn�e � monitorer
    set ::sensor($XMLprocess($processID,sensor),value,$XMLprocess($processID,sensorOutput)) ""
    checkSensor::takeAbonnement $XMLprocess($processID,sensor) $XMLprocess($processID,sensorOutput)

    # On d�marre la boucle de v�rification
    set XMLprocess($processID,IDAfter) [after 1000 [list ::checkSensor::check $processID]]

    incr processID
}

proc checkSensor::takeAbonnement {sensor output} {
    set retErr [::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(serverSupervision) [incr ::TrameIndex] subscription ${sensor},value,${output} 2000"]

    if {$retErr != 0} {
        ::piLog::log [clock milliseconds] "warning" "::checkSensor::start : subscription is not done"
        after 1500 "checkSensor::takeAbonnement $sensor $output"
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

# Cette proc�dure v�rifie que le capteur ne d�passe pas le seuil
proc checkSensor::check {processID} {
    variable XMLprocess
   
    set sensorValue $::sensor($XMLprocess($processID,sensor),value,$XMLprocess($processID,sensorOutput))
   
    if {$sensorValue == "" || $sensorValue == "NULL" || $sensorValue == "DEFCOM" || $sensorValue == "NA" } {
        ::piLog::log [clock milliseconds] "warning" "::checkSensor::check : No value for sensor ::sensor($XMLprocess($processID,sensor),value,$XMLprocess($processID,sensorOutput))"
        
        set XMLprocess($processID,IDAfter) [after 1000 [list ::checkSensor::check $processID]]
        
        return 
    }
   
    # On v�rifie si la valeur est sup�rieur ou pas au seuil 
    # Deux cas : on a choisit d'envoyer une alerte si la valeur est sup�rieure
    if {$XMLprocess($processID,alertIf) == "up"} {
    
        if {$sensorValue > $XMLprocess($processID,valueSeuil)} {
            # La valeur du capteur est sup�rieur au seuil d�finit
            if {$XMLprocess($processID,startAlertInS) == 0} {
                # On enregistre l'heure de d�part du d�passement de seuil
                set XMLprocess($processID,startAlertInS) [clock seconds]
            }
            
            # Si la valeur est sup�rieur au seuil depuis trop longtemps, envoyer un message � l'utilisateur
            set nbSecAlert [expr [clock seconds] - $XMLprocess($processID,startAlertInS)]
            if {$nbSecAlert >= $XMLprocess($processID,timeSeuilInS)} {
                # Si on a pas envoy� d�j� un message 
                if {$XMLprocess($processID,messageSend) == 0} {
                    # Si on a pas envoy� d�j� un message 
                    ::piLog::log [clock milliseconds] "info" "checkSensor::check sensor value is too high, send mail (sensor : $XMLprocess($processID,sensor),value,$XMLprocess($processID,sensorOutput) , value $sensorValue , time $nbSecAlert)"
                    
                    # On envoi une alerte
                    ::checkSensor::sendAlert $processID
                    
                    # On sauvegarde l'envoi du message
                    set XMLprocess($processID,messageSend) 1 
                }
            }
            
        } else {
            # La valeur du capteur est inf�rieure au seuil 
            set XMLprocess($processID,startAlertInS) 0
            
            # Si un message d'alerte a �t� envoy� , renvoyer un message pour dire que tout va bien
            if {$XMLprocess($processID,messageSend) == 1} {
            
                ::piLog::log [clock milliseconds] "info" "checkSensor::check back to normal"

                ::checkSensor::sendRetToNormal $processID

                set XMLprocess($processID,messageSend) 0
            }
            
        }
    
    } else {
        # Si on a choisit d'envoyer une alerte si la valeur est inf�rieure
        
        if {$sensorValue < $XMLprocess($processID,valueSeuil)} {
            # La valeur du capteur est inf�rieure au seuil d�finit
            if {$XMLprocess($processID,startAlertInS) == 0} {
                # On enregistre l'heure de d�part du d�passement de seuil
                set XMLprocess($processID,startAlertInS) [clock seconds]
            }
            
            # Si la valeur est inf�rieure au seuil depuis trop longtemps, envoyer un message � l'utilisateur
            set nbSecAlert [expr [clock seconds] - $XMLprocess($processID,startAlertInS)]
            if {$nbSecAlert >= $XMLprocess($processID,timeSeuilInS)} {
                # Si on a pas envoy� d�j� un message 
                if {$XMLprocess($processID,messageSend) == 0} {
                    # Si on a pas envoy� d�j� un message 
                    # On envoi une alerte
                    ::checkSensor::sendAlert $processID
                    
                    # On sauvegarde l'envoi du message
                    set XMLprocess($processID,messageSend) 1 
                }
            }
        } else {
            # La valeur du capteur est sup�rieure au seuil 
            set XMLprocess($processID,startAlertInS) 0
            
            # Si un message d'alerte a �t� envoy� , renvoyer un message pour dire que tout va bien
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

    # On calcul les donn�es a mettre dans le mail 
    set nbSecAlert [expr [clock seconds] - $XMLprocess($processID,startAlertInS)]
    set seuil $XMLprocess($processID,valueSeuil)
    set capteur $XMLprocess($processID,sensor)
    if {$XMLprocess($processID,alertIf) == "up"} {
        set sens "sup�rieure"
    } else {
        set sens "inf�rieure"
    }

    set title {[Cultibox : Alerte]}
    
    set message "Alerte g�n�r�e le [clock format [clock seconds] -format "%Y/%m/%d %H:%M:%S"] : "
    
    set message "${message}\\nLa valeur du capteur $capteur est $sens au seuil de $seuil depuis $nbSecAlert secondes."
    
    set message "${message}\\nVous recevrez un nouvel eMail lorsque tout sera rentr� dans l'ordre"
    
    set message "${message}\\nMessage envoy� automatiquement par ma Cultibox"
    
    # On envoi le message
    ::piServer::sendToServer $::piServer::portNumber(serverMail) "$::piServer::portNumber(serverSupervision) [incr ::TrameIndex] sendMail $XMLprocess($processID,eMail) \"${title}\" \"${message}\""
}

proc checkSensor::sendRetToNormal {processID} {

    # On calcul les donn�es a mettre dans le mail 
    set seuil $XMLprocess($processID,valueSeuil)
    set capteur $XMLprocess($processID,sensor)
    if {$XMLprocess($processID,alertIf) == "up"} {
        set sens "inf�rieure"
    } else {
        set sens "sup�rieure"
    }

    set title {[Cultibox : Alerte]}
    
    set message "Retour � la normal g�n�r� le [clock format [clock seconds] -format "%Y/%m/%d %H:%M:%S"] : "
    
    set message "${message}\\nLa valeur du capteur $capteur est redevenue $sens au seuil de $seuil."

    set message "${message}\\nMessage envoy� automatiquement par ma Cultibox"
    
    # On envoi le message
    ::piServer::sendToServer $::piServer::portNumber(serverMail) "$::piServer::portNumber(serverSupervision) [incr ::TrameIndex] sendMail $XMLprocess($processID,eMail) \"${title}\" \"${message}\""
}
