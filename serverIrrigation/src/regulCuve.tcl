
proc initRegulationVariable {} {
    for {set i 0} {$i < $::configXML(nbPlateforme)} {incr i} {

        set name $::configXML(plateforme,${i},name)
        
        # Ces variables permettent de savoir combien de temps d'irrigation ont �t� r�alis�
        set ::tempsIrrigation($i)           0
        
        # Les temps de starter r�alis�s
        set ::tempsIrrigationStarter($i,Matin)   0
        set ::tempsIrrigationStarter($i,Apres)   0
        set ::tempsIrrigationStarter($i,Nuit)    0
        
        set ::regulationActivePlateforme($i)    "false"
        set ::autoRemplissageActivePlateforme($i)    "false"

    }
}

proc remplissageCuve {indexPtf} {

    if {$indexPtf == ""} {
        ::piLog::log [clock milliseconds] "error" "Fill Cuve :index plateforme is not defined"; update
        return
    }

    set plateformeNom           $::configXML(plateforme,$indexPtf,name)
    set Surpresseur             $::configXML(localtechnique,pompePrise)
    set autoRemplissageDirect   [::piTools::readArrayElem [array get ::configXML] "plateforme,$indexPtf,autoRemplissageDirect" "true"]
    set EVRemplissage           [::piTools::readArrayElem [array get ::configXML] "plateforme,$indexPtf,priseEau" "0"]
    set priseRemplissage        [::piTools::readArrayElem [array get ::configXML] "plateforme,$indexPtf,priseRemplissage" "0"]
    set evLTeau                 [::piTools::readArrayElem [array get ::configXML] "engrais,3,prise" "0"]
    set EVPFLT                  $::configXML(plateforme,$indexPtf,priseDansLT)
    set IPplateforme            $::configXML(plateforme,$::autoRemplissagePlateformeIndex,ip)
    set IPlocalTechnique        $::configXML(localtechnique,ip)
    
    ::piLog::log [clock milliseconds] "info" "Fill Cuve : plateforme $plateformeNom : Asked to fill"; update
    
    while {$::cuve($indexPtf) != 15} {
    
        if {$autoRemplissageDirect == "true"} {
        
            # On ouvre l'EV pendant 30 secondes
            ::piLog::log [clock milliseconds] "info" "Fill Cuve : plateforme $plateformeNom : ON EV remplissage 30 s"; update
            ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverIrrigation) 0 setRepere $EVRemplissage on 30" $IPplateforme
        
        } else {
            
            # On ouvre l'EV de l'eau
            ::piLog::log [clock milliseconds] "info" "Fill Cuve : plateforme $plateformeNom  : ON localtechnique EV eau pendant 32 s";update
            ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverIrrigation) 0 setRepere $evLTeau on 32" $IPlocalTechnique
            
            # On ouvre l'EV de la platfeorme 
            ::piLog::log [clock milliseconds] "info" "Fill Cuve : plateforme $plateformeNom  : ON localtechnique EV ${plateformeNom} pendant 32 s" ;update
            ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverIrrigation) 0 setRepere $EVPFLT on 32" $IPlocalTechnique
            
            # On ouvre l'EV de remplissage
            ::piLog::log [clock milliseconds] "info" "Fill Cuve : plateforme $plateformeNom : ON EV remplissage 32 s"; update
            ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverIrrigation) 0 setRepere $priseRemplissage on 32" $IPplateforme
            
            # On allume le surpresseur 
            ::piLog::log [clock milliseconds] "info" "Fill Cuve : plateforme $plateformeNom : ON localtechnique surpresseur pendant 30 s";update
            ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverIrrigation) 0 setRepere $Surpresseur on 30" $IPlocalTechnique
        
        }
    
        after 10000
    }

    ::piLog::log [clock milliseconds] "info" "Fill Cuve : plateforme $plateformeNom : End fill"; update
}

set ::AfterAutoRemplissage ""
set ::autoRemplissagePlateformeIndex 0
proc autoRemplissage {} {
    set ::AfterAutoRemplissage ""
    
    set plateformeNom     $::configXML(plateforme,$::autoRemplissagePlateformeIndex,name)
    set plateformeActive  $::configXML(plateforme,$::autoRemplissagePlateformeIndex,active)
    set plateformeNbZone  $::configXML(plateforme,$::autoRemplissagePlateformeIndex,nbZone)
    set Surpresseur       $::configXML(localtechnique,pompePrise)
    set EVPFLT            $::configXML(plateforme,$::autoRemplissagePlateformeIndex,priseDansLT)
    
    set activeAutoRemplissage [::piTools::readArrayElem [array get ::configXML] "plateforme,$::autoRemplissagePlateformeIndex,activeAutoRemplissage" "false"]
    set autoRemplissageDirect [::piTools::readArrayElem [array get ::configXML] "plateforme,$::autoRemplissagePlateformeIndex,autoRemplissageDirect" "true"]
    set priseRegulation       [::piTools::readArrayElem [array get ::configXML] "plateforme,$::autoRemplissagePlateformeIndex,priseRegulation" "0"]
    set priseRemplissage      [::piTools::readArrayElem [array get ::configXML] "plateforme,$::autoRemplissagePlateformeIndex,priseRemplissage" "0"]
    
    set evLTeau      [::piTools::readArrayElem [array get ::configXML] "engrais,3,prise" "0"]

    set nbPlateforme      $::configXML(nbPlateforme)


    set IPplateforme      $::configXML(plateforme,$::autoRemplissagePlateformeIndex,ip)
    set IPlocalTechnique  $::configXML(localtechnique,ip)
    set EVRemplissage      [::piTools::readArrayElem [array get ::configXML] "plateforme,$::autoRemplissagePlateformeIndex,priseEau" "0"]

    set TempsAutoRemplissage [::piTools::readArrayElem [array get ::configXML] "plateforme,$::autoRemplissagePlateformeIndex,TempsAutoRemplissage" 30]
    
    # Si la plateforme est d�sactiv�e, on passe � la suivante
    if {$plateformeActive == 0 || $plateformeActive == "false"} {
        ::piLog::log [clock milliseconds] "debug" "Rempli Cuve : plateforme $plateformeNom : d�sactiv�e"
        incr ::autoRemplissagePlateformeIndex
        if {$::autoRemplissagePlateformeIndex >= $nbPlateforme} {
            set ::autoRemplissagePlateformeIndex 0
        }
        set ::idAfterRegul [after 1000 [list after idle autoRemplissage]]
        return
    }
    
    # Si le remplissage auto est d�sactiv�, on passe � la plateforme suivante
    if {$activeAutoRemplissage == 0 || $activeAutoRemplissage == "false"} {
        ::piLog::log [clock milliseconds] "debug" "Rempli Cuve : plateforme $plateformeNom : auto remplissage d�sactiv�"
        incr ::autoRemplissagePlateformeIndex
        if {$::autoRemplissagePlateformeIndex >= $nbPlateforme} {
            set ::autoRemplissagePlateformeIndex 0
        }
        set ::idAfterRegul [after 1000 [list after idle autoRemplissage]]
        return
    }
    
    # Si la prise utilis�e pour piloter l'�lectrovanne n'est pas d�finit on passe � la plateforme suivante
    if {$EVRemplissage == 0} {
        ::piLog::log [clock milliseconds] "info" "Rempli Cuve : plateforme $plateformeNom : pas de prise pour le remplissage"
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
        ::piLog::log [clock milliseconds] "info" "Rempli Cuve : plateforme $plateformeNom : Pas d'information sur la hauteur de cuve ( $::cuve($::autoRemplissagePlateformeIndex) ) , on passe � la suivante";update
        incr ::autoRemplissagePlateformeIndex
        if {$::autoRemplissagePlateformeIndex >= $nbPlateforme} {
            set ::autoRemplissagePlateformeIndex 0
        }
        set ::idAfterRegul [after 1000 [list after idle autoRemplissage]]
        return
    }

    # La cuve est dessous du niveau minimum, on ouvre la vanne jusqu'� ce que le capteur cuve basse soit actif ou que le temps de remplissage soit d�pass�
    if {$::cuve($::autoRemplissagePlateformeIndex) == 0} {
    
        # Deux cas :
        #  - Soit on ouvre juste l'EV qui rempli 
        #  - Soit on ouvre l'EV de remplissage + l'EV de la zone dans le local technique + le surpresseur
        if {$autoRemplissageDirect == "true"} {
        
            # On sauvegarde le nom de la plateforme en r�gulation
            # Pas besoin de le sauvegarder car �a ne permet qu d'�viter les conflits d'utilisation des tuyeau
            # set ::autoRemplissageActivePlateforme($::autoRemplissagePlateformeIndex) "true"
        
            # On ouvre l'EV pendant 30 secondes
            ::piLog::log [clock milliseconds] "info" "Rempli Cuve : plateforme $plateformeNom : ON EV remplissage $TempsAutoRemplissage s"; update
            ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverIrrigation) 0 setRepere $EVRemplissage on $TempsAutoRemplissage" $IPplateforme
            
            # Dans 30 secondes on indique que la r�gulation est termin�e
            # after [expr 1000 * $TempsAutoRemplissage] [list set ::autoRemplissageActivePlateforme($::autoRemplissagePlateformeIndex) false]
            after [expr 1000 * $TempsAutoRemplissage] [list ::piLog::log [expr [clock milliseconds] + 1000 * $TempsAutoRemplissage] "info" "Rempli Cuve : plateforme $plateformeNom : Fin Rempli Cuve"]
            
        }  else {
            # On v�rifie qu'on est pas en remplissage de cuve 
            if {$::regulationActivePlateforme($::autoRemplissagePlateformeIndex) == "false"} {
                
                # On sauvegarde le nom de la plateforme en r�gulation
                set ::autoRemplissageActivePlateforme($::autoRemplissagePlateformeIndex) "true"
                
                set TempsEV [ expr $TempsAutoRemplissage + 2]
                
                # On ouvre l'EV de l'eau
                ::piLog::log [clock milliseconds] "info" "Rempli Cuve : plateforme $plateformeNom  : ON localtechnique EV eau pendant $TempsEV s";update
                ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverIrrigation) 0 setRepere $evLTeau on $TempsEV" $IPlocalTechnique
                
                # On ouvre l'EV de la platfeorme 
                ::piLog::log [clock milliseconds] "info" "Rempli Cuve : plateforme $plateformeNom  : ON localtechnique EV ${plateformeNom} pendant $TempsEV s" ;update
                ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverIrrigation) 0 setRepere $EVPFLT on $TempsEV" $IPlocalTechnique
                
                # On ouvre l'EV de remplissage
                ::piLog::log [clock milliseconds] "info" "Rempli Cuve : plateforme $plateformeNom : ON EV remplissage $TempsEV s"; update
                ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverIrrigation) 0 setRepere $priseRemplissage on $TempsEV" $IPplateforme
                
                # On allume le surpresseur 
                ::piLog::log [clock milliseconds] "info" "Rempli Cuve : plateforme $plateformeNom : ON localtechnique surpresseur pendant $TempsAutoRemplissage s";update
                ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverIrrigation) 0 setRepere $Surpresseur on $TempsAutoRemplissage" $IPlocalTechnique
                
                # Dans 30 secondes on indique que la r�gulation est termin�e
                after [expr 1000 * $TempsEV] [list set ::autoRemplissageActivePlateforme($::autoRemplissagePlateformeIndex) false]
                after [expr 1000 * $TempsEV] [list ::piLog::log [expr [clock milliseconds] + 1000 * $TempsEV] "info" "Rempli Cuve : plateforme $plateformeNom : Fin Rempli Cuve"]
                
            } else {
                ::piLog::log [clock milliseconds] "info" "Rempli Cuve : plateforme $plateformeNom : En r�gulation, on attend"; update
            }
        }
    } else {
        ::piLog::log [clock milliseconds] "debug" "Rempli Cuve : plateforme $plateformeNom : la cuve est OK : $::cuve($::autoRemplissagePlateformeIndex) "; update
    }


    # On passe � la zone suivante
    incr ::autoRemplissagePlateformeIndex
    if {$::autoRemplissagePlateformeIndex >= $nbPlateforme} {
        set ::autoRemplissagePlateformeIndex 0
    }
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
    
    set autoRemplissageDirect [::piTools::readArrayElem [array get ::configXML] "plateforme,$::regulCuvePlateformeIndex,autoRemplissageDirect" "true"]
    set priseRegulation       [::piTools::readArrayElem [array get ::configXML] "plateforme,$::regulCuvePlateformeIndex,priseRegulation" "0"]
    
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

    # Si la plateforme est d�sactiv�e, on passe � la suivante
    if {$plateformeActive == 0 || $plateformeActive == "false"} {
        ::piLog::log [clock milliseconds] "debug" "Regul Cuve : plateforme $plateformeNom : d�sactiv�e, on passe � la suivante"
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
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : Pas d'information sur la hauteur de cuve ( $::cuve($::regulCuvePlateformeIndex) ) , on passe � la suivante";update
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
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : Pas d'information sur le dernier remplissage, on passe � la suivante";update
        incr ::regulCuvePlateformeIndex
        set ::regulCuveZoneIndex 0
        if {$::regulCuvePlateformeIndex >= $nbPlateforme} {
            set ::regulCuvePlateformeIndex 0
        }
        set ::idAfterRegul [after 1000  [list after idle regulCuve]]
        return
    }
    
    # Si la plate-forme est pleine, on passe � la suivante
    # Si la cuve de la plateforme a �t� pleine lors des 3 derni�res minutes, on passe � la suivante
    set TimeBeforeLastPlein   [expr [clock seconds] - $::cuve($::regulCuvePlateformeIndex,heureDernierPlein)]
    if {$TimeBeforeLastPlein <  [expr  3 * 60]} {
        incr ::regulCuvePlateformeIndex
        set ::regulCuveZoneIndex 0
        if {$::regulCuvePlateformeIndex >= $nbPlateforme} {
            set ::regulCuvePlateformeIndex 0
        }
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : Cuve pleine depuis moins de trois minutes (${TimeBeforeLastPlein}s Vs 180s), on passe � la suivante ( $::regulCuvePlateformeIndex ) dans 27s";update
        set ::idAfterRegul [after 27000 [list after idle regulCuve]]
        return
    }
    
    # Si l'heure change, on efface le compteur de temps
    if {$::tempsIrrigation(actualHour) != [clock format [clock seconds] -format "%H"]} {
        set ::tempsIrrigation(actualHour)  [clock format [clock seconds] -format "%H"]
        
        for {set i 0} {$i < $::configXML(nbPlateforme)} {incr i} {
            # On r�initialise le temps du compteur
            set ::tempsIrrigation($i)           0
        }
    }
    
    # Si l'arrosage a �t� r�alis� plus 10 minute durant l'heure, on passe � la suivante
    if {$::tempsIrrigation($::regulCuvePlateformeIndex) >= $tempsMaxRemplissage} {
        set oldTmpsIrrig $::tempsIrrigation($::regulCuvePlateformeIndex)
        incr ::regulCuvePlateformeIndex
        set ::regulCuveZoneIndex 0
        if {$::regulCuvePlateformeIndex >= $nbPlateforme} {
            set ::regulCuvePlateformeIndex 0
        }
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : Cuve trop remplie pour cette heure (actuel : $oldTmpsIrrig - max : $tempsMaxRemplissage ), on passe � la suivante ( $::regulCuvePlateformeIndex ) dans 27s";update

        set ::idAfterRegul [after 27000  [list after idle regulCuve]]

        return
    }
    

    # Si la zone est en r�gulation, on passe � la suivante
    if {$::irrigationActive($::regulCuvePlateformeIndex) == "true"} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : La plateforme est en irrigation, on attend 15 secondes et on retente";update
        set ::idAfterRegul [after 15000 [list after idle regulCuve]]
        return
    }
    
    # Si la zone est d�sactiv�e, on passe � la suivante
    if {$zoneActive == 0 || $zoneActive == "false"} {
        ::piLog::log [clock milliseconds] "debug" "Regul Cuve : plateforme $plateformeNom : zone $zoneNom : La zone est d�sactiv�e, on passe � la suivante";update
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
    # Si le temps r�alis� est inf�rieur au temps starter, on est en starter
    set starter "Normal"
    if {$::tempsIrrigationStarter($::regulCuvePlateformeIndex,$JourOuNuit) < $::configXML(localtechnique,time${JourOuNuit}Starter)} {
        set starter "Starter"
    }
    ::piLog::log [clock milliseconds] "debug" "Regul Cuve : plateforme $plateformeNom : on est en $starter car $::tempsIrrigationStarter($::regulCuvePlateformeIndex,$JourOuNuit) < $::configXML(localtechnique,time${JourOuNuit}Starter)";update

    
    # On sauvegarde le nom de la plateforme en r�gulation
    set ::regulationActivePlateforme($::regulCuvePlateformeIndex) "true"
    
    # Le principe est le suivant : 30s de remplissage par zone
    # On met en route l'irrigation avec de l'eau fraiche
    # ON de l'EV de la plateforme set prise(localtechnique,ev,engrais1)
    ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : zone $zoneNom : ON EV $::regulCuveZoneIndex pendant 30 s"; update
    ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverIrrigation) 0 setRepere $EVZone on 30" $IPplateforme

    # On met en route l'�lectrovanne du LT associ�e � la zone
    # ON de l'EV de la plateforme set prise(localtechnique,ev,engrais1)
    ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : zone $zoneNom : ON localtechnique EV ${plateformeNom} pendant 30 s" ;update
    ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverIrrigation) 0 setRepere $EVPFLT on 30" $IPlocalTechnique

    # Si il y a une �lectrovanne pour la r�gulation 
    if {$autoRemplissageDirect == "false"} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : zone $zoneNom : ON EV $::priseRegulation pendant 30 s"; update
        ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverIrrigation) 0 setRepere $priseRegulation on 30" $IPplateforme
    }
    
    after 10
    
    # On ouvre toutes les �lectrovannes des engrais associ�s
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

    # On sauvegarde le temps d'irrigation pour v�rifier qu'on ne remplie pas trop
    set ::tempsIrrigation($::regulCuvePlateformeIndex)                    [expr $::tempsIrrigation($::regulCuvePlateformeIndex) + 30]
    set ::tempsIrrigationStarter($::regulCuvePlateformeIndex,$JourOuNuit) [expr $::tempsIrrigationStarter($::regulCuvePlateformeIndex,$JourOuNuit) + 30]

    # Dans 30 secondes on indique que la r�gulation est termin�e
    after 30000 [list set ::regulationActivePlateforme($::regulCuvePlateformeIndex) false]
    after 30000 [list ::piLog::log [expr [clock milliseconds] + 30000] "info" "Regul Cuve : plateforme $plateformeNom : zone $zoneNom : Fin Regul Cuve"]

    # On incr�mente le num�ro de la zone � irriguer
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

