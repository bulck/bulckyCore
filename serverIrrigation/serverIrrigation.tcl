# Pour lancer l'automatisation : tclsh /home/sdf/Bureau/program/progam.tcl
# Pour arreter : Ctrl + C

# Lecture des arguments : seul le path du fichier XML est donné en argument
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
    ::piLog::log [clock milliseconds] "info" "$element : $configXML($element)"
}


proc stopIt {} {
    ::piLog::log [clock milliseconds] "info" "Start stopping ${::moduleLocalName}"
    set ::forever 0
    ::piLog::log [clock milliseconds] "info" "End stopping ${::moduleLocalName}"
    
    # Arrêt du server de log
    ::piLog::closeLog
    
    exit
}


proc startIrrigation {} {

    # Pour chaque plateforme on démarre l'irrigation
    for {set i 0} {$i < $::configXML(nbPlateforme)} {incr i} {
    
        # On initialise les variables
        set ::irrigationActive($i) "false"
        set ::regulationActive($i) "false"

        irrigationLoop $i 0
    
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
    
    set TempsOnEV   $::configXML(plateforme,${indexPlateforme},zone,${indexZone},tempsOn)
    set TempsOffEV  $::configXML(plateforme,${indexPlateforme},zone,${indexZone},tempsOff)
    set TempsPerco  $::configXML(plateforme,${indexPlateforme},tempsPerco)
    
    # Si la plate-forme est désactivée on arrête de vérifier
    if {$plateformeActive == 0 || $plateformeActive == "false"} {
        ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : désactivée, on n'essaye pas de l'irriguer"
        set ::idAfter ""
        return
    }

    # Si la zone est désactivée
    if {$zoneActive == 0 || $zoneActive == "false"} {
        ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : La zone est désactivée, on passe à la suivante"
        incr indexZone
        if {$indexZone >= $plateformeNbZone} {
            set indexZone 0
        }
        set ::idAfter [after 100 irrigationLoop $indexPlateforme $indexZone]
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
                ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : La cuve n'est pas assez pleine pour irriguer"
                incr indexZone
                if {$indexZone >= $plateformeNbZone} {
                    set indexZone 0
                }
                set ::idAfter [after 100 irrigationLoop $indexPlateforme $indexZone]
                return 
            } else {
                 ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : La cuve n'est pas assez pleine pour irriguer - Fonctionnalité désactivée"
            }
    }

    # Si le temps On est de 1 ou inférieur, on ne réalise que le temps d'attente
    if {$TempsOnEV <= 1} {
        ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : Le temps On est trop petit"
        incr indexZone
        if {$indexZone >= $plateformeNbZone} {
            set indexZone 0
        }
        ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : Attente $TempsOffEV secondes avant zone suivante";update
        set ::idAfter [after [expr 1000 * $TempsOffEV] irrigationLoop $indexPlateforme $indexZone]
        return 
    }
    
    # Si la zone est en régulation, on rettente dans 10 secondes
    if {$::regulationActive($indexPlateforme) == "true"} {
        ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : La zone est actuellement en régulation, on attend 10 secondes"

        set ::idAfter [after 10000 irrigationLoop $indexPlateforme $indexZone]
        return 
    }    
    
    # ::piLog::log [clock milliseconds] "debug" $::irrigationActive(montmartre)
    set ::irrigationActive($indexPlateforme) true

    # On allume l'électrovanne 1 pour 2min30 secondes
    ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : Mise en route EV pendant [expr $TempsOnEV + 1] s"; update
    ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $EVZone on [expr $TempsOnEV + 1]" $IP

    # On allume la pompe
    ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : Mise en route pompe pendant $TempsOnEV s"; update
    ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $Pompe on $TempsOnEV" $IP

    # Dans X secondes, on indique que la zone n'est plus pilotée
    after [expr $TempsOnEV * 1000] "set ::irrigationActive($indexPlateforme) false"

    incr indexZone
    # Si on a terminé toute les zones, on laisse le temps de perco
    if {$indexZone >= $plateformeNbZone} {
        set indexZone 0
        
        ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : Attente $TempsOffEV secondes + Temps Perco ($TempsPerco) avant zone suivante ($indexZone)";update
        set ::idAfter [after [expr 1000 * ($TempsOffEV + $TempsPerco)] irrigationLoop $indexPlateforme $indexZone]
    } else {
        ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : Attente $TempsOffEV secondes avant zone suivante ($indexZone)";update
        set ::idAfter [after [expr 1000 * $TempsOffEV] irrigationLoop $indexPlateforme $indexZone]
    }
    

    
}

# *************  Update des cuves 
# Initialisation des variable 
initcuve

# On met en route le serveur de message
::piServer::start messageGestion $::piServer::portNumber(${::moduleLocalName})

# Mise en route de la mise à jour des cuves
after 100 updateCuve

# *************  Régulation
initRegulationVariable

regulCuve

# *************  Irrigation
startIrrigation


vwait forever

# Lancement 
# tclsh "D:\CBX\cultipiCore\serverIrrigation\serverIrrigation.tcl" 6005 "D:\CBX\cultipiCore\serverIrrigation\confExample\conf.xml" 6001 
# tclsh /home/sdf/Bureau/cultipiCore/serverIrrigation/serverIrrigation.tcl 6005 "/home/sdf/Bureau/cultipiCore/serverIrrigation/confExample/conf.xml" 6001 