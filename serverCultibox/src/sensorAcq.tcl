
namespace eval ::sensorAcq {
    variable periodeAcq  [expr 1000 * 300]
    #variable periodeAcq  [expr 1000 * 5]
    variable bandeMorteAcq 0.01
}

# Utiliser pour initialiser la partie sensor
proc ::sensorAcq::init {logPeriode} {
    variable periodeAcq 

    set ::port(serverAcqSensor)   ""

    # On demande le numéro de port du lecteur de capteur
    ::piLog::log [clock milliseconds] "info" "::sensorAcq::init ask getPort serverAcqSensor"
    ::piServer::sendToServer $::port(serverCultiPi) "$::port(serverCultibox) [incr ::TrameIndex] getPort serverAcqSensor"

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
    
    # On vérifie si le numéro de port est disponible
    if {$::port(serverAcqSensor) != ""} {
    
        # Le numéro du port est disponible
        # On lui demande les repères nécessaires (les 6 premiers) par abonnement
        for {set i 1} {$i < 7} {incr i} {
            ::piServer::sendToServer $::port(serverAcqSensor) "$::port(serverCultibox) [incr ::TrameIndex] subscription ${i},value $periodeAcq $bandeMorteAcq"
            
            # Les lignes suivantes marchent aussi !
            #::piServer::sendToServer $::port(serverAcqSensor) "$::port(serverCultibox) [incr ::TrameIndex] getRepere ${i},value,1"
            #::piServer::sendToServer $::port(serverAcqSensor) "$::port(serverCultibox) [incr ::TrameIndex] getRepere ${i},value,2"
        }

        set ::subscriptionRunned(sensorAcq) 1
    
    } else {
        ::piLog::log [clock milliseconds] "debug" "::sensorAcq::loop : port of serverAcqSensor is not defined"
    }

    # On tue la boucle si les souscriptions sont lancés
    if {$::subscriptionRunned(sensorAcq) == 0} {
        after 1500 ::sensorAcq::loop
    }
}
