# Premier test : on démarre l'ensemble
puts "* Demarrage 01_demarage_individuel.tcl"


#**********************************************
# Lancement individuel des modules

#On modifie la conf en fonction de l'OS
if {$::tcl_platform(os) == "Windows NT"} {
    set logConf(logPath) "D:/CBX/cultipiCore"
} else {
    set logConf(logPath) "./_verif/02_results"
}
set logConf(verbose) debug
::piXML::writeXML ${rootDir}/serverLog/confExample/conf.xml [array get logConf]
setPluga ${rootDir}/serverPlugUpdate/confExample/plg/pluga [list 50 51 52]

# On modifie les acquisitions qui doivent être réalisées par le serverSUpervision
set supervisionConf(verbose) debug
set supervisionConf(nbProcess) 0
::piXML::writeXML ${rootDir}/serverSupervision/confExample/conf.xml [array get supervisionConf]

set listeOpen ""
foreach module $moduleListLogFirst {
    puts "Démarrage de $module"
    puts "Ligne de commande : tclsh ${rootDir}/${module}/${module}.tcl ${rootDir}/${module}/confExample/conf.xml"
    lappend listeOpen [open "| tclsh ${rootDir}/${module}/${module}.tcl ${rootDir}/${module}/confExample/conf.xml"]
}

# On attend 5 secondes
after 5000

# On vérifie que le process est toujours en route
foreach module $moduleListLogFirst {
    puts "lecture PID $module"
    cleaWatchDog
    for {set i 0} {$i < 5} {incr i} {
        set results [exec tclsh ${rootDir}/cultiPi/getCommand.tcl ${module} localhost pid]
        if {$results == "TIMEOUT" || $results == "DEFCOM"} {
            puts "Réponse au démarrage : $results"
            set errorTemp "Le server $module ne se lance pas correctement"
            after 1000
        } else {
            set errorTemp ""
            set i 5
        }
    }
    
    # Si ça n'a pas marché, on enregistre
    if {$errorTemp != ""} {
        lappend errorList $errorTemp
    }
}

catch {
    puts "Liste des process après démarrage unitaire"
    puts [exec ps aux | grep tclsh]
}

# On arrete tous les modules
foreach module $moduleListLogEnd {
    exec tclsh ${rootDir}/cultiPi/setCommand.tcl ${module} localhost stop
}


# On vérifie qu'ils sont bien arretée
foreach module $moduleListLogEnd {
    puts "Vérification arrêt $module"
    cleaWatchDog
    for {set i 0} {$i < 5} {incr i} {
        set results [exec tclsh ${rootDir}/cultiPi/getCommand.tcl ${module} localhost pid]
        if {$results != "TIMEOUT"} {
            puts "Réponse à l'arrêt (module $module ): $results"
            set errorTemp "Le server $module ne s'arrete pas"
            after 1000
        } else {
            set errorTemp ""
            set i 5
        }
    }
    
    # Si ça n'a pas marché, on enregistre
    if {$errorTemp != ""} {
        lappend errorList $errorTemp
    }
}

catch {
    puts "Liste des process après arrêt"
    puts [exec ps aux | grep tclsh]
}

# On ferme tous les pipes ouverts
foreach op $listeOpen {
    fconfigure $op -blocking 0
    puts [read $op]
    close $op
}

puts "* Fin 01_demarage_individuel.tcl"
if {$errorList == ""} {
    puts "* TEST STATUT : OK"
} else {
    puts "* TEST STATUT : FAIL"
}


# tclsh D:\CBX\cultipiCore\_verif\01_test\testListe.tcl