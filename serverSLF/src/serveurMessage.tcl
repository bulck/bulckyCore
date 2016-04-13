
proc messageGestion {message networkhost} {

    # Trame standard : [FROM] [INDEX] [commande] [argument]
    set serverForResponse   [::piTools::lindexRobust $message 0]
    set indexForResponse    [::piTools::lindexRobust $message 1]
    set commande            [::piTools::lindexRobust $message 2]
    if {$networkhost == "127.0.0.1"} {
        set networkhost "localhost"
    }

    switch -nocase ${commande} {
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
        "fillCuve" {
            set cuve [::piTools::lindexRobust $message 3]
            ::piLog::log [clock milliseconds] "info" "messageGestion : Asked fillCuve  plateforme $cuve"
            
            remplissageCuve $cuve

        }
        "setRepere" {
            set variable [::piTools::lindexRobust $message 3]
            set value   [::piTools::lindexRobust $message 4]
            ::piLog::log [clock milliseconds] "info" "messageGestion : Asked setRepere  variable $variable value $value"
            
            set $variable $value
            
        }
        "getRepere" {
            # Pour toutes les variables demandées
            set indexVar 3
            set returnList ""
            while {[set variable [::piTools::lindexRobust $message $indexVar]] != ""} {
                # La variable est le nom de la variable à lire

                ::piLog::log [clock milliseconds] "debug" "Asked getRepere $variable"

                if {[info exists $variable] == 1} {
                
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
        "_getRepere" {
       
            set value [lrange $message 3 end]
            # ::piLog::log [clock milliseconds] "debug" "message recu : value $value from $networkhost"
            if {$value == ""} {
                ::piLog::log [clock milliseconds] "error" "Message pas compris $message"
            } else {
                ::piLog::log [clock milliseconds] "debug" "messageGestion : Reception capteur $networkhost "
                
                for {set i 1} {$i < [llength [lrange $message 3 end]]} {incr i} {
                    # ::piLog::log [clock milliseconds] "debug" "messageGestion : Capteur $i Valeur [lindex [lrange $message 3 end] [expr $i - 1]] "
                    set ::sensor(${networkhost},${i}) [lindex [lrange $message 3 end] [expr $i - 1]]
                }
            }
        }
        default {
            ::piLog::log [clock milliseconds] "error" "Message pas compris $message"

        }
    }
}