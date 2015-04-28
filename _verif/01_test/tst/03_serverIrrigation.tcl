
namespace eval ::03_serverIrrigation {
    variable errorList ""
}

proc ::03_serverIrrigation::init {} {
    #**********************************************
    # On test le d�marrage de cultipi
    puts "***********************"
    puts "* Test 03_serverIrrigation"
}

proc ::03_serverIrrigation::test {rootDir} {
    variable errorList
    
    puts "* 03_serverIrrigation : D�marrage du module"
    
    set iDOpen [open "| tclsh ${rootDir}/serverIrrigation/serverIrrigation.tcl ${rootDir}/serverIrrigation/confExample/conf.xml"]
    fconfigure $iDOpen -blocking 0
    puts -nonewline [read $iDOpen]
    
    # Il faut 35 seconde au module pour d�marrer
    for {set i 0} {$i < 35} {incr i} {
        after 1000
        update
        puts "* Attente avant d�marrage [expr 35 - $i]s"
        puts -nonewline [read $iDOpen]
        ::cleaWatchDog
    }
    
    puts "* serverIrrigation : V�rification du d�marrage"
    for {set i 0} {$i < 5} {incr i} {
        set results [exec tclsh ${rootDir}/cultiPi/getCommand.tcl serverIrrigation localhost pid]
        if {$results == "TIMEOUT" || $results == "DEFCOM"} {
            puts "* - 03_serverIrrigation : R�ponse au d�marrage : $results"
            set errorTemp "03_serverIrrigation : serverIrrigation ne se lance pas correctement"
            after 1000
        } else {
            set errorTemp ""
            set i 5
        }
        puts -nonewline [read $iDOpen]
    }
    
    # Si �a n'a pas march�, on enregistre
    if {$errorTemp != ""} {
        lappend errorList $errorTemp
    }


    puts "* serverIrrigation : Fermeture du module"
    exec tclsh ${rootDir}/cultiPi/setCommand.tcl serverIrrigation localhost stop
    after 2000
    
    for {set i 0} {$i < 5} {incr i} {
        set results [exec tclsh ${rootDir}/cultiPi/getCommand.tcl serverIrrigation localhost pid]
        if {$results != "TIMEOUT"} {
            puts "* - 03_serverIrrigation : R�ponse � l'arr�t : $results"
            set errorTemp "03_serverIrrigation : serverIrrigation ne s'arrete pas"
            after 1000
        } else {
            set errorTemp ""
            set i 5
        }
        puts -nonewline [read $iDOpen]
    }
    
    close $iDOpen
    
    # Si �a n'a pas march�, on enregistre
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