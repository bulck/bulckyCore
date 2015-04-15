# Pour lancer l'automatisation : tclsh /home/sdf/Bureau/program/progam.tcl
# Pour arreter : Ctrl + C

# Read argv
set port(serverIrrigation)  [lindex $argv 0]
set confXML                 [lindex $argv 1]
set port(serverLogs)        [lindex $argv 2]
set port(serverCultiPi)     [lindex $argv 3]
set port(serverCultipi) 6000
set port(serverAcqSensor) 6006
set port(serverPlugUpdate) 6004
set port(serverHisto) 6009

# Load lib
set rootDir [file dirname [file dirname [info script]]]

# Load lib
lappend auto_path [file join $rootDir lib tcl]
package require piLog
package require piServer
package require piTools
package require piXML

source [file join $rootDir serverIrrigation src updateCuve.tcl]
source [file join $rootDir serverIrrigation src regulCuve.tcl]
source [file join $rootDir serverIrrigation src serveurMessage.tcl]

# Initialisation d'un compteur pour les commandes externes envoy�es
set TrameIndex 0
# On initialise la conf XML
array set configXML {
    verbose     debug
}

if {[file exists $confXML] != 1} {
    # Le fichier de conf n'exists pas, on meurt tranquillement
    puts "[clock milliseconds] info serverIrrigation Conf file ($confXML) does not exists. Bye Bye !"
    exit
}

# Chargement de la conf XML
set RC [catch {
    array set configXML [::piXML::convertXMLToArray $confXML]
} msg]
if {$RC != 0} {
    puts "[clock milliseconds] info serverIrrigation [clock milliseconds] error $msg"
}

# On initialise la connexion avec le server de log
::piLog::openLog $port(serverLogs) "serverIrrigation" $configXML(verbose)

::piLog::log [clock milliseconds] "info" "starting serverIrrigation - PID : [pid]"
::piLog::log [clock milliseconds] "info" "port serverIrrigation : $port(serverIrrigation)"
::piLog::log [clock milliseconds] "info" "confXML : $confXML"
::piLog::log [clock milliseconds] "info" "port serverLogs : $port(serverLogs)"
::piLog::log [clock milliseconds] "info" "port serverCultiPi : $port(serverCultiPi)"
# On affiche les infos dans le fichier de debug
foreach element [lsort [array names configXML]] {
    #::piLog::log [clock milliseconds] "info" "$element : $configXML($element)"
    ::piLog::log [clock milliseconds] "info" "$element : $configXML($element)"
}


proc stopIt {} {
    ::piLog::log [clock milliseconds] "info" "Start stopping serverIrrigation"
    set ::forever 0
    ::piLog::log [clock milliseconds] "info" "End stopping serverIrrigation"
    
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
    
    # Si la plate-forme est d�sactiv�e on arr�te de v�rifier
    if {$plateformeActive == 0 || $plateformeActive == "false"} {
        ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : d�sactiv�e, on n'essaye pas de l'irriguer"
        set ::idAfter ""
        return
    }

    # Si la zone est d�sactiv�e
    if {$zoneActive == 0 || $zoneActive == "false"} {
        ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : La zone est d�sactiv�e, on passe � la suivante"
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
                 ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : La cuve n'est pas assez pleine pour irriguer - Fonctionnalit� d�sactiv�e"
            }
    }
    
    set TempsOnEV   $::configXML(plateforme,${indexPlateforme},zone,${indexZone},tempsOn)
    set TempsOffEV  $::configXML(plateforme,${indexPlateforme},zone,${indexZone},tempsOff)
    
    # Si le temps On est de 1 ou inf�rieur, on ne r�alise que le temps d'attente
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
    
    # Si la zone est en r�gulation, on rettente dans 10 secondes
    if {$::regulationActive($indexPlateforme) == "true"} {
        ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : La zone est actuellement en r�gulation, on attend 10 secondes"

        set ::idAfter [after 10000 irrigationLoop $indexPlateforme $indexZone]
        return 
    }    
    
    # ::piLog::log [clock milliseconds] "debug" $::irrigationActive(montmartre)
    set ::irrigationActive($indexPlateforme) true

    # On allume l'�lectrovanne 1 pour 2min30 secondes
    ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : Mise en route EV pendant [expr $TempsOnEV + 1] s"; update
    ::piServer::sendToServer $::port(serverPlugUpdate) "$::port(serverIrrigation) 0 setRepere $EVZone on [expr $TempsOnEV + 1]" $IP)

    # On allume la pompe
    ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : Mise en route pompe pendant $TempsOnEV s"; update
    ::piServer::sendToServer $::port(serverPlugUpdate) "$::port(serverIrrigation) 0 setRepere $Pompe on $TempsOnEV" $IP)

    # Dans X secondes, on indique que la zone n'est plus pilot�e
    after [expr $TempsOnEV * 1000] "set ::irrigationActive($indexPlateforme) false"

    incr indexZone
    if {$indexZone >= $plateformeNbZone} {
        set indexZone 0
    }
    
    ::piLog::log [clock milliseconds] "info" "irrigation : plate-forme $plateformeNom : zone $zoneNom : Attente $TempsOffEV secondes avant zone suivante ($indexZone)";update
    set ::idAfter [after [expr 1000 * $TempsOffEV] irrigationLoop $indexPlateforme $indexZone]
    
}

# *************  Update des cuves 
# Initialisation des variable 
initcuve

# On met en route le serveur de message
::piServer::start messageGestion $::port(serverIrrigation)

# Mise en route de la mise � jour des cuves
updateCuve

# *************  R�gulation
initRegulationVariable

regulCuve

# *************  Irrigation
startIrrigation


vwait forever

# Lancement 
# tclsh "D:\CBX\cultipiCore\serverIrrigation\serverIrrigation.tcl" 6005 "D:\CBX\cultipiCore\serverIrrigation\confExample\conf.xml" 6001 