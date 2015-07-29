
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
                
                ::piLog::log [clock milliseconds] "info" "Asked getRepere $variable by $networkhost"
                
                if {[info exists ::$variable] == 1} {
                
                    eval set returnValue $$variable
                    
                    # Condition particuliere : pour les regroupement de variable, on met DEFCOM si null
                    if {$variable == "::sensor(1,value)" || $variable == "::sensor(2,value)"  || $variable == "::sensor(3,value)"  || $variable == "::sensor(4,value)"  || $variable == "::sensor(5,value)"  || $variable == "::sensor(6,value)" } {
                        if {$returnValue == ""} {
                            set returnValue "DEFCOM"
                        }
                    }
                    
                    lappend returnList $returnValue
                } else {
                    ::piLog::log [clock milliseconds] "error" "Asked variable $variable by $networkhost - variable doesnot exists"
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
        "subscription" {
            # Le repère est l'index des capteurs
            set repere [::piTools::lindexRobust $message 3]
            set frequency [::piTools::lindexRobust $message 4]
            if {$frequency == 0} {set frequency 1000}
            set BandeMorteAcquisition [::piTools::lindexRobust $message 5]
            if {$BandeMorteAcquisition == ""} {set BandeMorteAcquisition 0}
            
            ::piLog::log [clock milliseconds] "info" "Subscription of $repere by $serverForResponse frequency $frequency ms"

            set ::subscriptionVariable($::SubscriptionIndex) ""
            
            # On cré la proc associée
            proc subscription${::SubscriptionIndex} {repere frequency SubscriptionIndex serverForResponse BandeMorteAcquisition networkhost} {
                set reponse $::sensor($repere)
                if {$reponse == ""} {
                    set reponse "DEFCOM"
                }
                
                set time [clock milliseconds]
                if {[array name ::sensor -exact $repere,time] != ""} {
                    set time    $::sensor($repere,time)
                }
            
                # On envoi la nouvelle valeur uniquement si la valeur a changée
                if {$::subscriptionVariable($SubscriptionIndex) != $reponse} {
                
                    # Dans le cas d'un double, on vérifie la bande morte
                    if {[string is double $reponse] == 1} {
                        # Réponse doit être > à l'ancienne valeur + BMA ou < à l'ancienne valeur - BMA
                        set oldValue $::subscriptionVariable($SubscriptionIndex)
                        if {[string is double $oldValue] != 1} {
                            set oldValue -100
                        }
                        if {$reponse > [expr $oldValue + $BandeMorteAcquisition] || $reponse < [expr $oldValue - $BandeMorteAcquisition]} {
                            ::piServer::sendToServer $serverForResponse "$serverForResponse [incr ::TrameIndex] _subscription ::sensor($repere) $reponse $time" $networkhost
                            set ::subscriptionVariable($SubscriptionIndex) $reponse
                        } else {
                            ::piLog::log [clock milliseconds] "debug" "Doesnot send ::sensor($repere) besause it's between BMA $reponse sup [expr $oldValue + $BandeMorteAcquisition] OR $reponse inf [expr $oldValue - $BandeMorteAcquisition]"
                        }
                        
                    } else {
                        ::piServer::sendToServer $serverForResponse "$serverForResponse [incr ::TrameIndex] _subscription ::sensor($repere) $reponse $time" $networkhost
                        set ::subscriptionVariable($SubscriptionIndex) $reponse
                        ::piLog::log [clock milliseconds] "debug" "Response is not a double _subscription ::sensor($repere) reponse : $reponse"
                    }
                } else {
                    #::piLog::log [clock milliseconds] "debug" "Doesnot resend ::sensor($repere) besause it's same value -$reponse-"
                }
                
                after $frequency "subscription${SubscriptionIndex} $repere $frequency $SubscriptionIndex $serverForResponse $BandeMorteAcquisition $networkhost"
            }
            
            # on la lance
            subscription${::SubscriptionIndex} $repere $frequency $::SubscriptionIndex $serverForResponse $BandeMorteAcquisition $networkhost
            
            incr ::SubscriptionIndex
        }
        "_subscription" -
        "_subscriptionEvenement" {
            # On parse le retour de la commande
            set variable    [::piTools::lindexRobust $message 3]
            set valeur      [::piTools::lindexRobust $message 4]
            set time        [::piTools::lindexRobust $message 5]
            
            # On enregistre le retour de l'abonnement
            set ${variable} $valeur

            # On traite immédiatement cette info
            set splitted [split ${variable} "(,)"]
            set variableName [lindex $splitted 0]
            set networkSensor [lindex $splitted 1]
            
            # On analyse pour savoir quelle capteur en local ça correspond
            set localSensor [::network_read::getSensor $networkhost $networkSensor]
            if {$localSensor == "NA"} {
                return
            }
            
            switch $variableName {
                "::sensor" {
                    switch [lindex $splitted 2] {
                        "type" {
                            # Si c'est le type de capteur
                            ::piLog::log [clock milliseconds] "debug" "_subscription response : save sensor type (local sensor $localSensor ): $message"
                            set ::sensor($localSensor,type) $valeur
                        }
                        "value" {
                            set valeur1      [::piTools::lindexRobust $message 4]
                            set valeur2      [::piTools::lindexRobust $message 5]
                            set time         [::piTools::lindexRobust $message 6]
                            # Si c'est la valeur
                            # ::piLog::log [clock milliseconds] "debug" "_subscription response : save sensor value : $message - [lindex $splitted 1] $valeur1 $valeur2 $time"
                            if {$valeur1 == "DEFCOM"} {
                                ::piLog::log [clock milliseconds] "warning" "_subscription response : save sensor value : DEFCOM so not saved - msg : $message"
                            } else {
                                set ::sensor($localSensor,value,1) $valeur1
                                set ::sensor($localSensor,value)   $valeur1
                                set ::sensor($localSensor,value,time) $time
                            }
                            
                        } 
                        default {
                            ::piLog::log [clock milliseconds] "error" "_subscription response : not rekognize type [lindex $splitted 2]  - msg : $message"
                        }
                    }
                }
                "::plug" {
                }
                default {
                    ::piLog::log [clock milliseconds] "error" "_subscription response : unknow variable name $variableName - msg : $message"
                }
            }

            # ::piLog::log [clock milliseconds] "debug" "subscription response : variable $variable valeur -$valeur-"
        }
        default {
            # Si on reçoit le retour d'une commande, le nom du serveur est le notre
            if {$serverForResponse == $::piServer::portNumber(${::moduleLocalName})} {
            
                if {[array names ::TrameSended -exact $indexForResponse] != ""} {
                    
                    switch [lindex $::TrameSended($indexForResponse) 0] {
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
