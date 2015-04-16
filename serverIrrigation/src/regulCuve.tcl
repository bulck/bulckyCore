
proc initRegulationVariable {} {
    for {set i 0} {$i < $::configXML(nbPlateforme)} {incr i} {

        set name $::configXML(plateforme,${i},name)
        
        # Ces variables permettent de savoir combien de temps d'irrigation ont été réalisé
        set ::tempsIrrigation($i)    0
        
        set ::regulationActivePlateforme($i)    "false"

    }
}


set ::tempsIrrigation(actualHour)  [clock format [clock seconds] -format "%H"]
set ::regulCuvePlateformeIndex 0
set ::regulCuveZoneIndex 0

proc regulCuve {} {

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

    # Si la plateforme est désactivée, on passe à la suivante
    if {$plateformeActive == 0 || $plateformeActive == "false"} {
        ::piLog::log [clock milliseconds] "debug" "Regul Cuve : plateforme $plateformeNom : désactivée, on passe à la suivante"
        incr ::regulCuvePlateformeIndex
        if {$::regulCuvePlateformeIndex >= $nbPlateforme} {
            set ::regulCuvePlateformeIndex 0
            set ::regulCuveZoneIndex 0
        }
        set ::idAfterRegul [after 1000 regulCuve]
        return
    }
    
    # Si la plateforme est désactivée, on passe à la suivante
    if {$::cuve($::regulCuvePlateformeIndex) == "NA" || 
        $::cuve($::regulCuvePlateformeIndex) == "" || 
        $::cuve($::regulCuvePlateformeIndex) == "DEFCOM" || 
        $::cuve($::regulCuvePlateformeIndex) == "TIMEOUT" ||
        [string is integer $::cuve($::regulCuvePlateformeIndex)] != 1} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : Pas d'information sur la hauteur de cuve, on passe à la suivante"
        incr ::regulCuvePlateformeIndex
        if {$::regulCuvePlateformeIndex >= $nbPlateforme} {
            set ::regulCuvePlateformeIndex 0
            set ::regulCuveZoneIndex 0
        }
        set ::idAfterRegul [after 1000 regulCuve]
        return
    }
    
    # Si on a pas d'info sur la date du dernier plein
    if {$::cuve($::regulCuvePlateformeIndex,heureDernierPlein) == "NA" || 
        $::cuve($::regulCuvePlateformeIndex,heureDernierPlein) == "" || 
        $::cuve($::regulCuvePlateformeIndex,heureDernierPlein) == "DEFCOM" || 
        $::cuve($::regulCuvePlateformeIndex,heureDernierPlein) == "TIMEOUT" ||
        [string is integer $::cuve($::regulCuvePlateformeIndex,heureDernierPlein)] != 1} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : Pas d'information sur le dernier remplissage, on passe à la suivante"
        incr ::regulCuvePlateformeIndex
        if {$::regulCuvePlateformeIndex >= $nbPlateforme} {
            set ::regulCuvePlateformeIndex 0
            set ::regulCuveZoneIndex 0
        }
        set ::idAfterRegul [after 1000 regulCuve]
        return
    }
    
    # Si la plate-forme est pleine, on passe à la suivante
    # Si la cuve de la plateforme a été pleine lors des 3 dernières minutes, on passe à la suivante
    set TimeBeforeLastPlein   [expr [clock seconds] - $::cuve($::regulCuvePlateformeIndex,heureDernierPlein)]
    if {$TimeBeforeLastPlein <  [expr  3 * 60]} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : Cuve pleine depuis moins de trois minutes (${TimeBeforeLastPlein}s Vs 180s), on passe à la suivante dans 27s"
        incr ::regulCuvePlateformeIndex
        if {$::regulCuvePlateformeIndex >= $nbPlateforme} {
            set ::regulCuvePlateformeIndex 0
            set ::regulCuveZoneIndex 0
        }
        set ::idAfterRegul [after 27000 regulCuve]
        return
    }
    
    # Si l'heure change, on réinitialise tous les compteurs
    if {$::tempsIrrigation(actualHour) != [clock format [clock seconds] -format "%H"]} {
        set ::tempsIrrigation(actualHour)  [clock format [clock seconds] -format "%H"]
        initRegulationVariable
    }
    
    # Si l'arrosage a été réalisé plus 10 minute durant l'heure, on passe à la suivante
    if {$::tempsIrrigation($::regulCuvePlateformeIndex) > $::configXML(plateforme,$::regulCuvePlateformeIndex,tempsMaxRemp)} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : Cuve trop remplie pour cette heure, on passe à la suivante dans 27s"
        incr ::regulCuvePlateformeIndex
        if {$::regulCuvePlateformeIndex >= $nbPlateforme} {
            set ::regulCuvePlateformeIndex 0
            set ::regulCuveZoneIndex 0
        }
        set ::idAfterRegul [after 27000 regulCuve]
        return
    }
    

    # Si la zone est en régulation, on passe à la suivante
    if {$::irrigationActive($::regulCuvePlateformeIndex) == "true"} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : La plateforme est en régulation, on attend 15 secondes et on retente"
        set ::idAfterRegul [after 15000 regulCuve]
        return
    }
    
    # Si la zone est désactivée, on passe à la suivante
    if {$zoneActive == 0 || $zoneActive == "false"} {
        ::piLog::log [clock milliseconds] "debug" "Regul Cuve : plateforme $plateformeNom : zone $zoneNom : La zone est désactivée, on passe à la suivante"
        incr ::regulCuveZoneIndex
        if {$::regulCuveZoneIndex >= $plateformeNbZone} {
            set ::regulCuveZoneIndex 0
            incr ::regulCuvePlateformeIndex
            if {$::regulCuvePlateformeIndex >= $nbPlateforme} {
                set ::regulCuvePlateformeIndex 0
            }
        }
        set ::idAfterRegul [after 100 regulCuve]
        return 
    }

    # On sauvegarde le nom de la plateforme en réégulation
    set ::regulationActivePlateforme($::regulCuvePlateformeIndex) "true"
    
    # Le principe est le suivant : 30s de remplissage par zone
    # On met en route l'irrigation avec de l'eau fraiche
    # Mise en route de l'EV de la plateforme set prise(localtechnique,ev,engrais1)
    ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : zone $zoneNom : Mise en route ev $::regulCuveZoneIndex pendant 30 s"; update
    ::piServer::sendToServer $::port(serverPlugUpdate) "$::port(serverIrrigation) 0 setRepere $EVZone on 30" $IPplateforme


    # On met en route l'électrovanne du LT associée à la zone
    # Mise en route de l'EV de la plateforme set prise(localtechnique,ev,engrais1)
    ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : zone $zoneNom : Mise en route localtechnique ev ${plateformeNom} pendant 30 s" ;update
    ::piServer::sendToServer $::port(serverPlugUpdate) "$::port(serverIrrigation) 0 setRepere $EVPFLT on 30" $IPlocalTechnique

    after 10
    
    # On ouvre toutes les électrovannes des engrais associés
    for {set i 0} {$i < $::configXML(nbEngrais)} {incr i} {
        if {$::configXML(engrais,${i},active) == "true"} {
        
            set name $::configXML(engrais,${i},name)
            set priseEVEngrais $::configXML(engrais,${i},prise)
        
            ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : zone $zoneNom : Mise en route localtechnique ev $name pendant 30 s";update
            ::piServer::sendToServer $::port(serverPlugUpdate) "$::port(serverIrrigation) 0 setRepere $priseEVEngrais on 30" $IPlocalTechnique
        }
    }

    after 10
    
    # On met en route le pompe
    ::piLog::log [clock milliseconds] "info" "Regul Cuve : plateforme $plateformeNom : zone $zoneNom : Mise en route localtechnique surpresseur pendant 29 s";update
    ::piServer::sendToServer $::port(serverPlugUpdate) "$::port(serverIrrigation) 0 setRepere $Surpresseur on 29" $IPlocalTechnique
    
    # On sauvegarde le temps d'irrigation pour vérifier qu'on ne remplie pas trop
    set ::tempsIrrigation($::regulCuvePlateformeIndex) [expr $::tempsIrrigation($::regulCuvePlateformeIndex) + 30]
    
    # DAns 30 secondes on indique que la régulation est terminée
    after 30000 "set ::regulationActivePlateforme($::regulCuvePlateformeIndex) false"
    
    # On incrémente le numéro de la zone à irriguer
    incr ::regulCuveZoneIndex
    if {$::regulCuveZoneIndex >= $plateformeNbZone} {
        set ::regulCuveZoneIndex 0
        incr ::regulCuvePlateformeIndex
        if {$::regulCuvePlateformeIndex >= $nbPlateforme} {
            set ::regulCuvePlateformeIndex 0
        }
    }
    
    
    set ::idAfterRegul [after 60000 regulCuve]
    
}

