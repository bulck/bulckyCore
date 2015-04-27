
namespace eval ::sensor {

}

# Utiliser pour initialiser la partie sensor
proc ::sensor::init {} {

    set ::port(serverAcqSensor)   ""

    # On demande le num�ro de port du lecteur de capteur
    ::piLog::log [clock milliseconds] "info" "ask getPort serverAcqSensor"
    ::piServer::sendToServer $::piServer::portNumber(serverCultipi) "$::piServer::portNumber(serverPlugUpdate) [incr ::TrameIndex] getPort serverAcqSensor"

    # On initialise l'ensemble des valeurs
    set ::sensor(firsReadDone) 0
    for {set i 1} {$i < 7} {incr i} {
        set ::sensor(${i},value,1) ""
        set ::sensor(${i},value,2) ""
    }
    
    set ::subscriptionRunned 0
}


proc ::sensor::loop {} {

    # On v�rifie si le num�ro de port est disponible
    if {$::piServer::portNumber(serverAcqSensor) != ""} {
    
        # Le num�ro du port est disponible
        # On lui demande les rep�res n�cessaires (les 6 premiers) par abonnement
        for {set i 1} {$i < 7} {incr i} {
            ::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(serverPlugUpdate) [incr ::TrameIndex] subscription ${i},value,1 2000"
            ::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(serverPlugUpdate) [incr ::TrameIndex] subscription ${i},value,2 2000"
            
            # Les lignes sivantes marchent aussi !
            #::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(serverPlugUpdate) [incr ::TrameIndex] getRepere ${i},value,1"
            #::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(serverPlugUpdate) [incr ::TrameIndex] getRepere ${i},value,2"
        }
        
        # On prend un abonnement sur l'�tat de la lecture des capteurs
        ::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(serverPlugUpdate) [incr ::TrameIndex] subscription firsReadDone 2000"

        set ::subscriptionRunned 1
    
    } else {
        ::piLog::log [clock milliseconds] "debug" "::sensor::loop : port of serverAcqSensor is not defined"
    }

    # On tue la boucle si les souscriptions sont lanc�s
    if {$::subscriptionRunned == 0} {
        after 1500 ::sensor::loop
    }
}