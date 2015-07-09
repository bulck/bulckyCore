
proc initRegulationVariable {} {
    for {set i 0} {$i < $::configXML(nbPlateforme)} {incr i} {

        set name $::configXML(plateforme,${i},name)
        
        # Ces variables permettent de savoir combien de temps d'irrigation ont été réalisé
        set ::tempsIrrigation($i)           0
        
        # Les temps de starter réalisés
        set ::tempsIrrigationStarter($i,Matin)   0
        set ::tempsIrrigationStarter($i,Apres)   0
        set ::tempsIrrigationStarter($i,Nuit)    0
        
        set ::regulationActivePlateforme($i)    "false"

    }
}

set ::AfterAutoRemplissage ""
set ::autoRemplissagePlateformeIndex 0
proc autoRemplissage {} {
    set ::AfterAutoRemplissage ""
    
    set plateformeNom     $::configXML(plateforme,$::autoRemplissagePlateformeIndex,name)
    set plateformeActive  $::configXML(plateforme,$::autoRemplissagePlateformeIndex,active)
    set plateformeNbZone  $::configXML(plateforme,$::autoRemplissagePlateformeIndex,nbZone)

    if {[array names ::configXML -exact "plateforme,$::autoRemplissagePlateformeIndex,activeAutoRemplissage"] != ""} {
        set remplissageAuto   $::configXML(plateforme,$::autoRemplissagePlateformeIndex,activeAutoRemplissage) 
    } else {
        set remplissageAuto "false"
    }
    set nbPlateforme      $::configXML(nbPlateforme)

    # Si on est entre 6h et 22h -> utilisation des temps de jour
    set hour [string trimleft [clock format [clock seconds] -format %H] "0"]
    if {$hour == ""} {set hour 0}

    if {$hour >= 6 && $hour < 14} {
        set JourOuNuit Matin
        set tempsMaxRemplissage $::configXML(plateforme,$::autoRemplissagePlateformeIndex,tempsMaxRemp)
    } elseif {$hour >= 14 && $hour <= 22} {
        set JourOuNuit Apres
        set tempsMaxRemplissage $::configXML(plateforme,$::autoRemplissagePlateformeIndex,tempsMaxRempApresMidi)
        
    } else {
        set JourOuNuit Nuit
        set tempsMaxRemplissage $::configXML(plateforme,$::autoRemplissagePlateformeIndex,tempsMaxRempNuit)
    }

    set IPplateforme      $::configXML(plateforme,$::autoRemplissagePlateformeIndex,ip)
    set IPlocalTechnique  $::configXML(localtechnique,ip)
    if {[array names ::configXML -exact "plateforme,$::autoRemplissagePlateformeIndex,priseEau"] != ""} {
        set EVRemplissage   $::configXML(plateforme,$::autoRemplissagePlateformeIndex,priseEau) 
    } else {
        set EVRemplissage "0"
    }
    set Surpresseur       $::configXML(localtechnique,pompePrise)
    
    # Si la plateforme est désactivée, on passe à la suivante
    if {$plateformeActive == 0 || $plateformeActive == "false"} {
        ::piLog::log [clock milliseconds] "debug" "Rempli Cuve : plateforme $plateformeNom : désactivée"
        incr ::autoRemplissagePlateformeIndex
        if {$::autoRemplissagePlateformeIndex >= $nbPlateforme} {
            set ::autoRemplissagePlateformeIndex 0
        }
        set ::idAfterRegul [after 1000 [list after idle autoRemplissage]]
        return
    }
    
    # Si le remplissage auto est désactivé, on passe à la plateforme suivante
    if {$remplissageAuto == 0 || $remplissageAuto == "false"} {
        ::piLog::log [clock milliseconds] "debug" "Rempli Cuve : plateforme $plateformeNom : auto remplissage désactivé"
        incr ::autoRemplissagePlateformeIndex
        if {$::autoRemplissagePlateformeIndex >= $nbPlateforme} {
            set ::autoRemplissagePlateformeIndex 0
        }
        set ::idAfterRegul [after 1000 [list after idle autoRemplissage]]
        return
    }
    
    # Si la prise utilisée pour piloter l'électrovanne n'est pas définit on passe à la plateforme suivante
    if {$EVRemplissage == 0} {
        ::piLog::log [clock milliseconds] "debug" "Rempli Cuve : plateforme $plateformeNom : pas de prise pour le remplissage"
        incr ::autoRemplissagePlateformeIndex
        if {$::autoRemplissagePlateformeIndex >= $nbPlateforme} {
            set ::autoRemplissagePlateformeIndex 0
        }
        set ::idAfterRegul [after 1000 [list after idle autoRemplissage]]
        return
    }

    # Si on a pas d'information sur la hauteur
    if {$::cuve($::autoRemplissagePlateformeIndex) == "NA" || 
        $::cuve($::autoRemplissagePlateformeIndex) == "" || 
        $::cuve($::autoRemplissagePlateformeIndex) == "DEFCOM" || 
        $::cuve($::autoRemplissagePlateformeIndex) == "TIMEOUT" ||
        [string is double $::cuve($::autoRemplissagePlateformeIndex)] != 1} {
        ::piLog::log [clock milliseconds] "info" "Rempli Cuve : plateforme $plateformeNom : Pas d'information sur la hauteur de cuve ( $::cuve($::autoRemplissagePlateformeIndex) ) , on passe à la suivante";update
        incr ::autoRemplissagePlateformeIndex
        if {$::autoRemplissagePlateformeIndex >= $nbPlateforme} {
            set ::autoRemplissagePlateformeIndex 0
        }
        set ::idAfterRegul [after 1000 [list after idle autoRemplissage]]
        return
    }

    # Si l'arrosage a été réalisé plus 10 minute durant l'heure, on passe à la suivante
    if {$::tempsIrrigation($::autoRemplissagePlateformeIndex) >= $tempsMaxRemplissage} {
        set oldTmpsIrrig $::tempsIrrigation($::autoRemplissagePlateformeIndex)
        incr ::autoRemplissagePlateformeIndex
        if {$::autoRemplissagePlateformeIndex >= $nbPlateforme} {
            set ::autoRemplissagePlateformeIndex 0
        }
        ::piLog::log [clock milliseconds] "info" "Rempli Cuve : plateforme $plateformeNom : Cuve trop remplie pour cette heure (actuel : $oldTmpsIrrig - max : $tempsMaxRemplissage ), on passe à la suivante ( $::autoRemplissagePlateformeIndex ) dans 27s";update

        set ::idAfterRegul [after 1000  [list after idle autoRemplissage]]

        return
    }

    # La cuve est dessous du niveau minimum, on ouvre la vanne jusqu'à ce que le capteur cuve basse soit actif ou que le temps de remplissage soit dépassé
    if {$::cuve($::autoRemplissagePlateformeIndex) == 0} {
    
        # On ouvre l'EV 
        ::piLog::log [clock milliseconds] "info" "Rempli Cuve : plateforme $plateformeNom : ON EV remplissage"; update
        ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverIrrigation) 0 setRepere $EVRemplissage on 999" $IPplateforme
    
        # on attend que le niveau soit remonté
        while {$::cuve($::autoRemplissagePlateformeIndex) == 0 && $::tempsIrrigation($::autoRemplissagePlateformeIndex) < $tempsMaxRemplissage} {
        
            set ::tempsIrrigation($::autoRemplissagePlateformeIndex) [expr $::tempsIrrigation($::autoRemplissagePlateformeIndex) + 1]
        
            after 950
            update
        }
        
        # On éteint l'électrovanne 
        ::piLog::log [clock milliseconds] "info" "Rempli Cuve : plateforme $plateformeNom : OFF EV remplissage"; update
        ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverIrrigation) 0 setRepere $EVRemplissage off 999" $IPplateforme
    }

    # On passe à la zone suivante
    set ::idAfterRegul [after 1000  [list after idle autoRemplissage]]
    return
}

set ::tempsIrrigation(actualHour)  [clock format [clock seconds] -format "%H"]
set ::regulCuvePlateformeIndex 0
set ::regulCuveZoneIndex 0

proc regulCuve {} {

    set ::idAfterRegul ""
    
    set plateformeNom     $::configXML(plateforme,$::regulCuvePlateformeIndex,name)
    set plateformeActive  $::configXML(plateforme,$::regulCuvePlateformeIndex,active)
    set plateformeNbZone  $::configXML(plateforme,$::regulCuvePlateformeIndex,nbZone)
    
    set nbPlateforme      $::configXML(nbPlateforme)

    set zoneNom          $::configXML(plateforme,$::regulCuvePlateformeIndex,zone,$::regulCuveZoneIndex,name)
    set zoneActive       $::configXML(plateforme,$::regulCuvePlateformeIndex,zone,$::regulCuveZoneIndex,active)

    set IPplateforme      $::configXML(plateforme,$::regulCuvePlateformeIndex,ip)
    set IPlocalTechnique  $::configXML(localtechnique,ip)
    set EVZone            $::configXML(plateforme,$::regulCuvePlateformeIndex,zone,$::regulCuveZoneIndex,prise)
    set EVPFLT            $::configXML(plateforme,$::regulCuvePlateformeIndex,priseDansLT)
    set Surpresseur       $::configXML(localtechnique,pompePrise)
    
    # Si on est entre 6h et 22h -> utilisation des temps de jour
    set hour [string trimleft [clock format [clock seconds] -format %H] "0"]
    if {$hour == ""} {set hour 0}

    if {$hour >= 6 && $hour < 14} {
        set JourOuNuit Matin
        set tempsMaxRemplissage $::configXML(plateforme,$::regulCuvePlateformeIndex,tempsMaxRemp)
        
        # On vide les deux autres buffers
        set ::tempsIrrigationStarter($::regulCuvePlateformeIndex,Apres) 0
        set ::tempsIrrigationStarter($::regulCuvePlateformeIndex,Nuit) 0
        
    } elseif {$hour >= 14 && $hour <= 22} {
        set JourOuNuit Apres
        set tempsMaxRemplissage $::configXML(plateforme,$::regulCuvePlateformeIndex,tempsMaxRempApresMidi)
        
        # On vide les deux autres buffers
        set ::tempsIrrigationStarter($::regulCuvePlateformeIndex,Matin) 0
        set ::tempsIrrigationStarter($::regulCuvePlateformeIndex,Nuit) 0
        
    } else {
        set JourOuNuit Nuit
        set tempsMaxRemplissage $::configXML(plateforme,$::regulCuvePlateformeIndex,tempsMaxRempNuit)
        
        # On vide les deux autres buffers
        set ::tempsIrrigationStarter($::regulCuvePlateformeIndex,Matin) 0
        set ::tempsIrrigationStarter($::regulCuvePlateformeIndex,Apres) 0
    }

    # Si la plateforme est désactivée, on passe à la suivante
    if {$plateformeActive == 0 || $plateformeActive == "false"} {
        ::piLog::log [clock milliseconds] "debug" "Regul Cuve : plateforme $plateformeNom : désactivée, on passe à la suivante"
        incr ::regulCuvePlateformeIndex
        set ::regulCuveZoneIndex 0
        if {$::regulCuvePlateformeIndex >= $nbPlateforme} {
            set ::regulCuvePlateformeIndex 0
        }
        set ::idAfterRegul [after 1000 [list after idle regulCuve]]
        return
    }
    
    # Si on a pas d'information sur la hauteur
    if {$::cuve($::regulCuvePlateformeIndex) == "NA" || 
        $::cuve($::regulCuvePlateformeIndex) == "" || 
        $::cuve($::regulCuvePlateformeIndex) == "DEFCOM" || 
        $::cuve($::regulCuvePlateformeIndex) == "TIMEOUT" ||
        [string is double $::cuve($::regulCuvePlateformeIndex)] != 1} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : Pas d'information sur la hauteur de cuve ( $::cuve($::regulCuvePlateformeIndex) ) , on passe à la suivante";update
        incr ::regulCuvePlateformeIndex
        set ::regulCuveZoneIndex 0
        if {$::regulCuvePlateformeIndex >= $nbPlateforme} {
            set ::regulCuvePlateformeIndex 0
        }
        set ::idAfterRegul [after 1000 [list after idle regulCuve]]
        return
    }
    
    # Si on a pas d'info sur la date du dernier plein
    if {$::cuve($::regulCuvePlateformeIndex,heureDernierPlein) == "NA" || 
        $::cuve($::regulCuvePlateformeIndex,heureDernierPlein) == "" || 
        $::cuve($::regulCuvePlateformeIndex,heureDernierPlein) == "DEFCOM" || 
        $::cuve($::regulCuvePlateformeIndex,heureDernierPlein) == "TIMEOUT" ||
        [string is double $::cuve($::regulCuvePlateformeIndex,heureDernierPlein)] != 1} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : Pas d'information sur le dernier remplissage, on passe à la suivante";update
        incr ::regulCuvePlateformeIndex
        set ::regulCuveZoneIndex 0
        if {$::regulCuvePlateformeIndex >= $nbPlateforme} {
            set ::regulCuvePlateformeIndex 0
        }
        set ::idAfterRegul [after 1000  [list after idle regulCuve]]
        return
    }
    
    # Si la plate-forme est pleine, on passe à la suivante
    # Si la cuve de la plateforme a été pleine lors des 3 dernières minutes, on passe à la suivante
    set TimeBeforeLastPlein   [expr [clock seconds] - $::cuve($::regulCuvePlateformeIndex,heureDernierPlein)]
    if {$TimeBeforeLastPlein <  [expr  3 * 60]} {
        incr ::regulCuvePlateformeIndex
        set ::regulCuveZoneIndex 0
        if {$::regulCuvePlateformeIndex >= $nbPlateforme} {
            set ::regulCuvePlateformeIndex 0
        }
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : Cuve pleine depuis moins de trois minutes (${TimeBeforeLastPlein}s Vs 180s), on passe à la suivante ( $::regulCuvePlateformeIndex ) dans 27s";update
        set ::idAfterRegul [after 27000 [list after idle regulCuve]]
        return
    }
    
    # Si l'heure change, on efface le compteur de temps
    if {$::tempsIrrigation(actualHour) != [clock format [clock seconds] -format "%H"]} {
        set ::tempsIrrigation(actualHour)  [clock format [clock seconds] -format "%H"]
        
        for {set i 0} {$i < $::configXML(nbPlateforme)} {incr i} {
            # On réinitialise le temps du compteur
            set ::tempsIrrigation($i)           0
        }
    }
    
    # Si l'arrosage a été réalisé plus 10 minute durant l'heure, on passe à la suivante
    if {$::tempsIrrigation($::regulCuvePlateformeIndex) >= $tempsMaxRemplissage} {
        set oldTmpsIrrig $::tempsIrrigation($::regulCuvePlateformeIndex)
        incr ::regulCuvePlateformeIndex
        set ::regulCuveZoneIndex 0
        if {$::regulCuvePlateformeIndex >= $nbPlateforme} {
            set ::regulCuvePlateformeIndex 0
        }
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : Cuve trop remplie pour cette heure (actuel : $oldTmpsIrrig - max : $tempsMaxRemplissage ), on passe à la suivante ( $::regulCuvePlateformeIndex ) dans 27s";update

        set ::idAfterRegul [after 27000  [list after idle regulCuve]]

        return
    }
    

    # Si la zone est en régulation, on passe à la suivante
    if {$::irrigationActive($::regulCuvePlateformeIndex) == "true"} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : La plateforme est en irrigation, on attend 15 secondes et on retente";update
        set ::idAfterRegul [after 15000 [list after idle regulCuve]]
        return
    }
    
    # Si la zone est désactivée, on passe à la suivante
    if {$zoneActive == 0 || $zoneActive == "false"} {
        ::piLog::log [clock milliseconds] "debug" "Regul Cuve : plateforme $plateformeNom : zone $zoneNom : La zone est désactivée, on passe à la suivante";update
        incr ::regulCuveZoneIndex
        if {$::regulCuveZoneIndex >= $plateformeNbZone} {
            set ::regulCuveZoneIndex 0
            incr ::regulCuvePlateformeIndex
            if {$::regulCuvePlateformeIndex >= $nbPlateforme} {
                set ::regulCuvePlateformeIndex 0
            }
        }
        set ::idAfterRegul [after 100 [list after idle regulCuve]]
        return 
    }

    # On regarde si on est en starter ou non
    # Si le temps réalisé est inférieur au temps starter, on est en starter
    set starter "Normal"
    if {$::tempsIrrigationStarter($::regulCuvePlateformeIndex,$JourOuNuit) < $::configXML(localtechnique,time${JourOuNuit}Starter)} {
        set starter "Starter"
    }
    ::piLog::log [clock milliseconds] "debug" "Regul Cuve : plateforme $plateformeNom : on est en $starter car $::tempsIrrigationStarter($::regulCuvePlateformeIndex,$JourOuNuit) < $::configXML(localtechnique,time${JourOuNuit}Starter)";update

    
    # On sauvegarde le nom de la plateforme en régulation
    set ::regulationActivePlateforme($::regulCuvePlateformeIndex) "true"
    
    # Le principe est le suivant : 30s de remplissage par zone
    # On met en route l'irrigation avec de l'eau fraiche
    # ON de l'EV de la plateforme set prise(localtechnique,ev,engrais1)
    ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : zone $zoneNom : ON EV $::regulCuveZoneIndex pendant 30 s"; update
    ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverIrrigation) 0 setRepere $EVZone on 30" $IPplateforme


    # On met en route l'électrovanne du LT associée à la zone
    # ON de l'EV de la plateforme set prise(localtechnique,ev,engrais1)
    ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : zone $zoneNom : ON localtechnique EV ${plateformeNom} pendant 30 s" ;update
    ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverIrrigation) 0 setRepere $EVPFLT on 30" $IPlocalTechnique

    after 10
    
    # On ouvre toutes les électrovannes des engrais associés
    for {set i 0} {$i < $::configXML(nbEngrais)} {incr i} {
        if {$::configXML(engrais,${i},use${JourOuNuit}${starter}) == "true"} {

            set name $::configXML(engrais,${i},name)
            set priseEVEngrais $::configXML(engrais,${i},prise)

            ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : zone $zoneNom : ON localtechnique EV $name pendant 30 s";update
            ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverIrrigation) 0 setRepere $priseEVEngrais on 30" $IPlocalTechnique
        }
    }

    after 10

    # On met en route la pompe
    ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : zone $zoneNom : ON localtechnique surpresseur pendant 29 s";update
    ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverIrrigation) 0 setRepere $Surpresseur on 29" $IPlocalTechnique

    # On sauvegarde le temps d'irrigation pour vérifier qu'on ne remplie pas trop
    set ::tempsIrrigation($::regulCuvePlateformeIndex)                    [expr $::tempsIrrigation($::regulCuvePlateformeIndex) + 30]
    set ::tempsIrrigationStarter($::regulCuvePlateformeIndex,$JourOuNuit) [expr $::tempsIrrigationStarter($::regulCuvePlateformeIndex,$JourOuNuit) + 30]

    # Dans 30 secondes on indique que la régulation est terminée
    after 30000 [list set ::regulationActivePlateforme($::regulCuvePlateformeIndex) false]
    after 30000 [list ::piLog::log [expr [clock milliseconds] + 30000] "info" "Regul Cuve : plateforme $plateformeNom : zone $zoneNom : Fin Regul Cuve"]

    # On incrémente le numéro de la zone à irriguer
    incr ::regulCuveZoneIndex
    if {$::regulCuveZoneIndex >= $plateformeNbZone} {
        set ::regulCuveZoneIndex 0
        incr ::regulCuvePlateformeIndex
        if {$::regulCuvePlateformeIndex >= $nbPlateforme} {
            set ::regulCuvePlateformeIndex 0
        }
    }
    
    ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : zone $zoneNom : Attente 60 secondes avant plateforme $::regulCuvePlateformeIndex zone $::regulCuveZoneIndex";update
    set ::idAfterRegul [after 60000 [list after idle regulCuve]]
    
}

