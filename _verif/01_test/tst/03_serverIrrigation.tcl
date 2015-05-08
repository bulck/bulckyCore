
namespace eval ::03_serverIrrigation {
    variable errorList ""
}

proc ::03_serverIrrigation::init {} {
    #**********************************************
    # On test le démarrage de cultipi
    puts "***********************"
    puts "* Test 03_serverIrrigation"
}

proc ::03_serverIrrigation::test {rootDir} {
    variable errorList
    
    puts "* 03_serverIrrigation : Démarrage du module"
    
    # On modifie le XML
    set irriConf(verbose)               "debug"
    set irriConf(localtechnique,name)   "localtechnique"
    set irriConf(localtechnique,ip)     "localhost"
    set irriConf(localtechnique,pompeName)     "Surpresseur"
    set irriConf(localtechnique,pompePrise)     "2"
    set irriConf(localtechnique,irriActive)     "true"
    set irriConf(nbEngrais)     "4"
    set irriConf(engrais,0,id)     "1"
    set irriConf(engrais,0,name)     "engrais1"
    set irriConf(engrais,0,prise)     "3"
    set irriConf(engrais,0,active)     "true"
    set irriConf(engrais,0,engraisId)     "0"
    set irriConf(engrais,1,id)     "2"
    set irriConf(engrais,1,name)     "engrais2"
    set irriConf(engrais,1,prise)     "4"
    set irriConf(engrais,1,active)     "true"
    set irriConf(engrais,1,engraisId)     "1"
    set irriConf(engrais,2,id)     "3"
    set irriConf(engrais,2,name)     "engrais3"
    set irriConf(engrais,2,prise)     "5"
    set irriConf(engrais,2,active)     "true"
    set irriConf(engrais,2,engraisId)     "2"
    set irriConf(engrais,3,id)     "4"
    set irriConf(engrais,3,name)     "eau"
    set irriConf(engrais,3,prise)     "6"
    set irriConf(engrais,3,active)     "false"
    set irriConf(engrais,3,engraisId)     "3"
    set irriConf(nbPlateforme)     "2"
    set irriConf(plateforme,0,id)     "1"
    set irriConf(plateforme,0,idPlateforme)     "0"
    set irriConf(plateforme,0,name)     "montmartre"
    set irriConf(plateforme,0,ip)     "localhost"
    set irriConf(plateforme,0,pompeName)     "pompe"
    set irriConf(plateforme,0,pompePrise)     "1"
    set irriConf(plateforme,0,active)     "true"
    set irriConf(plateforme,0,limitDesamorcagePompe)     "false"
    set irriConf(plateforme,0,tempsPerco)     "3"
    set irriConf(plateforme,0,tempsPercoNuit)     "3"
    set irriConf(plateforme,0,tempsPercoApresMidi)     "3"
    set irriConf(plateforme,0,tempsMaxRemp)     "3"
    set irriConf(plateforme,0,tempsMaxRempNuit)     "3"
    set irriConf(plateforme,0,tempsMaxRempApresMidi)     "3"
    set irriConf(plateforme,0,priseDansLT)     "7"
    set irriConf(plateforme,0,nbZone)     "3"
    set irriConf(plateforme,0,zone,0,id)     "1"
    set irriConf(plateforme,0,zone,0,motherPlatef)     "0"
    set irriConf(plateforme,0,zone,0,zoneId)     "0"
    set irriConf(plateforme,0,zone,0,name)     "EV_sud"
    set irriConf(plateforme,0,zone,0,prise)     "2"
    set irriConf(plateforme,0,zone,0,tempsOn)     "2"
    set irriConf(plateforme,0,zone,0,tempsOff)     "40"
    set irriConf(plateforme,0,zone,0,tempsOnNuit)     "2"
    set irriConf(plateforme,0,zone,0,tempsOffNuit)     "40"
    set irriConf(plateforme,0,zone,0,tempsOnApresMidi)     "2"
    set irriConf(plateforme,0,zone,0,tempsOffApresMidi)     "40"
    set irriConf(plateforme,0,zone,0,active)     "true"
    set irriConf(plateforme,0,zone,0,coef)     "1.00"
    set irriConf(plateforme,0,zone,1,id)     "2"
    set irriConf(plateforme,0,zone,1,motherPlatef)     "0"
    set irriConf(plateforme,0,zone,1,zoneId)     "1"
    set irriConf(plateforme,0,zone,1,name)     "EV_milieu"
    set irriConf(plateforme,0,zone,1,prise)     "3"
    set irriConf(plateforme,0,zone,1,tempsOn)     "2"
    set irriConf(plateforme,0,zone,1,tempsOff)     "40"
    set irriConf(plateforme,0,zone,1,tempsOnNuit)     "2"
    set irriConf(plateforme,0,zone,1,tempsOffNuit)     "40"
    set irriConf(plateforme,0,zone,1,tempsOnApresMidi)     "2"
    set irriConf(plateforme,0,zone,1,tempsOffApresMidi)     "40"
    set irriConf(plateforme,0,zone,1,active)     "true"
    set irriConf(plateforme,0,zone,1,coef)     "1.00"
    set irriConf(plateforme,0,zone,2,id)     "3"
    set irriConf(plateforme,0,zone,2,motherPlatef)     "0"
    set irriConf(plateforme,0,zone,2,zoneId)     "2"
    set irriConf(plateforme,0,zone,2,name)     "EV_nord"
    set irriConf(plateforme,0,zone,2,prise)     "4"
    set irriConf(plateforme,0,zone,2,tempsOn)     "2"
    set irriConf(plateforme,0,zone,2,tempsOff)     "40"
    set irriConf(plateforme,0,zone,2,tempsOnNuit)     "2"
    set irriConf(plateforme,0,zone,2,tempsOffNuit)     "40"
    set irriConf(plateforme,0,zone,2,tempsOnApresMidi)     "2"
    set irriConf(plateforme,0,zone,2,tempsOffApresMidi)     "40"
    set irriConf(plateforme,0,zone,2,active)     "true"
    set irriConf(plateforme,0,zone,2,coef)     "1.00"
    set irriConf(plateforme,1,id)     "2"
    set irriConf(plateforme,1,idPlateforme)     "1"
    set irriConf(plateforme,1,name)     "dantin"
    set irriConf(plateforme,1,ip)       "localhost"
    set irriConf(plateforme,1,pompeName)     "pompe"
    set irriConf(plateforme,1,pompePrise)     "1"
    set irriConf(plateforme,1,active)     "false"
    set irriConf(plateforme,1,limitDesamorcagePompe)     "true"
    set irriConf(plateforme,1,tempsPerco)     "3"
    set irriConf(plateforme,1,tempsPercoNuit)     "3"
    set irriConf(plateforme,1,tempsPercoApresMidi)     "3"
    set irriConf(plateforme,1,tempsMaxRemp)     "3"
    set irriConf(plateforme,1,tempsMaxRempNuit)     "3"
    set irriConf(plateforme,1,tempsMaxRempApresMidi)     "3"
    set irriConf(plateforme,1,priseDansLT)     "8"
    set irriConf(plateforme,1,nbZone)     "2"
    set irriConf(plateforme,1,zone,0,id)     "4"
    set irriConf(plateforme,1,zone,0,motherPlatef)     "1"
    set irriConf(plateforme,1,zone,0,zoneId)     "0"
    set irriConf(plateforme,1,zone,0,name)     "EV_nord"
    set irriConf(plateforme,1,zone,0,prise)     "2"
    set irriConf(plateforme,1,zone,0,tempsOn)     "10"
    set irriConf(plateforme,1,zone,0,tempsOff)     "15"
    set irriConf(plateforme,1,zone,0,tempsOnNuit)     "10"
    set irriConf(plateforme,1,zone,0,tempsOffNuit)     "15"
    set irriConf(plateforme,1,zone,0,tempsOnApresMidi)     "2"
    set irriConf(plateforme,1,zone,0,tempsOffApresMidi)     "40"
    set irriConf(plateforme,1,zone,0,active)     "true"
    set irriConf(plateforme,1,zone,0,coef)     "1.00"
    set irriConf(plateforme,1,zone,1,id)     "5"
    set irriConf(plateforme,1,zone,1,motherPlatef)     "1"
    set irriConf(plateforme,1,zone,1,zoneId)     "1"
    set irriConf(plateforme,1,zone,1,name)     "EV_sud"
    set irriConf(plateforme,1,zone,1,prise)     "3"
    set irriConf(plateforme,1,zone,1,tempsOn)       "10"
    set irriConf(plateforme,1,zone,1,tempsOff)      "15"
    set irriConf(plateforme,1,zone,1,tempsOnNuit)     "10"
    set irriConf(plateforme,1,zone,1,tempsOffNuit)     "15"
    set irriConf(plateforme,1,zone,1,tempsOnApresMidi)     "2"
    set irriConf(plateforme,1,zone,1,tempsOffApresMidi)     "40"
    set irriConf(plateforme,1,zone,1,active)        "true"
    set irriConf(plateforme,1,zone,1,coef)          "1.00"
    
    ::piXML::writeXML ${rootDir}/serverIrrigation/confExample/conf.xml [array get irriConf]
    
    set iDOpen [open "| tclsh ${rootDir}/serverIrrigation/serverIrrigation.tcl ${rootDir}/serverIrrigation/confExample/conf.xml"]
    fconfigure $iDOpen -blocking 0
    puts -nonewline [read $iDOpen]
    
    # Il faut 35 seconde au module pour démarrer
    for {set i 0} {$i < 6} {incr i} {
        after 1000
        update
        puts "* Attente avant démarrage [expr 6 - $i]s"
        puts -nonewline [read $iDOpen]
        ::cleaWatchDog
    }
    
    # On vérifie qu'il s'est bien lancé
    set errorTemp [checkStarted 03_serverIrrigation serverIrrigation $iDOpen ${rootDir}]
    # Si ça n'a pas marché, on enregistre
    if {$errorTemp != ""} {
        lappend errorList $errorTemp
    }
    
    puts "* serverIrrigation : Démarrage de l'acquisition des capteurs"
    
    # On modifie le XML
    set acqConf(verbose)    "info"
    set acqConf(simulator)  "on"
    set acqConf(simulator,nbSensor)  "1"
    set acqConf(simulator,0x01,max)  "5"
    set acqConf(simulator,0x01,min)  "0"
    ::piXML::writeXML ${rootDir}/serverAcqSensor/confExample/conf.xml [array get acqConf]
    
    set iDAcqSensor [open "| tclsh ${rootDir}/serverAcqSensor/serverAcqSensor.tcl ${rootDir}/serverAcqSensor/confExample/conf.xml"]
    fconfigure $iDAcqSensor -blocking 0
    # On vérifie qu'il s'est bien lancé
    after 1000
    set errorTemp [checkStarted 03_serverIrrigation serverAcqSensor $iDAcqSensor ${rootDir}]

    
    # L'ensemble est démarré
    for {set i 0} {$i < 120} {incr i} {
        puts -nonewline [read $iDOpen]
        puts -nonewline [read $iDAcqSensor]
        after 1000
    }
    
    # On vérifie que tout le monde tourne encore
    set errorTemp [checkStarted 03_serverIrrigation serverIrrigation $iDOpen ${rootDir}]
    # Si ça n'a pas marché, on enregistre
    if {$errorTemp != ""} {
        lappend errorList $errorTemp
    }
    

    puts "* serverIrrigation : Fermeture des modules"
    exec tclsh ${rootDir}/cultiPi/setCommand.tcl serverIrrigation localhost stop
    exec tclsh ${rootDir}/cultiPi/setCommand.tcl serverAcqSensor localhost stop
    after 2000
    
    set errorTemp [checkStoped 03_serverIrrigation serverAcqSensor $iDAcqSensor ${rootDir}]
    close $iDAcqSensor
    if {$errorTemp != ""} {
        lappend errorList $errorTemp
    }

    set errorTemp [checkStoped 03_serverIrrigation serverIrrigation $iDOpen ${rootDir}]
    close $iDOpen
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