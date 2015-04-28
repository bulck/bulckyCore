# Premier test : on d�marre l'ensemble

namespace eval ::01_demarrage_individuel {
    variable errorList ""
}


proc ::01_demarrage_individuel::init {} {
    #**********************************************
    # On test le d�marrage de cultipi
    puts "***********************"
    puts "* Test 01_demarage_individuel"
}


proc ::01_demarrage_individuel::test {rootDir} {
    variable errorList
    
    set moduleListLogFirst [list serverLog serverAcqSensor serverCultibox serverHisto serverIrrigation serverMail serverPlugUpdate serverSupervision]
    set moduleListLogEnd   [list serverAcqSensor serverCultibox serverHisto serverIrrigation serverMail serverPlugUpdate serverSupervision serverLog]

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

    # On modifie les acquisitions qui doivent �tre r�alis�es par le serverSUpervision
    set supervisionConf(verbose) debug
    set supervisionConf(nbProcess) 0
    ::piXML::writeXML ${rootDir}/serverSupervision/confExample/conf.xml [array get supervisionConf]

    set listeOpen ""
    foreach module $moduleListLogFirst {
        puts "* 01_demarage_individuel D�marrage de $module"
        puts "* 01_demarage_individuel Ligne de commande : tclsh ${rootDir}/${module}/${module}.tcl ${rootDir}/${module}/confExample/conf.xml"
        lappend listeOpen [open "| tclsh ${rootDir}/${module}/${module}.tcl ${rootDir}/${module}/confExample/conf.xml"]
    }

    # On attend 5 secondes
    after 5000

    # On v�rifie que le process est toujours en route
    foreach module $moduleListLogFirst {
        puts "* 01_demarage_individuel lecture PID $module"
        cleaWatchDog
        for {set i 0} {$i < 5} {incr i} {
            set results [exec tclsh ${rootDir}/cultiPi/getCommand.tcl ${module} localhost pid]
            if {$results == "TIMEOUT" || $results == "DEFCOM"} {
                puts "* 01_demarage_individuel R�ponse au d�marrage : $results"
                set errorTemp "Le server $module ne se lance pas correctement"
                after 1000
            } else {
                set errorTemp ""
                set i 5
            }
        }
        
        # Si �a n'a pas march�, on enregistre
        if {$errorTemp != ""} {
            lappend errorList $errorTemp
        }
    }

    catch {
        puts "* 01_demarage_individuel Liste des process apr�s d�marrage unitaire"
        puts [exec ps aux | grep tclsh]
    }

    # On arrete tous les modules
    foreach module $moduleListLogEnd {
        exec tclsh ${rootDir}/cultiPi/setCommand.tcl ${module} localhost stop
    }


    # On v�rifie qu'ils sont bien arret�e
    foreach module $moduleListLogEnd {
        puts "* 01_demarage_individuel V�rification arr�t $module"
        cleaWatchDog
        for {set i 0} {$i < 5} {incr i} {
            set results [exec tclsh ${rootDir}/cultiPi/getCommand.tcl ${module} localhost pid]
            if {$results != "TIMEOUT"} {
                puts "* 01_demarage_individuel R�ponse � l'arr�t (module $module ): $results"
                set errorTemp "Le server $module ne s'arrete pas"
                after 1000
            } else {
                set errorTemp ""
                set i 5
            }
        }
        
        # Si �a n'a pas march�, on enregistre
        if {$errorTemp != ""} {
            lappend errorList $errorTemp
        }
    }

    catch {
        puts "* 01_demarage_individuel Liste des process apr�s arr�t"
        puts [exec ps aux | grep tclsh]
    }

    # On ferme tous les pipes ouverts
    foreach op $listeOpen {
        fconfigure $op -blocking 0
        puts -nonewline [read $op]
        close $op
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


# tclsh D:\CBX\cultipiCore\_verif\01_test\testListe.tcl