

proc displayProcess {} {

    catch {
        puts "* Liste des process : "
        puts [exec ps aux | grep tclsh]
    }

}

proc checkStarted {test module iDOpen rootDir} {
    set errorTemp ""
    puts "* $module : Vérification du démarrage"
    for {set i 0} {$i < 5} {incr i} {
        set results [exec tclsh ${rootDir}/cultiPi/getCommand.tcl $module localhost pid]
        if {$results == "TIMEOUT" || $results == "DEFCOM"} {
            puts "* - $test : Réponse au démarrage : $results"
            set errorTemp "$test : $module ne se lance pas correctement"
            after 1000
        } else {
            set errorTemp ""
            set i 5
        }
        puts -nonewline [read $iDOpen]
    }
    
    return $errorTemp

}

proc checkStoped {test module iDOpen rootDir} {
    set errorTemp ""
    puts "* $module : Vérification de l'arret"
    for {set i 0} {$i < 5} {incr i} {
        set results [exec tclsh ${rootDir}/cultiPi/getCommand.tcl $module localhost pid]
        if {$results != "TIMEOUT"} {
            puts "* - $test : Réponse à l'arret : $results"
            set errorTemp "$test : $module ne s'arrete correctement"
            after 1000
        } else {
            set errorTemp ""
            set i 5
        }
        puts -nonewline [read $iDOpen]
    }
    
    return $errorTemp

}