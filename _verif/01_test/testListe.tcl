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

set testList [list 01_demarrage_individuel 02_demarrage_cultipi 03_serverIrrigation]

# On charge les scripts
source [file join $rootDirLib _verif 01_test src file_func.tcl]
source [file join $rootDirLib _verif 01_test src util_func.tcl]
foreach test $testList {
    source [file join $rootDirLib _verif 01_test tst ${test}.tcl]
}

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
puts "* Lancement des test..."

cleaWatchDog
displayProcess

# On lance tous les tests
foreach test $testList {
    ::${test}::init
    ::${test}::test $rootDir
    set errorTempList [::${test}::end]
    if {$errorTempList != ""} {
        foreach errorTemp $errorTempList {
            lappend errorList $errorTemp
        }
    }

    cleaWatchDog
    displayProcess
}


#**********************************************

after cancel $::IDAfterWatchdog

if {$errorList == ""} {
    puts "* Ensemble des test : OK"
    exit 0
} else {
    puts "* Liste des erreurs :"
    foreach err $errorList {
        puts $err
    }
    exit 1
}

# tclsh D:\CBX\cultipiCore\_verif\01_test\testListe.tcl