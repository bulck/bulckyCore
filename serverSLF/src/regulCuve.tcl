
proc init_cuveLoop {idxZone} {

    # Les hauteurs de cuves sont 
    # Capteur bas : 5
    # Capteur bas + milieu : 15
    # Capteur bas + milieu + haut : 35
    set ::cuve(purge) 0
    set ::cuve(min) 10
    set ::cuve(max) 20
    set ::cuve(${idxZone},hauteurMini) $::cuve(min)
    
    # On désactive le pilotage des pompes la première heure
    set heure  [expr [clock format [clock seconds] -format "%H"] + 0]
    set heure  [string trimleft $heure "0"]
    if {$heure == ""} {set heure 0}
    set ::cuve(${idxZone},engraisappliquee) $heure
    
    set ::etatLDV(cuveLoop) ""
    set ::etatLDV(purgeCuve) ""
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
    set surpresseurActif    [::piTools::readArrayElem [array get ::configXML] "surpresseur,actif" "false"]
    
    set priseremplissagecuve $::configXML(zone,${idxZone},prise,remplissagecuve)
    
    set ::etatLDV(cuveLoop) ""
    
    # On vérifie que l'information de niveau de cuve est valide 
    set hauteurCuve $::sensor(${IP},${num_cap_niveau})
    
    if {[string is double $hauteurCuve]} {
        # On vérifie toute les 10 secondes le niveau d'eau
        # Si il est inférieur au niveau bas on remplie
        if {$hauteurCuve < $::cuve(${idxZone},hauteurMini)} {
            ::piLog::log [clock milliseconds] "info" "cuve : $zoneNom : niveau trop bas (hauteur : $hauteurCuve / $::cuve(${idxZone},hauteurMini) ) "; update
            
            # On met en route le remplissage pour 30 s 
            ::piLog::log [clock milliseconds] "info" "cuve : $zoneNom : ON EV Remplissage pendant 31s"; update
            ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $priseremplissagecuve on 31" $IP
            
            # On vérifie qu'il faille piloter le surpresseur
            if {$surpresseurActif != "false"} {
                ::piLog::log [clock milliseconds] "info" "cuve : $zoneNom : ON Supresseur pendant 30s"; update
                ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $Prisesurpresseur on 30" $IPsurpresseur
            } else {
                ::piLog::log [clock milliseconds] "debug" "cuve : $zoneNom : Surpresseur desactive"; update
            }

            
            # On indique que la hauteur mini doit être le capteur du dessus
            set ::cuve(${idxZone},hauteurMini) $::cuve(max)
            
        } else {
        
            ::piLog::log [clock milliseconds] "debug" "cuve : $zoneNom : niveau bon on remet le seuil a $::cuve(min) (hauteur : $hauteurCuve  / $::cuve(${idxZone},hauteurMini) ) "; update
        
            # On réinitialise la hauteur mini 
            set ::cuve(${idxZone},hauteurMini) $::cuve(min)
        }
    } else {
        ::piLog::log [clock milliseconds] "info" "cuve : $zoneNom : la hauteur de cuve n'est pas connue (hauteur : $hauteurCuve )"; update
    }

    #---------------  Aplication des engrais
    # Au début de chaque heure, on charge en engrais
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
                
                ::piLog::log [clock milliseconds] "info" "engrais : $zoneNom : ON ENGRAIS ${i} pendant $engraistmps s "; update
                ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $engraisprise on $engraistmps" $IP 
            }
        }

        # On sauvegarde la dernière heure 
        set ::cuve(${idxZone},engraisappliquee) $heure
    }

    # On lance l'iteration suivante 
    set ::etatLDV(cuveLoop) [after [expr 1000 * 30] [list after idle cuveLoop $idxZone]]
}

proc purgeCuve {idxZone} {

    set ::etatLDV(purgeCuve) ""
    set zoneNom         $::configXML(zone,${idxZone},name)
    
    # On cherche la prise pour purger 
    set prisePurge  [::piTools::readArrayElem [array get ::configXML] "zone,${idxZone},prise,purge" "false"]
    if {$prisePurge == "false"} {
        ::piLog::log [clock milliseconds] "error" "purgeCuve : $zoneNom : La prise pour purger n'est pas définie "; update
        return
    }
    
    set IP              $::configXML(zone,${idxZone},ip)
    set num_cap_niveau  $::configXML(zone,${idxZone},capteur,niveau)
    
    # On vérifie que l'information de niveau de cuve est valide 
    set hauteurCuve $::sensor(${IP},${num_cap_niveau})
    
    if {[string is double $hauteurCuve]} {
        if {$hauteurCuve != $::cuve(purge)} {
            # on active la prise de purge 
            ::piLog::log [clock milliseconds] "info" "purgeCuve : $zoneNom : ON EV Purge pendant 30s"; update
            ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $prisePurge on 30" $IP
        } else {
            ::piLog::log [clock milliseconds] "info" "purgeCuve : $zoneNom : la cuve est vide"; update
            return
        }
    } else {
        ::piLog::log [clock milliseconds] "info" "purgeCuve : $zoneNom : la hauteur de cuve n'est pas connue (hauteur : $hauteurCuve )"; update
    }
    
    # On lance l'iteration suivante 
    set ::etatLDV(purgeCuve) [after [expr 1000 * 10] [list after idle purgeCuve $idxZone]]
}
