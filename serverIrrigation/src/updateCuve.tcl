


proc initcuve {} {

    for {set i 0} {$i < $::configXML(nbPlateforme)} {incr i} {

        set name $::configXML(plateforme,${i},name)
        
        # Cette proc permet de mettre à jour les variable de cuve
        set ::cuve($name)    "NA"

        # Ces variables permettent de savoir si la Cuve a été pleine lors des trois dernières minutes
        set ::cuve($name,heureDernierPlein)    "NA"

    }
}

set cuveIndex 0
set valeurResponse ""
set cuveAsked ""
proc updateCuve {} {

    update

    set ::cuveAsked [lindex $::listePlateforme $::cuveIndex]
    set adresseIP   $::ip($::cuveAsked)
    
    #puts "Demande hauteur cuve $::cuveAsked"
    #::piServer::sendToServer 6006 "$::port(serverIrrigation) 0 getRepere ::sensor(1,value)" 192.168.0.55
    ::piServer::sendToServer $::port(serverAcqSensor) "$::port(serverIrrigation) 0 getRepere ::sensor(1,value)" $adresseIP

    incr ::cuveIndex
    if {[lindex $::listePlateforme $::cuveIndex] == ""} {
        set ::cuveIndex 0
    }
    
    after 5000 updateCuve
}

proc messageGestion {message host} {

    # Trame standard : [FROM] [INDEX] [commande] [argument]
    set serverForResponse   [::piTools::lindexRobust $message 0]
    set indexForResponse    [::piTools::lindexRobust $message 1]
    set commande            [::piTools::lindexRobust $message 2]

    if {$::cuveAsked != "" && [lindex $message 3] != ""} {
        #puts "Reception hauteur cuve $::cuveAsked , message $message "
        set ::cuve($::cuveAsked) [lindex $message 3]
        
        # On met à jour l'interface graphique
        #cuves.$::cuveAsked.cuve configure -value [expr [lindex $message 3] * 4]
        
        # Si on a jamais eu d'info et que la cuve n'est pas pleine
        if {[lindex $message 3] != "" &&
            [lindex $message 3] != "DEFCOM" &&
            [lindex $message 3] != "NA" &&
            [lindex $message 3] < 10} {
            set ::cuve($::cuveAsked,heureDernierPlein) 0
        }
        
        # Si la cuve est pleine on enregistre l'heure
        if {[lindex $message 3] != "" &&
            [lindex $message 3] != "DEFCOM" &&
            [lindex $message 3] != "NA" &&
            [lindex $message 3] >= 10} {
            set ::cuve($::cuveAsked,heureDernierPlein) [clock seconds]
        }
        
    } else {
        puts "Message pas compris $message"
    }

}

