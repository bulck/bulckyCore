
proc messageGestion {message networkhost} {

    # Trame standard : [FROM] [INDEX] [commande] [argument]
    set serverForResponse   [::piTools::lindexRobust $message 0]
    set indexForResponse    [::piTools::lindexRobust $message 1]
    set commande            [::piTools::lindexRobust $message 2]

    switch ${commande} {
        "stop" {
            ::piLog::log [clock milliseconds] "info" "messageGestion : Asked stop"
            stopIt
        }
        "reload" {
            ::piLog::log [clock milliseconds] "info" "messageGestion : Asked reload"
            reload
        }
        "pid" {
            ::piLog::log [clock milliseconds] "info" "messageGestion : Asked pid"
            ::piServer::sendToServer $serverForResponse "$::piServer::portNumber(${::moduleLocalName}) $indexForResponse _pid ${::moduleLocalName} [pid]" $networkhost
        }
        "getRepere" {
            # La variable est le nom de la variable à lire
            set variable  [::piTools::lindexRobust $message 3]

            ::piLog::log [clock milliseconds] "info" "messageGestion : Asked getRepere $variable by $networkhost"
            # Les parametres d'un repere : nom Valeur 
            
            if {[info exists ::$variable] == 1} {
            
                eval set returnValue $$variable
            
                ::piLog::log [clock milliseconds] "info" "messageGestion : response : $serverForResponse $indexForResponse _getRepere $returnValue"
                ::piServer::sendToServer $serverForResponse "$serverForResponse $indexForResponse _getRepere $returnValue" $networkhost
            } else {
                ::piLog::log [clock milliseconds] "error" "messageGestion : Asked variable $variable - variable doesnot exists"
            }
        }
        default {
        
            set plateformeNom     $::configXML(plateforme,$::cuveIndex,name)
        
            if {$::cuveIndex != "" && [lindex $message 3] != ""} {
                ::piLog::log [clock milliseconds] "debug" "messageGestion : Reception hauteur cuve $plateformeNom , message $message "
                set ::cuve($::cuveIndex) [lindex $message 3]
                
                # On met à jour l'interface graphique
                #cuves.$::cuveAsked.cuve configure -value [expr [lindex $message 3] * 4]
                
                # Si on a jamais eu d'info et que la cuve n'est pas pleine
                if {[lindex $message 3] != "" &&
                    [lindex $message 3] != "DEFCOM" &&
                    [lindex $message 3] != "NA" &&
                    [lindex $message 3] < 10} {
                    set ::cuve($::cuveIndex,heureDernierPlein) 0
                }
                
                # Si la cuve est pleine on enregistre l'heure
                if {[lindex $message 3] != "" &&
                    [lindex $message 3] != "DEFCOM" &&
                    [lindex $message 3] != "NA" &&
                    [lindex $message 3] >= 10} {
                    set ::cuve($::cuveIndex,heureDernierPlein) [clock seconds]
                }
                
            } else {
                ::piLog::log [clock milliseconds] "error" "Message pas compris $message"
            }
        }
    }
}