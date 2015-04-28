
namespace eval ::03_serverIrrigation {
    variable errorList ""
}

proc ::03_serverIrrigation::init {} {
    #**********************************************
    # On test le démarrage de cultipi
    puts "***********************"
    puts "* Test 03_serverIrrigation"
}

proc ::03_serverIrrigation::test {rootDir} {
    variable errorList
    
    puts "* 03_serverIrrigation : Démarrage du module"
    
    set iDOpen [open "| tclsh ${rootDir}/serverIrrigation/serverIrrigation.tcl ${rootDir}/serverIrrigation/confExample/conf.xml"]
    fconfigure $iDOpen -blocking 0
    puts -nonewline [read $iDOpen]
    
    # Il faut 35 seconde au module pour démarrer
    for {set i 0} {$i < 35} {incr i} {
        after 1000
        update
        puts "* Attente avant démarrage [expr 35 - $i]s"
        puts -nonewline [read $iDOpen]
        ::cleaWatchDog
    }
    
    puts "* serverIrrigation : Vérification du démarrage"
    for {set i 0} {$i < 5} {incr i} {
        set results [exec tclsh ${rootDir}/cultiPi/getCommand.tcl serverIrrigation localhost pid]
        if {$results == "TIMEOUT" || $results == "DEFCOM"} {
            puts "* - 03_serverIrrigation : Réponse au démarrage : $results"
            set errorTemp "03_serverIrrigation : serverIrrigation ne se lance pas correctement"
            after 1000
        } else {
            set errorTemp ""
            set i 5
        }
        puts -nonewline [read $iDOpen]
    }
    
    # Si ça n'a pas marché, on enregistre
    if {$errorTemp != ""} {
        lappend errorList $errorTemp
    }


    puts "* serverIrrigation : Fermeture du module"
    exec tclsh ${rootDir}/cultiPi/setCommand.tcl serverIrrigation localhost stop
    after 2000
    
    for {set i 0} {$i < 5} {incr i} {
        set results [exec tclsh ${rootDir}/cultiPi/getCommand.tcl serverIrrigation localhost pid]
        if {$results != "TIMEOUT"} {
            puts "* - 03_serverIrrigation : Réponse à l'arrêt : $results"
            set errorTemp "03_serverIrrigation : serverIrrigation ne s'arrete pas"
            after 1000
        } else {
            set errorTemp ""
            set i 5
        }
        puts -nonewline [read $iDOpen]
    }
    
    close $iDOpen
    
    # Si ça n'a pas marché, on enregistre
    if {$errorTemp != ""} {
        lappend errorList $errorTemp
    }
}

proc ::03_serverIrrigation::end {} {
    variable errorList
    if {$errorList == ""} {
        puts "* STATUT : OK"
    } else {
        puts "* STATUT : FAIL"
        puts "* Liste des erreurs :"
        foreach error $errorList {
            puts "* $error"
        }
        
    }
    puts "* Fin"
    puts "***********************"
    return $errorList
}