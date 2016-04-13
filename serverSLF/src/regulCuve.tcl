
proc init_cuveLoop {idxZone} {

    # Les hauteurs de cuves sont 
    # Capteur bas : 5
    # Capteur bas + milieu : 15
    # Capteur bas + milieu + haut : 35
    set ::cuve(min) 10
    set ::cuve(max) 20
    set ::cuve(${idxZone},hauteurMini) $::cuve(min)
    
    # On d�sactive le pilotage des pompes la premi�re heure
    set heure  [expr [clock format [clock seconds] -format "%H"] + 0]
    set heure  [string trimleft $heure "0"]
    if {$heure == ""} {set heure 0}
    set ::cuve(${idxZone},engraisappliquee) $heure
    
    set ::etatLDV(cuveLoop) ""
    
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
    
    set ::etatLDV(cuveLoop) ""
    
    # On v�rifie que l'information de niveau de cuve est valide 
    set hauteurCuve $::sensor(${IP},${num_cap_niveau})
    
    if {[string is double $hauteurCuve]} {
        # On v�rifie toute les 10 secondes le niveau d'eau
        # Si il est inf�rieur au niveau bas on remplie
        if {$hauteurCuve < $::cuve(${idxZone},hauteurMini)} {
            ::piLog::log [clock milliseconds] "info" "cuve : ZONE $zoneNom : niveau trop bas (hauteur : $hauteurCuve / $::cuve(${idxZone},hauteurMini) ) "; update
            
            # On met en route le remplissage pour 30 s 
            ::piLog::log [clock milliseconds] "info" "cuve : ZONE $zoneNom : ON EV Remplissage pendant 31s"; update
            ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $priseremplissagecuve on 31" $IP
            ::piLog::log [clock milliseconds] "info" "cuve : ZONE $zoneNom : ON Supresseur pendant 30s"; update
            ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $Prisesurpresseur on 30" $IPsurpresseur
            
            # On indique que la hauteur mini doit �tre le capteur du dessus
            set ::cuve(${idxZone},hauteurMini) $::cuve(max)
            
        } else {
        
            ::piLog::log [clock milliseconds] "debug" "cuve : ZONE $zoneNom : niveau bon on remet le seuil a $::cuve(min) (hauteur : $hauteurCuve  / $::cuve(${idxZone},hauteurMini) ) "; update
        
            # On r�initialise la hauteur mini 
            set ::cuve(${idxZone},hauteurMini) $::cuve(min)
        }
    } else {
        ::piLog::log [clock milliseconds] "info" "cuve : ZONE $zoneNom : la hauteur de cuve n'est pas connue (hauteur : $hauteurCuve )"; update
    }

    #---------------  Aplication des engrais
    # Au d�but de chaque heure, on charge en engrais
    set heure  [expr [clock format [clock seconds] -format "%H"] + 0]
    set heure  [string trimleft $heure "0"]
    if {$heure == ""} {set heure 0}

    if {$heure != $::cuve(${idxZone},engraisappliquee)} {
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

        # On sauvegarde la derni�re heure 
        set ::cuve(${idxZone},engraisappliquee) $heure
    }

    # On lance l'iteration suivante 
    set ::etatLDV(cuveLoop) [after [expr 1000 * 10] [list after idle cuveLoop $idxZone]]
}
