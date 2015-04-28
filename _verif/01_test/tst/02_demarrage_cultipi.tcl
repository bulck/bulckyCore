
#**********************************************
# On test le démarrage de cultipi
puts "* Test démarrage cultipi"

#On modifie la conf en fonction de l'OS
if {$::tcl_platform(os) == "Windows NT"} {
    set logConf(logPath) "D:/CBX/cultipiCore"
} else {
    set logConf(logPath) "./_verif/02_results"
}
set logConf(verbose) debug
::piXML::writeXML ${rootDir}/_conf/01_defaultConf_RPi/serverLog/conf.xml [array get logConf]

# On modifie les adresses
set fid [open ${rootDir}/_conf/01_defaultConf_RPi/serverPlugUpdate/plg/pluga w+]
puts $fid "03"
puts $fid "50"
puts $fid "51"
puts $fid "52"
close $fid

set testa [open "| tclsh ${rootDir}/cultiPi/cultiPi.tcl ${rootDir}/_conf"]
fconfigure $testa -blocking 0
puts "tclsh ${rootDir}/cultiPi/cultiPi.tcl ${rootDir}/_conf"


# On attend un peu que tout soit démarré
after 5000
puts [read $testa]
after 5000
puts [read $testa]
after 5000
puts [read $testa]

foreach module $moduleListLogFirst {
    puts "Démarrage Cultipi :lecture PID $module"
    cleaWatchDog
    for {set i 0} {$i < 5} {incr i} {
        set results [exec tclsh ${rootDir}/cultiPi/getCommand.tcl ${module} localhost pid]
        if {$results == "TIMEOUT" || $results == "DEFCOM"} {
            puts "Démarrage Cultipi :Réponse au démarrage : $results"
            set errorTemp "Démarrage Cultipi : Le server $module ne se lance pas correctement"
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
    puts "Liste des process après demmarrage cultipi"
    puts [exec ps aux | grep tclsh]
}


# On demande l'arret
exec tclsh ${rootDir}/cultiPi/cultiPistop.tcl

# On attend 10 secondes
after 10000

foreach module $moduleListLogEnd {
    puts "Vérification arrêt $module"
    cleaWatchDog
    for {set i 0} {$i < 5} {incr i} {
        set results [exec tclsh ${rootDir}/cultiPi/getCommand.tcl ${module} localhost pid]
        if {$results != "TIMEOUT"} {
            puts "Réponse à l'arrêt (module $module ): $results"
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
    puts "Liste des process après arrêt"
    puts [exec ps aux | grep tclsh]
}

puts [read $testa]
close $testa

puts "* Fin démarrage cultipi"