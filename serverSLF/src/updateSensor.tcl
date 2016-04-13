
proc updateSensor {zone} {


   set adresseIP    $::configXML(zone,${zone},ip)

    # Il nous faut : 
    # La hauteur de la cuve 
    # L'�tat des bouttons
    
    set listeVariable ""
    
    set capteurNiveau $::configXML(zone,${zone},capteur,niveau)
    lappend listeVariable ::sensor(${capteurNiveau},value)
    set ::capteur(${zone},niveau) "" 
    
    ::piLog::log [clock milliseconds] "debug" "Demande capteur $zone ($adresseIP : $::piServer::portNumber(serverAcqSensorV2))"
    ::piServer::sendToServer $::piServer::portNumber(serverAcqSensorV2) "$::piServer::portNumber(${::moduleLocalName}) 0 getRepere [join $listeVariable " "]" $adresseIP

    after [expr 5000] [list after idle updateSensor $zone]
    
    return
}

