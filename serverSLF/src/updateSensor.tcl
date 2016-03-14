
proc updateSensor {zone} {


   set adresseIP    $::configXML(zone,${zone},ip)

    # Il nous faut : 
    # La hauteur de la cuve 
    # L'état des bouttons
    
    set listeVariable ""
    
    set capteurNiveau $::configXML(zone,${zone},capteur,niveau)
    lappend listeVariable ::sensor(${capteurNiveau},value)
    set capteur(${zone},niveau) "" 
    
    for {set i 0} {$i < $::configXML(nbPlateforme)} {incr i} {
        set capteur(${zone},bouton,${i}) "" 
    
        set bouton $::configXML(plateforme,$i,boutonarret,prise)
        
        lappend listeVariable ::sensor(${bouton},value)
    }
    

    ::piLog::log [clock milliseconds] "debug" "Demande capteur $zone ($adresseIP : $::piServer::portNumber(serverAcqSensor))"
    ::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(serverIrrigation) 0 getRepere [join $listeVariable " "]" $adresseIP

    after [expr 500] [list after idle updateSensor $zone]
    
    return
}

