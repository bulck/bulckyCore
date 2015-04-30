
namespace eval ::02_demarrage_cultipi {
    variable errorList ""
}

proc ::02_demarrage_cultipi::init {} {
    #**********************************************
    # On test le démarrage de cultipi
    puts "***********************"
    puts "* Test 02_demarrage_cultipi"
}


proc ::02_demarrage_cultipi::test {rootDir} {
    variable errorList
    
    set moduleListLogFirst [list serverLog serverAcqSensor serverCultibox serverHisto serverIrrigation serverMail serverPlugUpdate serverSupervision]
    set moduleListLogEnd   [list serverAcqSensor serverCultibox serverHisto serverIrrigation serverMail serverPlugUpdate serverSupervision serverLog]


    #On modifie la conf en fonction de l'OS
    if {$::tcl_platform(os) == "Windows NT"} {
        set logConf(logPath) "D:/CBX/cultipiCore"
    } else {
        set logConf(logPath) "./_verif/02_results"
    }
    set logConf(verbose) debug
    ::piXML::writeXML ${rootDir}/_conf/01_defaultConf_RPi/serverLog/conf.xml [array get logConf]

    # On modifie les acquisitions qui doivent être réalisées par le serverSUpervision
    set supervisionConf(verbose) debug
    set supervisionConf(nbProcess) 0
    ::piXML::writeXML ${rootDir}/_conf/01_defaultConf_RPi/serverSupervision/conf.xml [array get supervisionConf]

    # On cré le XML de démarrage
    set fid [open ${rootDir}/_conf/01_defaultConf_RPi/cultiPi/start.xml w+]
    puts $fid {<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>}    
    puts $fid {<starts>}
    puts $fid {    <item name="serverLog" waitAfterUS="1000" pathexe="tclsh" path="./serverLog/serverLog.tcl" xmlconf="./serverLog/conf.xml" />}
    puts $fid {    <item name="serverAcqSensor" waitAfterUS="100" pathexe="tclsh" path="./serverAcqSensor/serverAcqSensor.tcl" xmlconf="./serverAcqSensor/conf.xml" />}
    puts $fid {    <item name="serverPlugUpdate" waitAfterUS="100" pathexe="tclsh" path="./serverPlugUpdate/serverPlugUpdate.tcl" xmlconf="./serverPlugUpdate/conf.xml" />}
    puts $fid {    <item name="serverHisto" waitAfterUS="100" pathexe="tclsh" path="./serverHisto/serverHisto.tcl" xmlconf="./serverHisto/conf.xml" />}
    puts $fid {    <item name="serverCultibox" waitAfterUS="100" pathexe="tclsh" path="./serverCultibox/serverCultibox.tcl" xmlconf="./serverCultibox/conf.xml" />}
    puts $fid {    <item name="serverMail" waitAfterUS="100" pathexe="tclsh" path="./serverMail/serverMail.tcl" xmlconf="./serverMail/conf.xml" />}
    puts $fid {    <item name="serverIrrigation" waitAfterUS="100" pathexe="tclsh" path="./serverIrrigation/serverIrrigation.tcl" xmlconf="./serverIrrigation/conf.xml" />}
    puts $fid {    <item name="serverSupervision" waitAfterUS="100" pathexe="tclsh" path="./serverSupervision/serverSupervision.tcl" xmlconf="./serverSupervision/conf.xml" />}
    puts $fid {</starts>}
    close $fid

    # On modifie les adresses
    set fid [open ${rootDir}/_conf/01_defaultConf_RPi/serverPlugUpdate/plg/pluga w+]
    puts $fid "03"
    puts $fid "50"
    puts $fid "51"
    puts $fid "52"
    close $fid

    set testa [open "| tclsh ${rootDir}/cultiPi/cultiPi.tcl ${rootDir}/_conf"]
    fconfigure $testa -blocking 0
    puts "* 02_demarrage_cultipi tclsh ${rootDir}/cultiPi/cultiPi.tcl ${rootDir}/_conf"


    # On attend un peu que tout soit démarré
    after 5000
    puts -nonewline [read $testa]
    after 5000
    puts -nonewline [read $testa]
    after 5000
    puts -nonewline [read $testa]

    foreach module $moduleListLogFirst {
        puts "* 02_demarrage_cultipi Démarrage Cultipi :lecture PID $module"
        cleaWatchDog
        for {set i 0} {$i < 5} {incr i} {
            set results [exec tclsh ${rootDir}/cultiPi/getCommand.tcl ${module} localhost pid]
            if {$results == "TIMEOUT" || $results == "DEFCOM"} {
                puts "* 02_demarrage_cultipi Démarrage Cultipi :Réponse au démarrage : $results"
                set errorTemp "Démarrage Cultipi : Le server $module ne se lance pas correctement"
                after 1000
            } else {
                set errorTemp ""
                set i 5
            }
        }
        puts -nonewline [read $testa]
        
        # Si ça n'a pas marché, on enregistre
        if {$errorTemp != ""} {
            lappend errorList $errorTemp
        }
    }

    catch {
        puts "* 02_demarrage_cultipi Liste des process après demmarrage cultipi"
        puts [exec ps aux | grep tclsh]
    }


    # On demande l'arret
    exec tclsh ${rootDir}/cultiPi/cultiPistop.tcl

    # On attend 10 secondes
    after 10000

    foreach module $moduleListLogEnd {
        puts "* 02_demarrage_cultipi Vérification arrêt $module"
        cleaWatchDog
        for {set i 0} {$i < 5} {incr i} {
            set results [exec tclsh ${rootDir}/cultiPi/getCommand.tcl ${module} localhost pid]
            if {$results != "TIMEOUT"} {
                puts "* 02_demarrage_cultipi Réponse à l'arrêt (module $module ): $results"
                set errorTemp "Démarrage Cultipi : Le server $module ne s'arrete pas"
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
        puts "* 02_demarrage_cultipi Liste des process après arrêt"
        puts [exec ps aux | grep tclsh]
    }

    puts -nonewline [read $testa]
    close $testa
}

proc ::02_demarrage_cultipi::end {} {
    variable errorList
    if {$errorList == ""} {
        puts "* 02_demarrage_cultipi STATUT : OK"
    } else {
        puts "* 02_demarrage_cultipi STATUT : FAIL"
        puts "* 02_demarrage_cultipi Liste des erreurs :"
        foreach error $errorList {
            puts "* 02_demarrage_cultipi $error"
        }
        
    }
    puts "* 02_demarrage_cultipi Fin"
    puts "***********************"
    return $errorList
}