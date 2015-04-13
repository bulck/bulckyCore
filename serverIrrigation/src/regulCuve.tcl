


proc initRegulationVariable {} {
    for {set i 0} {$i < $::configXML(nbPlateforme)} {incr i} {

        set name $::configXML(plateforme,${i},name)
        
        # Ces variables permettent de savoir combien de temps d'irrigation ont été réalisé
        set ::tempsIrrigation($name)    0

    }
}


set ::tempsIrrigation(actualHour)  [clock format [clock seconds] -format "%H"]

proc startRegulation {} {
    if {$::idAfterRegul == ""} {
        regulCuve
        
        set ::status(regulation) "En route"
    } 
}

proc stopRegulation {} {
    if {$::idAfterRegul == ""} {
    } else {
        set ::status(regulation) "En cours d arret"
    
        set ::stopNow 1
        after cancel $::idAfterRegul
        
        # On etteint toutes les électrovannes
        foreach elem $::listeEVOuverteRegulation {
            ::piLog::log [clock milliseconds] "info" "Regul Cuve : Demande arret : IP : [lindex $elem 1] - Prise [lindex $elem 0]" 
            ::piServer::sendToServer $::port(serverPlugUpdate) "$::port(serverIrrigation) 0 setRepere [lindex $elem 0] off 10" [lindex $elem 1]
        }
        set ::listeEVOuverteRegulation ""

        set ::status(regulation) "Arretee"
        
        set ::idAfterRegul ""
        
        set ::regulationActivePlateforme ""
    }
}

set ::idAfterRegul ""
set ::regulCuvePlateformeIndex 0
set ::regulCuveZoneIndex 1
set ::listeEVOuverteRegulation ""
set ::regulationActivePlateforme ""
proc regulCuve {} {

    set plateforme [lindex $::listePlateforme $::regulCuvePlateformeIndex]
    set ::listeEVOuverteRegulation ""
    set ::regulationActivePlateforme ""
    
    # Si la plateforme n'existe pas on recommence
    if {$plateforme == ""} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : On recommence pour toutes les plateformes"
        set ::regulCuvePlateformeIndex 0
        set ::idAfterRegul [after 100 regulCuve]
        return
    }
    
    # Si la plateforme est désactivée, on passe à la suivante
    if {$::Activ($plateforme) == 0} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : la plateforme $plateforme est désactivée, on passe à la suivante"
        incr ::regulCuvePlateformeIndex
        set ::idAfterRegul [after 1000 regulCuve]
        return
    }
    
    # Si la plateforme est désactivée, on passe à la suivante
    if {$::cuve($plateforme) == "NA" || 
        $::cuve($plateforme) == "" || 
        $::cuve($plateforme) == "DEFCOM" || 
        $::cuve($plateforme) == "TIMEOUT" ||
        [string is integer $::cuve($plateforme)] != 1} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : Pas d'information sur la hauteur de cuve, on passe à la suivante"
        incr ::regulCuvePlateformeIndex
        set ::idAfterRegul [after 1000 regulCuve]
        return
    }
    
    # Si on a pas d'info sur la date du dernier plein
    if {$::cuve($plateforme,heureDernierPlein) == "NA" || 
        $::cuve($plateforme,heureDernierPlein) == "" || 
        $::cuve($plateforme,heureDernierPlein) == "DEFCOM" || 
        $::cuve($plateforme,heureDernierPlein) == "TIMEOUT" ||
        [string is integer $::cuve($plateforme,heureDernierPlein)] != 1} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : Pas d'information sur le dernier remplissage, on passe à la suivante"
        incr ::regulCuvePlateformeIndex
        set ::idAfterRegul [after 1000 regulCuve]
        return
    }
    
    # Si la plate-forme est pleine, on passe à la suivante
    # Si la cuve de la plateforme a été pleine lors des 3 dernières minutes, on passe à la suivante
    set TimeBeforeLastPlein   [expr [clock seconds] - $::cuve($plateforme,heureDernierPlein)]
    if {$TimeBeforeLastPlein <  [expr  3 * 60]} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : Cuve pleine depuis moins de trois minutes (${TimeBeforeLastPlein}s Vs 180s), on passe à la suivante dans 27s"
        incr ::regulCuvePlateformeIndex
        set ::regulCuveZoneIndex 1
        set ::idAfterRegul [after 27000 regulCuve]
        return
    }
    
    # Si l'heure change, on réinitialise tous les compteurs
    if {$::tempsIrrigation(actualHour) != [clock format [clock seconds] -format "%H"]} {
        set ::tempsIrrigation(actualHour)  [clock format [clock seconds] -format "%H"]
        initRegulationVariable
    }
    # Si l'arrosage a été réalisé plus 10 minute durant l'heure, on passe à la suivante
    if {$::tempsIrrigation(${plateforme}) > $::TempsMaxRegul(general)} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : Cuve trop remplie pour cette heure, on passe à la suivante dans 27s"
        incr ::regulCuvePlateformeIndex
        set ::regulCuveZoneIndex 1
        set ::idAfterRegul [after 27000 regulCuve]
        return
    }
    
    
    if {$::prise(${plateforme},ev,$::regulCuveZoneIndex) == "NA"} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : Fin de toute les zones, on passe à la plate-forme suivante"
        set ::regulCuveZoneIndex 1
        incr ::regulCuvePlateformeIndex
        set ::idAfterRegul [after 1000 regulCuve]
        return
    }
    
    # Si la zone est en régulation, on passe à la suivante
    if {$::irrigationActive == ${plateforme}} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : La plateforme est en régulation, on attend 15 secondes et on retente"
        set ::idAfterRegul [after 15000 regulCuve]
        return
    }
    
    # Si la zone est désactivée, on passe à la suivante
    if {$::Activ(${plateforme},ev,$::regulCuveZoneIndex) == 0} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : La zone est désactivée, on passe à la suivante"
        incr ::regulCuveZoneIndex
        set ::idAfterRegul [after 100 regulCuve]
        return 
    }

    # On sauvegarde le nom de la plateforme en réégulation
    set ::regulationActivePlateforme ${plateforme}
    
    # Le principe est le suivant : 30s de remplissage par zone
    # On met en route l'irrigation avec de l'eau fraiche
    # Mise en route de l'EV de la plateforme set prise(localtechnique,ev,engrais1)
    ::piLog::log [clock milliseconds] "info" "Regul Cuve : Mise en route ${plateforme},ev,$::regulCuveZoneIndex pendant 30 s"; update
    ::piServer::sendToServer $::port(serverPlugUpdate) "$::port(serverIrrigation) 0 setRepere $::prise(${plateforme},ev,$::regulCuveZoneIndex) on 30" $::ip(${plateforme})
    lappend ::listeEVOuverteRegulation [list $::prise(${plateforme},ev,$::regulCuveZoneIndex) $::ip(localtechnique)]
    

    # On met en route l'irrigation avec de l'eau fraiche
    # Mise en route de l'EV de la plateforme set prise(localtechnique,ev,engrais1)
    ::piLog::log [clock milliseconds] "info" "Regul Cuve : Mise en route localtechnique,ev,${plateforme} pendant 30 s" ;update
    ::piServer::sendToServer $::port(serverPlugUpdate) "$::port(serverIrrigation) 0 setRepere $::prise(localtechnique,ev,${plateforme}) on 30" $::ip(localtechnique)
    lappend ::listeEVOuverteRegulation [list $::prise(localtechnique,ev,${plateforme}) $::ip(localtechnique)]
    
    after 10
    
    # On ouvre toutes les électrovannes des engrais associés
    if {$::EngraisEau == 1} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : Mise en route localtechnique,ev,eau pendant 30 s";update
        ::piServer::sendToServer $::port(serverPlugUpdate) "$::port(serverIrrigation) 0 setRepere $::prise(localtechnique,ev,eau) on 30" $::ip(localtechnique)
        lappend ::listeEVOuverteRegulation [list $::prise(localtechnique,ev,eau) $::ip(localtechnique)]
    }
    if {$::Engrais1 == 1} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : Mise en route localtechnique,ev,engrais1 pendant 30 s";update
        ::piServer::sendToServer $::port(serverPlugUpdate) "$::port(serverIrrigation) 0 setRepere $::prise(localtechnique,ev,engrais1) on 30" $::ip(localtechnique)
        lappend ::listeEVOuverteRegulation [list $::prise(localtechnique,ev,engrais1) $::ip(localtechnique)]
    }
    if {$::Engrais2 == 1} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : Mise en route localtechnique,ev,engrais2 pendant 30 s";update
        ::piServer::sendToServer $::port(serverPlugUpdate) "$::port(serverIrrigation) 0 setRepere $::prise(localtechnique,ev,engrais2) on 30" $::ip(localtechnique)
        lappend ::listeEVOuverteRegulation [list $::prise(localtechnique,ev,engrais2) $::ip(localtechnique)]
    }
    if {$::Engrais3 == 1} {
        ::piLog::log [clock milliseconds] "info" "Regul Cuve : Mise en route localtechnique,ev,engrais3 pendant 30 s";update
        ::piServer::sendToServer $::port(serverPlugUpdate) "$::port(serverIrrigation) 0 setRepere $::prise(localtechnique,ev,engrais3) on 30" $::ip(localtechnique)
        lappend ::listeEVOuverteRegulation [list $::prise(localtechnique,ev,engrais3) $::ip(localtechnique)]
    }
    
    after 10
    
    # On met en route le pompe
    ::piLog::log [clock milliseconds] "info" "Regul Cuve : Mise en route localtechnique,surpresseur pendant 29 s";update
    ::piServer::sendToServer $::port(serverPlugUpdate) "$::port(serverIrrigation) 0 setRepere $::prise(localtechnique,pompe) on 29" $::ip(localtechnique)
    lappend ::listeEVOuverteRegulation [list $::prise(localtechnique,pompe) $::ip(localtechnique)]
    
    # On sauvegarde le temps d'irigation pour vérifier qu'on ne remplie pas trop
    set ::tempsIrrigation(${plateforme}) [expr $::tempsIrrigation(${plateforme}) + 30]
    
    incr ::regulCuveZoneIndex
    
    # DAns 30 secondes on indique que la régulation est terminée
    after 30000 "set ::regulationActivePlateforme NA"
    
    set ::idAfterRegul [after 60000 regulCuve]
    
}

