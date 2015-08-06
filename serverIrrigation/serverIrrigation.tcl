# Pour lancer l'automatisation : tclsh /home/sdf/Bureau/program/progam.tcl
# Pour arreter : Ctrl + C

# Lecture des arguments : seul le path du fichier XML est donn� en argument
set confXML                 [lindex $argv 0]

set moduleLocalName serverIrrigation

# Load lib
set rootDir [file dirname [file dirname [info script]]]

# Load lib
lappend auto_path [file join $rootDir lib tcl]
package require piLog
package require piServer
package require piTools
package require piXML

source [file join $rootDir ${::moduleLocalName} src updateCuve.tcl]
source [file join $rootDir ${::moduleLocalName} src regulCuve.tcl]
source [file join $rootDir ${::moduleLocalName} src serveurMessage.tcl]

# Initialisation d'un compteur pour les commandes externes envoy�es
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
    ::piLog::log [clock milliseconds] "info" "$element : $configXML($element)"
}


proc stopIt {} {
    ::piLog::log [clock milliseconds] "info" "Start stopping ${::moduleLocalName}"
    set ::forever 0
    ::piLog::log [clock milliseconds] "info" "End stopping ${::moduleLocalName}"
    
    # Arr�t du server de log
    ::piLog::closeLog
    
    exit
}


proc startIrrigation {} {

    # Pour chaque plateforme on d�marre l'irrigation
    for {set i 0} {$i < $::configXML(nbPlateforme)} {incr i} {

        # On initialise les variables
        set ::irrigationActive($i) "false"
        set ::regulationActive($i) "false"

        # On d�marre avec un num�ro de zone al�atoire
        irrigationLoop $i [expr int(rand() * $::configXML(plateforme,$i,nbZone))]

    }

}

proc reload {} {

    ::piLog::log [clock milliseconds] "info" "Relaod"
    
    array set ::configXML [::piXML::convertXMLToArray $confXML]

    for {set i 0} {$i < $::configXML(nbPlateforme)} {incr i} {
        if {$::idAfter($i) == ""} {
    
            # On initialise les variables
            set ::irrigationActive($i) "false"
            set ::regulationActive($i) "false"

            irrigationLoop $i 0
        }
    }
}

proc irrigationLoop {indexPlateforme indexZone} {

    set plateformeNom       $::configXML(plateforme,${indexPlateforme},name)
    set plateformeActive    $::configXML(plateforme,${indexPlateforme},active)
    set plateformeNbZone    $::configXML(plateforme,${indexPlateforme},nbZone)
    set plateformeActiveLimiteDesamorcagePompe $::configXML(plateforme,${indexPlateforme},limitDesamorcagePompe)
    
    set zoneNom          $::configXML(plateforme,${indexPlateforme},zone,${indexZone},name)
    set zoneActive       $::configXML(plateforme,${indexPlateforme},zone,${indexZone},active)

    set IP      $::configXML(plateforme,${indexPlateforme},ip)
    set EVZone  $::configXML(plateforme,${indexPlateforme},zone,${indexZone},prise)
    set Pompe   $::configXML(plateforme,${indexPlateforme},pompePrise)
    
    
    # Si on est entre 6h et 22h -> utilisation des temps de jour
    set hour [string trimleft [clock format [clock seconds] -format %H] "0"]
    if {$hour == ""} {set hour 0}
    if {$hour >= 6 && $hour < 14} {
        set JourOuNuit matin
        set TempsOnEV   $::configXML(plateforme,${indexPlateforme},zone,${indexZone},tempsOn)
        set TempsOffEV  $::configXML(plateforme,${indexPlateforme},zone,${indexZone},tempsOff)
        set TempsPerco  $::configXML(plateforme,${indexPlateforme},tempsPerco)
    } elseif {$hour >= 14 && $hour <= 22} {
        set JourOuNuit apres_midi
        set TempsOnEV   $::configXML(plateforme,${indexPlateforme},zone,${indexZone},tempsOnApresMidi)
        set TempsOffEV  $::configXML(plateforme,${indexPlateforme},zone,${indexZone},tempsOffApresMidi)
        set TempsPerco  $::configXML(plateforme,${indexPlateforme},tempsPercoApresMidi)
    } else {
        set JourOuNuit nuit
        set TempsOnEV   $::configXML(plateforme,${indexPlateforme},zone,${indexZone},tempsOnNuit)
        set TempsOffEV  $::configXML(plateforme,${indexPlateforme},zone,${indexZone},tempsOffNuit)
        set TempsPerco  $::configXML(plateforme,${indexPlateforme},tempsPercoNuit)
    }

    
    # Si la plate-forme est d�sactiv�e on arr�te de v�rifier
    if {$plateformeActive == 0 || $plateformeActive == "false"} {
        ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : d�sactiv�e, on n'essaye pas de l'irriguer";update
        set ::idAfter ""
        return
    }

    # Si la zone est d�sactiv�e
    if {$zoneActive == 0 || $zoneActive == "false"} {
        ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : La zone est d�sactiv�e, on passe � la suivante";update
        incr indexZone
        if {$indexZone >= $plateformeNbZone} {
            set indexZone 0
        }
        set ::idAfter [after 100 [list after idle irrigationLoop $indexPlateforme $indexZone]]
        return 
    }
    
    # Si la cuve est vide
    if {$::cuve($indexPlateforme) == "NA" || 
        $::cuve($indexPlateforme) == "" || 
        $::cuve($indexPlateforme) == "DEFCOM" || 
        $::cuve($indexPlateforme) == "TIMEOUT" ||
        [string is integer $::cuve($indexPlateforme)] != 1 ||
        $::cuve($indexPlateforme) < 5} {
            if {$plateformeActiveLimiteDesamorcagePompe == "true"} {
                ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : La cuve n'est pas assez pleine pour irriguer";update
                incr indexZone
                if {$indexZone >= $plateformeNbZone} {
                    set indexZone 0
                }
                set ::idAfter [after 100 irrigationLoop [list after idle $indexPlateforme $indexZone]]
                return 
            } else {
                 ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : La cuve n'est pas assez pleine pour irriguer - Fonctionnalit� d�sactiv�e";update
            }
    }

    # Si le temps On est de 1 ou inf�rieur, on ne r�alise que le temps d'attente
    if {$TempsOnEV <= 1} {
        ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : Le temps On est trop petit";update
        incr indexZone
        if {$indexZone >= $plateformeNbZone} {
            set indexZone 0
        }
        ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : Attente $TempsOffEV secondes avant zone suivante";update
        set ::idAfter [after [expr 1000 * $TempsOffEV] [list after idle irrigationLoop $indexPlateforme $indexZone]]
        return 
    }
    
    # Si la zone est en r�gulation, on rettente dans 10 secondes
    # if {$::regulationActivePlateforme($indexPlateforme) == "true"} {
        # ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : La zone est actuellement en r�gulation, on attend 10 secondes";update

        # set ::idAfter [after 10000 [list after idle irrigationLoop $indexPlateforme $indexZone]]
        # return 
    # }    
    
    # ::piLog::log [clock milliseconds] "debug" $::irrigationActive(montmartre)
    set ::irrigationActive($indexPlateforme) true

    # On allume l'�lectrovanne 1 pour 2min30 secondes
    ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : ON EV pendant [expr $TempsOnEV + 1] s (temps d�finit pour $JourOuNuit)"; update
    ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $EVZone on [expr $TempsOnEV + 1]" $IP

    # On allume la pompe
    ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : ON pompe pendant $TempsOnEV s (temps d�finit pour $JourOuNuit)"; update
    ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $Pompe on $TempsOnEV" $IP

    # Dans X secondes, on indique que la zone n'est plus pilot�e
    after [expr $TempsOnEV * 1000] [list set ::irrigationActive($indexPlateforme) false]
    after [expr $TempsOnEV * 1000] [list ::piLog::log [expr [clock milliseconds] + $TempsOnEV * 1000] "info" "irrigation: plateforme $plateformeNom : zone $zoneNom : Fin Irrigation"]
    
    
    incr indexZone
    # Si on a termin� toute les zones, on laisse le temps de perco
    if {$indexZone >= $plateformeNbZone} {
        set indexZone 0
        
        ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : Attente $TempsOffEV secondes + Temps Perco ($TempsPerco) avant zone suivante ($indexZone) (temps d�finit pour $JourOuNuit)";update
        set ::idAfter [after [expr 1000 * ($TempsOffEV + $TempsPerco)] [list after idle irrigationLoop $indexPlateforme $indexZone]]
    } else {
        ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : Attente $TempsOffEV secondes avant zone suivante ($indexZone) (temps d�finit pour $JourOuNuit)";update
        set ::idAfter [after [expr 1000 * $TempsOffEV] [list after idle irrigationLoop $indexPlateforme $indexZone]]
    }
    

    
}

# *************  Update des cuves 
# Initialisation des variable 
initcuve

# On met en route le serveur de message
::piServer::start messageGestion $::piServer::portNumber(${::moduleLocalName})

# ON de la mise � jour des cuves
after 100 updateCuve

# *************  R�gulation
initRegulationVariable

regulCuve

# *************  Irrigation
startIrrigation

# *************  Auto remplissage
autoRemplissage


vwait forever

# Lancement 
# tclsh "D:\CBX\cultipiCore\serverIrrigation\serverIrrigation.tcl" "D:\CBX\cultipiCore\serverIrrigation\confExample\conf.xml" 
# tclsh /home/sdf/Bureau/cultipiCore/serverIrrigation/serverIrrigation.tcl "/home/sdf/Bureau/cultipiCore/serverIrrigation/confExample/conf.xml" 
# tclsh /opt/cultipi/serverIrrigation/serverIrrigation.tcl /etc/cultipi/01_defaultConf_RPi/serverIrrigation/conf.xml