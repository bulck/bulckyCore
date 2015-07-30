
namespace eval ::sensorAcq {
    variable periodeAcq  [expr 1000 * 300]
    #variable periodeAcq  [expr 1000 * 5]
    variable bandeMorteAcq 0.01
}

# Utiliser pour initialiser la partie sensor
proc ::sensorAcq::init {logPeriode} {
    variable periodeAcq 

    for {set i 1} {$i < 7} {incr i} {
        set ::sensor(${i},value,1) ""
        set ::sensor(${i},value,2) ""
        set ::sensor(${i},type) ""
    }
    
    set ::subscriptionRunned(sensorAcq) 0

    set periodeAcq  [expr 1000 * $logPeriode]

}

proc ::sensorAcq::loop {} {

    variable periodeAcq
    variable bandeMorteAcq

    # Le numéro du port est disponible
    # On lui demande les repères nécessaires (les 6 premiers) par abonnement
    set retErr 0
    for {set i 1} {$i < 7} {incr i} {
        incr retErr [::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(serverCultibox) [incr ::TrameIndex] subscription ${i},value 2000"]
    }

    # On prend un abonnement sur l'état de la lecture des capteurs
    incr retErr [::piServer::sendToServer $::piServer::portNumber(serverAcqSensor) "$::piServer::portNumber(serverCultibox) [incr ::TrameIndex] subscription firsReadDone 2000"]

    if {$retErr == 0} {
        set ::subscriptionRunned(sensorAcq) 1
    } else {
        ::piLog::log [clock milliseconds] "warning" "::sensorAcq::loop : subscriptions are not done"
    }

    # On tue la boucle si les souscriptions sont lancés
    if {$::subscriptionRunned(sensorAcq) == 0} {
        after 1500 ::sensorAcq::loop
    }
}
