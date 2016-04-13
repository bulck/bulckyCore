set ::EMETEUR_NB_PLUG_MAX 16
set ::EMETEUR_OFF_VALUE 0
set ::EMETEUR_ON_VALUE 999

proc emeteur_init {} {

    set ::emeteur_actualDay ""
    set ::c8_emeteurPlugFileName "plugv"
    set ::nextTimeToChange 0
    set ::uc8_regulationIsDone 0
    set ::uc8_alarm 0
    set ::actualProgramm ""

}

proc formatSeconds {seconds} {
    return [clock format [expr $seconds - 3600] -format %H:%M:%S]
}

proc load_plugXX {{plugVFileName ""}} {

    # On efface l'ancien vecteur s'il existe
    if {[array exists ::programm]} {
        array unset ::programm
    }

    # Si aucun nom de fichier à charger n'est donné, on récupère le fichier du jour
    if {$plugVFileName == ""} {
        set plugVFileName "plugv"
        ::piLog::log [clock milliseconds] "info" "plugv index : -[::piTime::readMonth][::piTime::readDay]-"
        set fid [open [file join $::confPath prg plgidx] r]
        while {[eof $fid] != 1 } {
            gets $fid UneLigne
            if {[string range $UneLigne 0 3] == "[::piTime::readMonth][::piTime::readDay]"} {
                set plugVFileName "plu[string range $UneLigne 4 5]"
                break
            }
        }
        close $fid
    }

    ::piLog::log [clock milliseconds] "info" "plugv filename : $plugVFileName"

    set fid [open [file join $::confPath prg $plugVFileName] r]
    
    # On ne mit pas la première ligne qui ne sert à rien
    gets $fid UneLigne
    
    while {[eof $fid] != 1 } {
        gets $fid UneLigne
        if {$UneLigne != ""} {
            # On calcul l'heure
            set formattedHour [string trimleft [string range $UneLigne 0 4] "0"]
            if {$formattedHour == ""} {set formattedHour 0}
        
            set time [expr $formattedHour * 1]

            set list ""
            for {set i 5} {$i < [string length $UneLigne]} {incr i 3} {
                set programmeCourt [string range $UneLigne [expr $i] [expr $i + 2]]
                switch $programmeCourt {
                    "000" {
                        lappend list "off"
                    }
                    "999" {
                        lappend list "on"
                    }
                    default {
                        set withoutZero [string trimleft $programmeCourt 0]
                        if {$withoutZero == ""} {
                            set withoutZero 0
                        }
                        lappend list [expr $withoutZero / 10.0]
                    }
                }
            }
            
            set ::programm($time) $list
        } else {
            break
        }
    }
    close $fid
    
    ::piLog::log [clock milliseconds] "debug" "end of reading : $plugVFileName"
}

proc getsProgramm {rtc_readSecondsOfTheDay {updateNextTimeToChange 0}} {
    set prg ""
    set lastProgramm ""

    foreach timeS [lsort -integer [array names ::programm]] {
    
        # On cherche l'élément le dernier élément inférieur à rtc_readSecondsOfTheDay
        if {$timeS > $rtc_readSecondsOfTheDay} {
            
            set prg $lastProgramm

            # Si besoin, on sauvegarde le prochain élément à envoyer
            if {$updateNextTimeToChange != 0} {
                set ::nextTimeToChange $timeS
            }
            
            break

        }
        
        set lastProgramm $::programm($timeS)
        
    }
    
    # Si le programme est vide c'est qu'on a pas trouvé de commande dnas le programme avec un temps > au temps actuel 
    # Le cas classique, je cherche un programme > 86399
    if {$prg == ""} {
        ::piLog::log [clock milliseconds] "error" "getsProgramm : Programm for hour -${rtc_readSecondsOfTheDay}- not found"
        if {${rtc_readSecondsOfTheDay} >= 86399} {
            ::piLog::log [clock milliseconds] "info" "getsProgramm : Hour is too big, we use last programm valid"
            set prg $lastProgramm
        } else {
            ::piLog::log [clock milliseconds] "info" "getsProgramm :load by default plugv"
            load_plugXX "plugv"
            set ::nextTimeToChange 0
            set prg $::programm($nextTimeToChange)
        }
    }
    
    return $prg
}

proc emeteur_update_loop {} {

        
    # Read actual hour
    set uc24_seconds [::piTime::readSecondsOfTheDay]
               
    # If system is in alarm state
    if {$::uc8_alarm == 1}  {
        for {set i 0} {$i < $::EMETEUR_NB_PLUG_MAX} {incr i} {
            # Save value
            set emeteur_regulation_value($i) $::EMETEUR_OFF_VALUE
            # update plug value
            emeteur_update_plug_value $i $::EMETEUR_OFF_VALUE
        }

        # Save it on log.txt
        ::piLog::log [clock milliseconds] "info" "IN ALARME"

        set ::uc8_alarm 2
      
        after 1000 emeteur_update_loop
      
        return 0
    }

    # If first evaluation of values {plug adress are send and plug value not send} are not done
    if {[::piTime::readDay] != $::emeteur_actualDay } {

        # Load plugV
        load_plugXX
        
        # Relaod hour (cf bug 1189)
        set uc24_seconds [::piTime::readSecondsOfTheDay]
    
        set programmeToSend [getsProgramm $uc24_seconds "updatenextTimeToChange"]
        set ::actualProgramm $programmeToSend

        for {set i 1} {$i <= $::EMETEUR_NB_PLUG_MAX} {incr i} {
            ::piLog::log [clock milliseconds] "info" "Programm of $i is [lindex $programmeToSend [expr $i - 1]]"
            updatePlug $i
        }

        ::piLog::log [clock milliseconds] "info" "init emetor next change $::nextTimeToChange - [formatSeconds $::nextTimeToChange]"
        
        # register day
        set ::emeteur_actualDay [::piTime::readDay]

    } elseif {$uc24_seconds >= $::nextTimeToChange && $uc24_seconds != 86399} {

        set programmeToSend [getsProgramm $uc24_seconds "updatenextTimeToChange"]
        set ::actualProgramm $programmeToSend

        for {set i 1} {$i <= $::EMETEUR_NB_PLUG_MAX} {incr i} {
            ::piLog::log [clock milliseconds] "info" "Programm of $i is [lindex $programmeToSend [expr $i - 1]]"
            updatePlug $i
        }
        
        ::piLog::log [clock milliseconds] "info" "next change $::nextTimeToChange - [formatSeconds $::nextTimeToChange]"
        
    } elseif {[expr $uc24_seconds % 5] == 0} { 
    

        # La régulation doit être faite
        if {$::uc8_regulationIsDone == 0} \
        {

            # update plug
            for {set i 1} {$i <= $::EMETEUR_NB_PLUG_MAX} {incr i} \
            {
            
                if {[array get ::plug "$i,module"] == ""} {
                    set ::plug($i,module) "NA"
                }
                set module $::plug($i,module)
            
                set plgPrgm [lindex $::actualProgramm [expr $i - 1]]
                # On ne met à jour que les plugs qui font de régulation
                if {$plgPrgm != "on" && 
                    $plgPrgm != "off" && 
                    $module != "XMAX" && 
                    $module != "PCA9685"} {
                    updatePlug $i
                }
            }
            set ::uc8_regulationIsDone 1
        }

    } else {
        set ::uc8_regulationIsDone 0
    }

    after 500 emeteur_update_loop
    
    return 0
    
}


proc updatePlug {plugNumber} {

    # retourne l'ensemble du programme pour toutes les prises
    set programmeToSend $::actualProgramm
    
    # On cherche le programme de la prise (attention les prises démarre à 1 !)
    set plgPrgm [lindex $programmeToSend [expr $plugNumber - 1]]
    
    if {[array get ::plug "$plugNumber,module"] == ""} {
        set ::plug($plugNumber,module) "NA"
    }
    set module $::plug($plugNumber,module)

    # On vérifie que le module utilisé pour le pilotage existe
    if {$::plug($plugNumber,module) == "NA"} {
        ::piLog::log [clock milliseconds] "error" "Plug $plugNumber module $module is not defined"
        set statusError 1
    } elseif {$::plug($plugNumber,source) == "force"} {
        # On regarde si la prise est forcée dans un état par l'utilisateur
    
        # On envoi la commande au module
        set statusError [::${module}::setValue $plugNumber $::plug($plugNumber,force,value) $::plug($plugNumber,adress)]
        
        # On sauvegarde le fait qu'on n'est plus en régulation
        set ::plug($plugNumber,inRegulation) "NONE"
        
    } elseif {$plgPrgm == ""} {
    
        ::piLog::log [clock milliseconds] "error" "Plug $plugNumber programme is empty, on passe la prise a 0"
        
        # On envoi la commande au module
        set statusError [::${module}::setValue $plugNumber "off" $::plug($plugNumber,adress)]
        
        # On sauvegarde le fait qu'on n'est plus en régulation
        set ::plug($plugNumber,inRegulation) "NONE"

    } elseif {$plgPrgm != "off" && 
              $plgPrgm != "on" && 
              ${module} != "XMAX" && 
              ${module} != "PCA9685"} {
        # Si c'est de la régulation
        set statusError [emeteur_regulation $plugNumber $plgPrgm]
        
    } else {
        ::piLog::log [clock milliseconds] "info" "update plug $plugNumber with programm $plgPrgm - module : -${module}-"
        
        # On envoi la commande au module
        set statusError [::${module}::setValue $plugNumber $plgPrgm $::plug($plugNumber,adress)]
        
        # On sauvegarde le fait qu'on n'est plus en régulation
        set ::plug($plugNumber,inRegulation) "NONE"
    }
    
    return $statusError
}

proc savePlugSendValue {plug value} {

    # On ne doit mettre à jour les abonnement que si l'état de la prise à changé
    if {$::plug($plug,value) != $value} {
        
        # On enregistre l'état de la prise
        set ::plug($plug,value)  $value
        
        # On ajoute à la liste des valeurs mise à jour
        # Si seulement il n'y a pas déjà une valeur
        if {[lsearch $::plug(updated) $plug] == -1} {
            lappend ::plug(updated)  $plug
        }
    }
    
}

set ::SubscriptionUpdateHour [clock seconds]
proc emeteur_subscriptionEvenement {} {

    set ThereAreSomeClient 0
    
    # S'il c'est passé 19 minutes sans logs, on renvoit l'état des prises
    if {[expr [clock seconds] - $::SubscriptionUpdateHour] > [expr 60 * 19]} {
        foreach plugP [array names ::plug "subscription*"] {
            set plg [lindex [split $plugP ","] 1]
            lappend ::plug(updated) $plg
        }
    }

    if {$::plug(updated) != ""} {
    
        # Pour chaque prise mise à jour
        foreach plugNb $::plug(updated) {
        
            if {[array names ::plug -exact subscription,$plugNb] == ""} {
                set ::plug(subscription,$plugNb) ""
            }
        
            # On envoi à tous les client qui on un abonnement événementiel
            foreach client $::plug(subscription,$plugNb) {

                if {$::plug($plugNb,value) == "NA" || $::plug($plugNb,value) == ""} {
                    ::piLog::log [clock milliseconds] "warning" "emeteur_subscriptionEvenement Asked $plugNb value but value is - $::plug($plugNb,value) -"
                } else {
                    ::piServer::sendToServer $client "$client [incr ::TrameIndex] _subscriptionEvenement ::plug($plugNb,value) $::plug($plugNb,value) [clock milliseconds]"
                }
                
                set ThereAreSomeClient 1
                
                # On enregistre l'heure à laquelle on a mis à jour l'état des prises
                set ::SubscriptionUpdateHour [clock seconds]
            }
        
        }
    
        # On efface la liste si on a envoyé quelque chose
        if {$ThereAreSomeClient != 0} {
            set ::plug(updated) ""
        }
    }
    
    after 200 emeteur_subscriptionEvenement

}
