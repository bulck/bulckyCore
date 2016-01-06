# Premier test : on démarre l'ensemble

namespace eval ::01_demarrage_individuel {
    variable errorList ""
}


proc ::01_demarrage_individuel::init {} {
    #**********************************************
    # On test le démarrage de cultipi
    puts "***********************"
    puts "* Test 01_demarage_individuel"
}


proc ::01_demarrage_individuel::test {rootDir} {
    variable errorList
    
    set moduleListLogFirst [list serverLog serverAcqSensor serverCultibox serverHisto serverMail serverPlugUpdate serverSupervision]
    set moduleListLogEnd   [list serverAcqSensor serverCultibox serverHisto serverMail serverPlugUpdate serverSupervision serverLog]

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

    # On modifie les acquisitions qui doivent être réalisées par le serverSupervision
    # set supervisionConf(verbose) debug
    # set supervisionConf(nbProcess) 0
    ::piXML::writeXML ${rootDir}/serverSupervision/confExample/conf.xml [array get supervisionConf]
    # Pour chaque process, on crée les fonctions associées
    foreach confFileName [glob -nocomplain -directory ${rootDir}/serverSupervision/confExample *.xml] {
        file rename -force $confFileName [string map {".xml" ".txml"} $confFileName]
    }

    foreach module $moduleListLogFirst {
        puts "* 01_demarage_individuel Démarrage de $module"
        puts "* 01_demarage_individuel Ligne de commande : tclsh ${rootDir}/${module}/${module}.tcl ${rootDir}/${module}/confExample/conf.xml"
        set listeOpen($module) [open "| tclsh ${rootDir}/${module}/${module}.tcl ${rootDir}/${module}/confExample/conf.xml"]
        fconfigure $listeOpen($module) -blocking 0
    }

    # On attend 5 secondes
    after 5000

    # On vérifie que le process est toujours en route
    foreach module $moduleListLogFirst {
        puts "* 01_demarage_individuel lecture PID $module"
        cleaWatchDog
        
        set errorTemp [checkStarted 01_demarage_individuel ${module} $listeOpen($module) ${rootDir}]
        
        # Si ça n'a pas marché, on enregistre
        if {$errorTemp != ""} {
            lappend errorList $errorTemp
        }
    }

    catch {
        puts "* 01_demarage_individuel Liste des process après démarrage unitaire"
        puts [exec ps aux | grep tclsh]
    }

    # On arrete tous les modules
    foreach module $moduleListLogEnd {
        exec tclsh ${rootDir}/cultiPi/setCommand.tcl ${module} localhost stop
    }


    # On vérifie qu'ils sont bien arretée
    foreach module $moduleListLogEnd {
        puts "* 01_demarage_individuel Vérification arrêt $module"
        cleaWatchDog
        
        set errorTemp [checkStoped 01_demarage_individuel ${module} $listeOpen($module) ${rootDir}]
        
        # Si ça n'a pas marché, on enregistre
        if {$errorTemp != ""} {
            lappend errorList $errorTemp
        }
    }

    catch {
        puts "* 01_demarage_individuel Liste des process après arrêt"
        puts [exec ps aux | grep tclsh]
    }

    # On ferme tous les pipes ouverts
    foreach module $moduleListLogFirst {
        puts -nonewline [read $listeOpen($module)]
        close $listeOpen($module)
    }

}

proc ::01_demarrage_individuel::end {} {
    variable errorList
    if {$errorList == ""} {
        puts "* 01_demarage_individuel STATUT : OK"
    } else {
        puts "* 01_demarage_individuel STATUT : FAIL"
        puts "* 01_demarage_individuel Liste des erreurs :"
        foreach error $errorList {
            puts "* 01_demarage_individuel $error"
        }
        
    }
    puts "* 01_demarage_individuel Fin"
    puts "***********************"
    return $errorList
}


# tclsh D:\CBX\06_bulckyCore\_verif\01_test\testListe.tcl