# Ce script d�finit la liste des tests � r�aliser
if {$::tcl_platform(os) == "Windows NT"} {
    set rootDir "D:/CBX/cultipiCore"
} else {
    set rootDir "."
}

set rootDir [file dirname [file dirname [file dirname [info script]]]]
lappend auto_path [file join $rootDir lib tcl]
package require piLog
package require piServer
package require piXML
package require piTools

set errorList ""

set compteurWatchdog 0
set IDAfterWatchdog ""
proc watchDog {} {

    set ::compteurWatchdog [expr $::compteurWatchdog + 1]
    
    if {$::compteurWatchdog > 30} {
        puts "Le watchdog a saut� !"
        exit 0
    }

    set IDAfterWatchdog [after 1000 watchDog]
}
proc cleaWatchDog {} {
    set ::compteurWatchdog 0
}
set IDAfterWatchdog [after 1000 watchDog]

# Premier test : on d�marre l'ensemble
puts "Lancement des test..."

catch {
    puts "Liste des process avant tout"
    puts [exec ps aux | grep tclsh]
}

set moduleListLogFirst [list serverLog serverAcqSensor serverCultibox serverHisto serverIrrigation serverMail serverPlugUpdate serverSupervision]
set moduleListLogEnd   [list serverAcqSensor serverCultibox serverHisto serverIrrigation serverMail serverPlugUpdate serverSupervision serverLog]

proc setPluga {filename adressList} {

    set fid [open $filename w+]

    set nbAdress [llength $adressList]
    if {$nbAdress < 10} {
        set nbAdress "0${nbAdress}"
    }

    puts $fid $nbAdress

    foreach adress $adressList {
        puts $fid $adress
    }

    close $fid

}


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

set listeOpen ""
foreach module $moduleListLogFirst {
    puts "D�marrage de $module"
    puts "Ligne de commande : tclsh ${rootDir}/${module}/${module}.tcl ${rootDir}/${module}/confExample/conf.xml"
    lappend listeOpen [open "| tclsh ${rootDir}/${module}/${module}.tcl ${rootDir}/${module}/confExample/conf.xml"]
}

# On attend 5 secondes
after 5000

# On v�rifie que le process est toujours en route
foreach module $moduleListLogFirst {
    puts "lecture PID $module"
    cleaWatchDog
    for {set i 0} {$i < 5} {incr i} {
        set results [exec tclsh ${rootDir}/cultiPi/getCommand.tcl ${module} localhost pid]
        if {$results == "TIMEOUT" || $results == "DEFCOM"} {
            puts "R�ponse au d�marrage : $results"
            set errorTemp "Le server $module ne se lance pas correctement"
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
    puts "Liste des process apr�s d�marrage unitaire"
    puts [exec ps aux | grep tclsh]
}

# On arrete tous les modules
foreach module $moduleListLogEnd {
    exec tclsh ${rootDir}/cultiPi/setCommand.tcl ${module} localhost stop
}


# On v�rifie qu'ils sont bien arret�e
foreach module $moduleListLogEnd {
    puts "V�rification arr�t $module"
    cleaWatchDog
    for {set i 0} {$i < 5} {incr i} {
        set results [exec tclsh ${rootDir}/cultiPi/getCommand.tcl ${module} localhost pid]
        if {$results != "TIMEOUT"} {
            puts "R�ponse � l'arr�t (module $module ): $results"
            set errorTemp "Le server $module ne s'arrete pas"
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

# On ferme tous les pipes ouverts
foreach op $listeOpen {
    fconfigure $op -blocking 0
    puts [read $op]
    close $op
}

#**********************************************
# On test le d�marrage de cultipi

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
puts "tclsh ${rootDir}/cultiPi/cultiPi.tcl ${rootDir}/_conf"


# On attend un peu que tout soit d�marr�
after 15000


foreach module $moduleListLogFirst {
    puts "D�marrage Cultipi :lecture PID $module"
    cleaWatchDog
    for {set i 0} {$i < 5} {incr i} {
        set results [exec tclsh ${rootDir}/cultiPi/getCommand.tcl ${module} localhost pid]
        if {$results == "TIMEOUT" || $results == "DEFCOM"} {
            puts "D�marrage Cultipi :R�ponse au d�marrage : $results"
            set errorTemp "D�marrage Cultipi : Le server $module ne se lance pas correctement"
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
            set errorTemp "Le server $module ne s'arrete pas"
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

fconfigure $testa -blocking 0
puts [read $testa]
close $testa
    
#**********************************************

after cancel $::IDAfterWatchdog

if {$errorList == ""} {
    exit 0
} else {
    puts "Liste des erreurs :"
    foreach err $errorList {
        puts $err
    }
    exit 1
}

# tclsh D:\CBX\cultipiCore\_verif\01_test\testListe.tcl