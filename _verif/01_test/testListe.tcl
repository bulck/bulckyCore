# Ce script définit la liste des tests à réaliser
if {$::tcl_platform(os) == "Windows NT"} {
    set rootDir "D:/CBX/cultipiCore"
} else {
    set rootDir "."
}

set rootDirLib [file dirname [file dirname [file dirname [info script]]]]
lappend auto_path [file join $rootDirLib lib tcl]
package require piLog
package require piServer
package require piXML
package require piTools

# On charge les scripts
source [file join $rootDirLib _verif 01_test src file_func.tcl]

set errorList ""

set compteurWatchdog 0
set IDAfterWatchdog ""
proc watchDog {} {

    set ::compteurWatchdog [expr $::compteurWatchdog + 1]
    
    if {$::compteurWatchdog > 30} {
        puts "Le watchdog a sauté !"
        exit 0
    }

    set IDAfterWatchdog [after 1000 watchDog]
}
proc cleaWatchDog {} {
    set ::compteurWatchdog 0
}
set IDAfterWatchdog [after 1000 watchDog]

# Premier test : on démarre l'ensemble
puts "Lancement des test..."

catch {
    puts "Liste des process avant tout"
    puts [exec ps aux | grep tclsh]
}

set moduleListLogFirst [list serverLog serverAcqSensor serverCultibox serverHisto serverIrrigation serverMail serverPlugUpdate serverSupervision]
set moduleListLogEnd   [list serverAcqSensor serverCultibox serverHisto serverIrrigation serverMail serverPlugUpdate serverSupervision serverLog]

#**********************************************
# On test le démarrage individuel des modules
source [file join $rootDirLib _verif 01_test tst 01_demarrage_individuel.tcl]

# On test le démarrage du cultipi
source [file join $rootDirLib _verif 01_test tst 02_demarrage_cultipi.tcl]


    
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