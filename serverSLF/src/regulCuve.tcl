
proc init_cuveLoop {idxZone} {

    # Les hauteurs de cuves sont 
    # Capteur bas : 5
    # Capteur bas + milieu : 15
    # Capteur bas + milieu + haut : 35
    set ::cuve(${idxZone},hauteurMini) 15

}


proc cuveLoop {idxZone} {

    set zoneNom         $::configXML(zone,${idxZone},name)
    set engrais1Actif   $::configXML(zone,${idxZone},engrais,1,actif)
    set engrais2Actif   $::configXML(zone,${idxZone},engrais,2,actif)
    set engrais3Actif   $::configXML(zone,${idxZone},engrais,3,actif)
    set IP              $::configXML(zone,${idxZone},ip)
    set num_cap_niveau  $::configXML(zone,${idxZone},capteur,niveau)
    
    set IPsurpresseur       $::configXML(surpresseur,ip)
    set Prisesurpresseur    $::configXML(surpresseur,prise)
    
    
    set priseremplissagecuve $::configXML(zone,${idxZone},prise,remplissagecuve)
    
    
    # On vérifie que l'information de niveau de cuve est valide 
    set hauteurCuve $::sensor(${IP},${num_cap_niveau})
    if {[string is double $hauteurCuve]} {
        # On vérifie toute les 10 secondes le niveau d'eau
        # Si il est inférieur au niveau bas on remplie
        if {$hauteurCuve < $::cuve(${idxZone},hauteurMini)} {
            ::piLog::log [clock milliseconds] "info" "cuve : ZONE $zoneNom : niveau trop bas (hauteur : $hauteurCuve ) "; update
            
            # On met en route le remplissage pour 30 s 
            ::piLog::log [clock milliseconds] "info" "cuve :  ZONE $zoneNom : ON EV Remplissage pendant 31s"; update
            ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $priseremplissagecuve on 31" $IP
            ::piLog::log [clock milliseconds] "info" "cuve :  ZONE $zoneNom : ON Supresseur pendant 30s"; update
            ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $Prisesurpresseur on 30" $IPsurpresseur
            
            # On indique que la hauteur mini doit être le capteur du dessus
            set ::cuve(${idxZone},hauteurMini) 35
            
        } else {
            # On réinitialise la hauteur mini 
            set ::cuve(${idxZone},hauteurMini) 15
        
        }
    } else {
        ::piLog::log [clock milliseconds] "info" "cuve : ZONE $zoneNom : la hauteur de cuve n'est pas connue (hauteur : $hauteurCuve ) "; update
    }

    #---------------  Aplication des engrais
    # Au début de chaque heure, on charge en engrais
    set heure  [expr [clock format [clock seconds] -format "%H"] + 0]
    set heure  [string trimleft $heure "0"]
    if {$heure == ""} {set heure 0}
    set minute [expr [clock format [clock seconds] -format "%M"] + 0]
    set minute  [string trimleft $minute "0"]
    if {$minute == ""} {set minute 0}
    
    if {$heure != $::configXML(zone,${idxZone},engraisappliquee) && $minute < 10 } {
        # On applique les engrais
        for {set i 1} {$i < 4} {incr i} {
        
            set engraisActif   $::configXML(zone,${idxZone},engrais,$i,actif)
        
            if {$engraisActif == "true"} {
                set engraistmps   $::configXML(zone,${idxZone},engrais,${i},temps)
                set engraisprise  $::configXML(zone,${idxZone},engrais,${i},prise)
                
                ::piLog::log [clock milliseconds] "info" "engrais : ZONE $zoneNom : ON ENGRAIS ${i} pendant $engraistmps s "; update
                ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $engraisprise on $engraistmps" $IP 
            }
        }


        # On sauvegarde la dernière heure 
        set ::configXML(zone,${idxZone},engraisappliquee) $heure
    }
    

    # On lance l'iteration suivante 
    after [expr 1000 * 10] [list after idle cuveLoop $idxZone]
}
