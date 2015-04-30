

proc initcuve {} {

    for {set i 0} {$i < $::configXML(nbPlateforme)} {incr i} {
        
        # Cette proc permet de mettre à jour les variable de cuve
        set ::cuve(${i})    "NA"

        # Ces variables permettent de savoir si la Cuve a été pleine lors des trois dernières minutes
        set ::cuve(${i},heureDernierPlein)    "NA"

    }
}

set cuveIndex 0
set valeurResponse ""
proc updateCuve {} {

    update
    
    incr ::cuveIndex
    if {$::cuveIndex >= $::configXML(nbPlateforme)} {
        set ::cuveIndex 0
    }

    set plateformeNom     $::configXML(plateforme,$::cuveIndex,name)
    set adresseIP         $::configXML(plateforme,$::cuveIndex,ip)
    
    set plateformeActive    $::configXML(plateforme,$::cuveIndex,active)
    
    if {$plateformeActive != 0 && $plateformeActive != "false"} {
        ::piLog::log [clock milliseconds] "debug" "Demande hauteur cuve $plateformeNom ($adresseIP : $::piServer::portNumber(serverAcqSensor))"
        ::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(serverIrrigation) 0 getRepere ::sensor(1,value)" $adresseIP
    }

    after 5000 updateCuve
    
    return
}

