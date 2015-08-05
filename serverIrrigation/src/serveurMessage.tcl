
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
        "reloadXML" {
            ::piLog::log [clock milliseconds] "info" "messageGestion : Asked reloadXML"
            set RC [catch {
                array set ::configXML [::piXML::convertXMLToArray $::confXML]
            } msg]
            if {$RC != 0} {
                ::piLog::log [clock milliseconds] "error" "messageGestion : Asked reloadXML error : $msg"
            } else {
                # On affiche les infos dans le fichier de debug
                foreach element [lsort [array names ::configXML]] {
                    ::piLog::log [clock milliseconds] "info" "$element : $::configXML($element)"
                }
            }
        }
        "getRepere" {
            # Pour toutes les variables demandées
            set indexVar 3
            set returnList ""
            while {[set variable [::piTools::lindexRobust $message $indexVar]] != ""} {
                # La variable est le nom de la variable à lire

                ::piLog::log [clock milliseconds] "debug" "Asked getRepere $variable"

                if {[info exists ::$variable] == 1} {
                
                    eval set returnValue $$variable

                    lappend returnList $returnValue
                } else {
                    ::piLog::log [clock milliseconds] "error" "Asked variable $variable - variable doesnot exists"
                }
                
                incr indexVar
            }

            ::piLog::log [clock milliseconds] "info" "response : $serverForResponse $indexForResponse _getRepere - $returnList - to $networkhost"
            ::piServer::sendToServer $serverForResponse "$serverForResponse $indexForResponse _getRepere $returnList" $networkhost

        }
        default {
        
            set plateformeNom     $::configXML(plateforme,$::cuveIndex,name)
        
            set value [lindex $message 3 0]
            
            if {$::cuveIndex != "" && $value != ""} {
                ::piLog::log [clock milliseconds] "debug" "messageGestion : Reception hauteur cuve $plateformeNom , [lindex $message 3 0] cm "
                set ::cuve($::cuveIndex) $value
                
                # On met à jour l'interface graphique
                #cuves.$::cuveAsked.cuve configure -value [expr [lindex $message 3] * 4]
                
                # Si on a jamais eu d'info et que la cuve n'est pas pleine
                if {$value != "" &&
                    $value != "DEFCOM" &&
                    $value != "NA" &&
                    $value < 10} {
                    set ::cuve($::cuveIndex,heureDernierPlein) 0
                }
                
                # Si la cuve est pleine on enregistre l'heure
                if {$value != "" &&
                    $value != "DEFCOM" &&
                    $value != "NA" &&
                    $value >= 10} {
                    set ::cuve($::cuveIndex,heureDernierPlein) [clock seconds]
                }
                
            } else {
                ::piLog::log [clock milliseconds] "error" "Message pas compris $message"
            }
        }
    }
}