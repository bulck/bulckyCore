
namespace eval ::plugAcq {
}

# Utiliser pour initialiser la partie sensor
proc ::plugAcq::init {} {
    
    for {set i 1} {$i < 17} {incr i} {
        set ::plug(${i},value) ""
    }
    
    set ::subscriptionRunned(plugAcq) 0
    set ::updateOfEndOfTheDay 0
    set ::updateAtStartOfTheDay 0
    
}


proc ::plugAcq::loop {} {

    variable periodeAcq
    variable bandeMorteAcq
    
    # On vérifie si le numéro de port est disponible (et qu'on l'a pas demandé)
    if {$::subscriptionRunned(plugAcq) == 0} {
    
        # Le numéro du port est disponible
        # On lui demande les repères nécessaires (les 16 premiers) par abonnement
        set retErr 0
        for {set i 1} {$i < 17} {incr i} {
            incr retErr [::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverHisto) [incr ::TrameIndex] subscriptionEvenement plug ${i},value"]
        }

        if {$retErr == 0} {
            set ::subscriptionRunned(plugAcq) 1
        } else {
            ::piLog::log [clock milliseconds] "warning" "::plugAcq::loop : subscriptions are not done"
        }

    }
    
    # En fin de journée, on demande une mise à jour des valeurs
    if {[::piTime::readSecondsOfTheDay] > 86397} {
        if {$::updateOfEndOfTheDay == 0 && $::piServer::portNumber(serverPlugUpdate) != ""} {
            set ::updateOfEndOfTheDay 1
            
            # On lui demande une mise à jour des valeurs
            ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverHisto) [incr ::TrameIndex] updateSubscriptionEvenement"
            
        }
    } else {
        set ::updateOfEndOfTheDay 0
    }
    
    # En début de journée aussi !
    if {[::piTime::readSecondsOfTheDay] < 5 && [::piTime::readSecondsOfTheDay] > 2} {
        if {$::updateAtStartOfTheDay == 0 && $::piServer::portNumber(serverPlugUpdate) != ""} {
            set ::updateAtStartOfTheDay 1
            
            # On lui demande une mise à jour des valeurs
            ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverHisto) [incr ::TrameIndex] updateSubscriptionEvenement"
            
        }
    } else {
        set ::updateAtStartOfTheDay 0
    }

    # On relance la boucle toutes les 500 millisecondes
    after 500 ::plugAcq::loop
}