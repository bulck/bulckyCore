# Pour lancer l'automatisation : tclsh /home/sdf/Bureau/program/progam.tcl
# Pour arreter : Ctrl + C

# Lecture des arguments : seul le path du fichier XML est donné en argument
set confXML                 [lindex $argv 0]

set moduleLocalName serverSLF

# Load lib
set rootDir [file dirname [file dirname [info script]]]

# Load lib
lappend auto_path [file join $rootDir lib tcl]
package require piLog
package require piServer
package require piTools
package require piXML

source [file join $rootDir ${::moduleLocalName} src updateSensor.tcl]
source [file join $rootDir ${::moduleLocalName} src regulCuve.tcl]
source [file join $rootDir ${::moduleLocalName} src serveurMessage.tcl]

# Initialisation d'un compteur pour les commandes externes envoyées
set TrameIndex 0
# On initialise la conf XML
array set configXML {
    verbose     debug
}

if {[file exists $confXML] != 1} {
    # Le fichier de conf n'exists pas, on meurt tranquillement
    puts "[clock milliseconds] info ${::moduleLocalName} Conf file ($confXML) does not exists. Bye Bye !"
    exit
}

# Chargement de la conf XML
set RC [catch {
    array set configXML [::piXML::convertXMLToArray $confXML]
} msg]
if {$RC != 0} {
    puts "[clock milliseconds] info ${::moduleLocalName} [clock milliseconds] error $msg"
}

# On initialise la connexion avec le server de log
::piLog::openLog $::piServer::portNumber(serverLog) ${::moduleLocalName} $configXML(verbose)

::piLog::log [clock milliseconds] "info" "starting ${::moduleLocalName} - PID : [pid]"
::piLog::log [clock milliseconds] "info" "port ${::moduleLocalName} : $::piServer::portNumber(${::moduleLocalName})"
::piLog::log [clock milliseconds] "info" "confXML : $confXML"
# On affiche les infos dans le fichier de debug
foreach element [lsort [array names configXML]] {
    ::piLog::log [clock milliseconds] "debug" "$element : $configXML($element)"
}

# Cette procédure permet d'afficher dans le fichier de log les erreurs qui sont apparues
proc bgerror {message} {
    ::piLog::log [clock milliseconds] error_critic "bgerror in [info script] $::argv -$message- "
    foreach elem [split $::errorInfo "\n"] {
        ::piLog::log [clock milliseconds] error_critic " * $elem"
    }
}

proc stopIt {} {
    ::piLog::log [clock milliseconds] "info" "Start stopping ${::moduleLocalName}"
    set ::forever 0
    ::piLog::log [clock milliseconds] "info" "End stopping ${::moduleLocalName}"
    
    # Arrêt du server de log
    ::piLog::closeLog
    
    exit
}



proc reload {} {

    ::piLog::log [clock milliseconds] "info" "Relaod"
    
    array set ::configXML [::piXML::convertXMLToArray $confXML]

}

set ::etatLDV(irrigationLoop) ""
proc irrigationLoop {idxZone indexPlateforme indexLigneIrrigation} {

    # On récupère les paramètres utiles
    set plateformeNom       $::configXML(zone,$idxZone,plateforme,${indexPlateforme},name)
    set IP                  $::configXML(zone,$idxZone,plateforme,${indexPlateforme},ip)
    set plateformeNbLigne   $::configXML(zone,$idxZone,plateforme,${indexPlateforme},nbligne)
    set tempscycle          $::configXML(zone,$idxZone,plateforme,${indexPlateforme},tempscycle)
    set Pompe               $::configXML(zone,$idxZone,plateforme,${indexPlateforme},pompe,prise)
    set EVEau               $::configXML(zone,$idxZone,plateforme,${indexPlateforme},eauclaire,prise)
    
    set IPsurpresseur       $::configXML(surpresseur,ip)
    set Prisesurpresseur    $::configXML(surpresseur,prise)
    set surpresseurActif    [::piTools::readArrayElem [array get ::configXML] "surpresseur,actif" "false"]
    
    set nettoyageactif      $::configXML(nettoyageactif)
    
    set num_cap_niveau      $::configXML(zone,${idxZone},capteur,niveau)
    set hauteurCuve         $::sensor(${IP},${num_cap_niveau})
    set cuveVide            0
    if {[string is double $hauteurCuve] == 0} {
        if {$hauteurCuve == 0} {
            set cuveVide    1
        }
    } else {
        set cuveVide        1
    }
    
    set ::etatLDV(irrigationLoop) ""
    
    # On vérifie que le numéro de ligne est correcte
    if {$indexLigneIrrigation >= $plateformeNbLigne} {
        set indexLigneIrrigation 0
    }
    
    set EVLigne             $::configXML(zone,$idxZone,plateforme,${indexPlateforme},ligne,${indexLigneIrrigation},prise)
    set active              $::configXML(zone,$idxZone,plateforme,${indexPlateforme},ligne,${indexLigneIrrigation},active)
    
    # Utilisé pour faire le nettoyage des gouteurs
    set nbCycle             $::configXML(zone,$idxZone,plateforme,${indexPlateforme},ligne,${indexLigneIrrigation},nbCycle)
    if {$nbCycle >= $::configXML(nettoyage)} {
        set ::configXML(zone,$idxZone,plateforme,${indexPlateforme},ligne,${indexLigneIrrigation},nbCycle) 0
    } else {
        incr  ::configXML(zone,$idxZone,plateforme,${indexPlateforme},ligne,${indexLigneIrrigation},nbCycle)
    }
    
    # Si on est entre 6h et 22h -> utilisation des temps de jour
    set hour [string trimleft [clock format [clock seconds] -format %H] "0"]
    if {$hour == ""} {set hour 0}
    if {$hour >= 6 && $hour < 14} {
        set JourOuNuit matin
        set TempsOnEV   $::configXML(zone,$idxZone,plateforme,${indexPlateforme},ligne,${indexLigneIrrigation},tempsOn,matin)
    } elseif {$hour >= 14 && $hour <= 22} {
        set JourOuNuit apres_midi
        set TempsOnEV   $::configXML(zone,$idxZone,plateforme,${indexPlateforme},ligne,${indexLigneIrrigation},tempsOn,apresmidi)
    } else {
        set JourOuNuit nuit
        set TempsOnEV   $::configXML(zone,$idxZone,plateforme,${indexPlateforme},ligne,${indexLigneIrrigation},tempsOn,nuit)
    }
    
    # 4 cas :
    # - la plateforme est désactivée avec le bouton ou avec l'interface web
    # - le temps est nul
    # - La cuve est vide
    # - Nettoyage (Et que le nettoyage est activé)
    # - Irrigation
    # On allume l'électrovanne 1 pour 2min30 secondes
    if {$active == "false"} {
        ::piLog::log [clock milliseconds] "info" "irrigation : $plateformeNom : Ligne $indexLigneIrrigation : désactivée web"; update
    } elseif {$TempsOnEV < 1} {
        # Le temps est nul
        ::piLog::log [clock milliseconds] "info" "irrigation : $plateformeNom : ligne $indexLigneIrrigation : Temps trop petit"; update
    } elseif {$cuveVide == 1} {
        # La cuve est vide
        ::piLog::log [clock milliseconds] "info" "irrigation : $plateformeNom : ligne $indexLigneIrrigation : Cuve pas assez remplie ou donnée non disponible (hauteurCuve $hauteurCuve) "; update
    } elseif {$nbCycle == 0 && $nettoyageactif == "true"} {
        # On active le nettoyage :
        # Mise en route de la ligne d'électrovanne + 1s
        # Mise en route de l'arrivée d'eau
        # Mise en route du surpresseur
        
        ::piLog::log [clock milliseconds] "info" "nettoyage : $plateformeNom : ligne $indexLigneIrrigation : ON EV pendant [expr $TempsOnEV + 1] s ($JourOuNuit)"; update
        ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $EVLigne on [expr $TempsOnEV + 1]" $IP 
        
        ::piLog::log [clock milliseconds] "info" "nettoyage : $plateformeNom : ligne $indexLigneIrrigation : ON EV EAU pendant $TempsOnEV s ($JourOuNuit)"; update
        ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $EVEau on $TempsOnEV" $IP 
        
        # On vérifie qu'il faille piloter le surpresseur
        if {$surpresseurActif != "false"} {
            ::piLog::log [clock milliseconds] "info" "nettoyage : $plateformeNom : ligne $indexLigneIrrigation : ON Supresseur pendant $TempsOnEV s ($JourOuNuit)"; update
            ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $Prisesurpresseur on $TempsOnEV" $IPsurpresseur
        } else {
            ::piLog::log [clock milliseconds] "debug" "nettoyage : $plateformeNom : ligne $indexLigneIrrigation : Surpresseur desactive"; update
        }

        
        # Dans X secondes, on indique que la Ligne n'est plus pilotée
        after [expr $tempscycle * 1000] [list ::piLog::log [expr [clock milliseconds] + $tempscycle * 1000] "info" "nettoyage : $plateformeNom : ligne $indexLigneIrrigation : Fin Nettoyage"]
        
    } else {
        ::piLog::log [clock milliseconds] "info" "irrigation : $plateformeNom : ligne $indexLigneIrrigation : ON EV pendant [expr $TempsOnEV + 1] s ($JourOuNuit)"; update
        ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $EVLigne on [expr $TempsOnEV + 1]" $IP

        # On allume la pompe
        ::piLog::log [clock milliseconds] "info" "irrigation : $plateformeNom : ligne $indexLigneIrrigation : ON pompe pendant $TempsOnEV s ($JourOuNuit)"; update
        ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $Pompe on $TempsOnEV" $IP

        # Dans X secondes, on indique que la Ligne n'est plus pilotée
        after [expr $tempscycle * 1000] [list ::piLog::log [expr [clock milliseconds] + $tempscycle * 1000] "info" "irrigation : $plateformeNom : ligne $indexLigneIrrigation : Fin Irrigation"]
    }

    incr indexLigneIrrigation

    # On lance l'iteration suivante 
    set ::etatLDV(irrigationLoop) [after [expr 1000 * $tempscycle] [list after idle irrigationLoop $idxZone $indexPlateforme $indexLigneIrrigation]]
}


# On met en route le serveur de message
::piServer::start messageGestion $::piServer::portNumber(${::moduleLocalName})


# Pour chaque zone, 
# Remplissage automatique & chargement d'engrais 
for {set i 0} {$i < $::configXML(nbzone)} {incr i} {

    # On lance la mise à jour des capteurs
    init_updateSensor $i
    updateSensor $i
    
    # on démarre la régulation de la cuve :
    init_cuveLoop $i
    cuveLoop $i
    
    # On active l'irrigation 
    for {set j 0} {$j < $::configXML(zone,$i,nbplateforme)} {incr j} {
        irrigationLoop $i $j [expr int(rand() * $::configXML(zone,$i,plateforme,$j,nbligne))]
    }

}

proc ligneDeVie {} {
    ::piLog::log [clock milliseconds] "info" "Ligne de vie : cuveLoop : $::etatLDV(cuveLoop) - updateSensor : $::etatLDV(updateSensor) - irrigationLoop $::etatLDV(irrigationLoop) - purgeCuve $::etatLDV(purgeCuve)"; update
    after [expr 1000 * 10] ligneDeVie
}
# On lance la ligne de vie
ligneDeVie

vwait forever

# Lancement 
# tclsh "D:\CBX\06_bulckyCore\serverSLF\serverSLF.tcl" "D:\CBX\06_bulckyCore\_conf\00_defaultConf_Win\serverSLF\conf.xml" 
# tclsh "D:\CBX\06_bulckyCore\serverSLF\serverSLF.tcl" "D:\CBX\06_bulckyCore\serverSLF\confExample\conf.xml" 
# tclsh /home/sdf/Bureau/cultipiCore/serverSLF/serverSLF.tcl "/home/sdf/Bureau/cultipiCore/serverSLF/confExample/conf.xml" 
# tclsh /opt/cultipi/serverSLF/serverSLF.tcl /etc/cultipi/01_defaultConf_RPi/serverSLF/conf.xml