
#**********************************************
# On test le d�marrage de cultipi
puts "* Test d�marrage cultipi"

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


# On attend un peu que tout soit d�marr�
after 5000
puts [read $testa]
after 5000
puts [read $testa]
after 5000
puts [read $testa]

foreach module $moduleListLogFirst {
    puts "D�marrage Cultipi :lecture PID $module"
    cleaWatchDog
    for {set i 0} {$i < 5} {incr i} {
        set results [exec tclsh ${rootDir}/cultiPi/getCommand.tcl ${module} localhost pid]
        if {$results == "TIMEOUT" || $results == "DEFCOM"} {
            puts "D�marrage Cultipi :R�ponse au d�marrage : $results"
            set errorTemp "D�marrage Cultipi : Le server $module ne se lance pas correctement"
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
    puts "Liste des process apr�s demmarrage cultipi"
    puts [exec ps aux | grep tclsh]
}


# On demande l'arret
exec tclsh ${rootDir}/cultiPi/cultiPistop.tcl

# On attend 10 secondes
after 10000

foreach module $moduleListLogEnd {
    puts "V�rification arr�t $module"
    cleaWatchDog
    for {set i 0} {$i < 5} {incr i} {
        set results [exec tclsh ${rootDir}/cultiPi/getCommand.tcl ${module} localhost pid]
        if {$results != "TIMEOUT"} {
            puts "R�ponse � l'arr�t (module $module ): $results"
            set errorTemp "D�marrage Cultipi : Le server $module ne s'arrete pas"
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
    puts "Liste des process apr�s arr�t"
    puts [exec ps aux | grep tclsh]
}

puts [read $testa]
close $testa

puts "* Fin d�marrage cultipi"