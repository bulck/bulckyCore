
namespace eval ::sensor {

}

# Utiliser pour initialiser la partie sensor
proc ::sensor::init {} {


    # On initialise l'ensemble des valeurs
    set ::sensor(firsReadDone) 0
    for {set i 1} {$i < 7} {incr i} {
        set ::sensor(${i},value,1) ""
        set ::sensor(${i},value,2) ""
    }
    
    set ::subscriptionRunned 0
}


proc ::sensor::loop {} {


    # Le numéro du port est disponible
    # On lui demande les repères nécessaires (les 6 premiers) par abonnement
    set retErr 0
    for {set i 1} {$i < 7} {incr i} {
        incr retErr [::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(serverPlugUpdate) [incr ::TrameIndex] subscription ${i},value,1 2000"]
        incr retErr [::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(serverPlugUpdate) [incr ::TrameIndex] subscription ${i},value,2 2000"]
    }

    # On prend un abonnement sur l'état de la lecture des capteurs
    incr retErr [::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(serverPlugUpdate) [incr ::TrameIndex] subscription firsReadDone 2000"]
    
    if {$retErr == 0} {
        set ::subscriptionRunned 1
    } else {
        ::piLog::log [clock milliseconds] "warning" "::sensor::loop : subscriptions are not done"
    }

    # On tue la boucle si les souscriptions sont lancés
    if {$::subscriptionRunned == 0} {
        after 1500 ::sensor::loop
    }
}