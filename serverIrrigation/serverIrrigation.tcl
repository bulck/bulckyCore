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

# Initialisation d'un compteur pour les commandes externes envoyées
set TrameIndex 0
# On initialise la conf XML
array set configXML {
    verbose     debug
}

# Chargement de la conf XML
set RC [catch {
    array set configXML [::piXML::convertXMLToArray $confXML]
} msg]
if {$RC != 0} {
    ::piLog::log [clock milliseconds] "info" "serverIrrigation [clock milliseconds] error $msg"
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

# On crée la liste des plateformes
set listePlateforme ""
for {set i 0} {$i < $configXML(nbPlateforme)} {incr i} {

    set name $configXML(plateforme,${i},name)

    lappend listePlateforme $name
    
    # On ajoute l'adresse IP
    set ip($name) $configXML(plateforme,${i},ip)
    
    # On crée la liste des prises
    set prise(${name},pompe)   $configXML(plateforme,${i},pompe,prise)
    for {set j 1} {$j <= $configXML(plateforme,${i},nbZone)} {incr j} {
        # Liste des prises
        set prise(${name},ev,$j)  $configXML(plateforme,${i},zone,${j},prise)
        
        # Définition des temps 
        set TempsOn(${name},ev,${j})    $configXML(TempsOn,${name},ev,${j})
        set TempsOff(${name},ev,${j})   $configXML(TempsOff,${name},ev,${j})
        set Activ(${name},ev,${j})      $configXML(Activ,${name},ev,${j})
    }
    set prise(${name},ev,[expr $j + 1]) "NA"
    
    # On ajoute dans le tableau l'information de est-ce que la zone est pilotable
    set Activ(${name})      $configXML(Activ,${name})
    # Le temps de perco 
    set TempsPerco(${name})      $configXML(TempsPerco,${name})
    
    # On ajoute la plateforme aux zones pilotable par le local technique
    set prise(localtechnique,ev,$name) $configXML(localtechnique,plateforme,${i},prise)
    
}

# On ajoute les infos du local technique
set prise(localtechnique,pompe)   $configXML(localtechnique,pompe,prise)
for {set i 0} {$i < $configXML(localtechnique,engrais,nombre)} {incr i} {
    set prise(localtechnique,ev,$configXML(localtechnique,engrais,${i},nom)) $configXML(localtechnique,engrais,${i},prise)
}

set irrigationActive ""


set status(irrigation) "Arretee"
set status(regulation) "Arretee"


set ::idAfter ""
set ::stopNow 0
proc start {} {
    if {$::idAfter == ""} {
        set ::stopNow 0
        set ::irrigationActive ""
        irrigationLoop
        set ::status(irrigation) "En route"
    } 
}

proc stop {} {
    if {$::idAfter == ""} {
    } else {
    
        set ::status(irrigation) "En cours d arrêt"
        
        set ::stopNow 1
        set ::irrigationActive ""
        after cancel $::idAfter
        
        # On éteint toutes les électrovannes
        foreach elem $::listeEVOuverte {
            ::piLog::log [clock milliseconds] "info" "Demande arrêt : IP : [lindex $elem 1] - Prise [lindex $elem 0]" 
            ::piServer::sendToServer $::port(serverPlugUpdate) "$::port(serverIrrigation) 0 setRepere [lindex $elem 0] off 10" [lindex $elem 1]
        }
        set ::listeEVOuverte ""

        set ::idAfter ""
        
        set irrigationActive ""
        
        set ::status(irrigation) "Arretee"
    }
}


set ::irrigationZoneIndex 1
set ::irrigationPlateformeIndex 0
set ::listeEVOuverte ""
set ::previousActivZone ""
proc irrigationLoop {} {

    set plateforme [lindex $::listePlateforme $::irrigationPlateformeIndex]
    
    
    # Si la plate-forme n'existe pas on recommence
    if {$plateforme == ""} {
        ::piLog::log [clock milliseconds] "info" "irrigation : On recommence pour toutes les plate-formes"
        set ::irrigationPlateformeIndex 0
        set ::irrigationZoneIndex 1
        set ::idAfter [after 100 irrigationLoop]
        return
    }
    
    # Si la plate-forme est désactivée, on passe à la suivante
    if {$::Activ($plateforme) == 0} {
        ::piLog::log [clock milliseconds] "info" "irrigation : la plate-forme $plateforme est désactivée, on passe à la suivante"
        incr ::irrigationPlateformeIndex
        set ::idAfter [after 100 irrigationLoop]
        return
    }

    # Si on a fini les zones de la plate-forme
    if {$::prise(${plateforme},ev,$::irrigationZoneIndex) == "NA"} {
        ::piLog::log [clock milliseconds] "info" "irrigation : Fin de toute les zones, on passe à la plate-forme suivante"
        set ::irrigationZoneIndex 1
        incr ::irrigationPlateformeIndex
        set ::idAfter [after 100 irrigationLoop]
        return 
    }
    
    # Si la zone est désactivée
    if {$::Activ(${plateforme},ev,$::irrigationZoneIndex) == 0} {
        ::piLog::log [clock milliseconds] "info" "irrigation : La zone est désactivée, on passe à la suivante"
        incr ::irrigationZoneIndex
        set ::idAfter [after 100 irrigationLoop]
        return 
    }
    
    # Si la cuve est vide
    if {$::cuve($plateforme) == "NA" || 
        $::cuve($plateforme) == "" || 
        $::cuve($plateforme) == "DEFCOM" || 
        $::cuve($plateforme) == "TIMEOUT" ||
        [string is integer $::cuve($plateforme)] != 1 ||
        $::cuve($plateforme) < 5} {
        ::piLog::log [clock milliseconds] "info" "irrigation : La cuve n'est pas assez pleine pour irriguer - Fonctionnalité désactivée"
        #incr ::irrigationZoneIndex
        #set ::idAfter [after 30000 irrigationLoop]
        #return
    }
    
    set ::listeEVOuverte ""
    set TempsOnEV $::TempsOn(${plateforme},ev,$::irrigationZoneIndex)
    set TempsOffEV $::TempsOff(${plateforme},ev,$::irrigationZoneIndex)
    
    # Si le temps On est de 1 ou inférieur, on ne réalise que le temps d'attente
    if {$TempsOnEV <= 1} {
        ::piLog::log [clock milliseconds] "info" "irrigation : Le temps On est trop petit"

        incr ::irrigationZoneIndex 

        ::piLog::log [clock milliseconds] "info" "irrigation : Attente $TempsOffEV secondes avant zone suivante";update
        set ::idAfter [after [expr 1000 * $TempsOffEV] irrigationLoop]
        return 
    }
    
    # Si la zone est en régulation, on rettente dans 10 secondes
    if {$::regulationActivePlateforme == ${plateforme}} {
        ::piLog::log [clock milliseconds] "info" "irrigation : La zone est actuellement en régulation, on attend 10 secondes"

        set ::idAfter [after 10000 irrigationLoop]
        return 
    }    
    
    # ::piLog::log [clock milliseconds] "debug" $::irrigationActive(montmartre)
    set ::irrigationActive ${plateforme}
    

    # On allume l'électrovanne 1 pour 2min30 secondes
    ::piLog::log [clock milliseconds] "info" "irrigation : Mise en route ${plateforme},ev,$::irrigationZoneIndex pendant [expr $TempsOnEV + 1] s"; update
    ::piServer::sendToServer $::port(serverPlugUpdate) "$::port(serverIrrigation) 0 setRepere $::prise(${plateforme},ev,$::irrigationZoneIndex) on [expr $TempsOnEV + 1]" $::ip(${plateforme})
    lappend ::listeEVOuverte [list $::prise(${plateforme},ev,$::irrigationZoneIndex) $::ip(${plateforme})]
    
    # On allume la pompe
    ::piLog::log [clock milliseconds] "info" "irrigation : Mise en route ${plateforme},pompe pendant [expr $TempsOnEV] s" ;update
    ::piServer::sendToServer $::port(serverPlugUpdate) "$::port(serverIrrigation) 0 setRepere $::prise(${plateforme},pompe) on [expr $TempsOnEV]" $::ip(${plateforme})
    lappend ::listeEVOuverte [list $::prise(${plateforme},pompe) $::ip(${plateforme})]

    # DAns X secondes, on indique que la zone n'est plus pilotée
    after [expr $TempsOnEV * 1000] "set ::irrigationActive NA"

    incr ::irrigationZoneIndex 

    ::piLog::log [clock milliseconds] "info" "irrigation : Attente $TempsOffEV secondes avant zone suivante";update
    set ::idAfter [after [expr 1000 * $TempsOffEV] irrigationLoop]
    
}

# *************  Update des cuves 
# Initialisation des variable 
initcuve

# On met en route le serveur de message
::piServer::start messageGestion $::port(serverIrrigation)

# Mise en route de la mise à jour des cuves
updateCuve

# *************  Régulation
initRegulationVariable

regulCuve

# *************  Irrigation
irrigationLoop


vwait foreaver

# Lancement 
# tclsh "D:\CBX\cultipiCore\serverIrrigation\serverIrrigation.tcl" 6005 "D:\CBX\cultipiCore\serverIrrigation\confExample\conf.xml" 6001 