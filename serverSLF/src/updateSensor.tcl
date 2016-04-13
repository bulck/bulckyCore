
proc init_updateSensor {zone} {
   set adresseIP    $::configXML(zone,${zone},ip)
   set nbSensor     $::configXML(zone,${zone},nbsensor)
   
    for {set i 1} {$i <= $nbSensor} { incr i} {
        set ::sensor(${adresseIP},${i}) "INIT"
    }
    
    set ::etatLDV(updateSensor) ""
}

proc updateSensor {zone} {


    set adresseIP    $::configXML(zone,${zone},ip)
    set nbSensor     $::configXML(zone,${zone},nbsensor)
    set ::etatLDV(updateSensor) ""
    # Il nous faut : 
    # La hauteur de la cuve 
    # L'état des bouttons
    
    set listeVariable ""
    
    set capteurNiveau $::configXML(zone,${zone},capteur,niveau)
    for {set i 1} {$i <= $nbSensor} { incr i} {
        lappend listeVariable "::sensor(${i},value)"
    }
    
    ::piLog::log [clock milliseconds] "debug" "Demande capteur $zone ($adresseIP : $::piServer::portNumber(serverAcqSensorV2))"
    ::piServer::sendToServer $::piServer::portNumber(serverAcqSensorV2) "$::piServer::portNumber(${::moduleLocalName}) 0 getRepere [join $listeVariable " "]" $adresseIP

    set ::etatLDV(updateSensor) [after [expr 5000] [list after idle updateSensor $zone]]
    
    return
}

