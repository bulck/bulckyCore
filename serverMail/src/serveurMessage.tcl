
proc messageGestion {message networkhost} {

    # Trame standard : [FROM] [INDEX] [commande] [argument]
    set serverForResponse   [::piTools::lindexRobust $message 0]
    set indexForResponse    [::piTools::lindexRobust $message 1]
    set commande            [::piTools::lindexRobust $message 2]

    switch [string tolower ${commande}] {
        "stop" {
            ::piLog::log [clock milliseconds] "info" "Asked stop"
            stopIt
        }
        "pid" {
            ::piLog::log [clock milliseconds] "info" "Asked pid"
            ::piServer::sendToServer $serverForResponse "$::piServer::portNumber(${::moduleLocalName}) $indexForResponse _pid ${::moduleLocalName} [pid]" $networkhost
        }
        "sendmail" {
            ::piLog::log [clock milliseconds] "info" "Asked to send mail"
            
            set to      [::piTools::lindexRobust $message 3]
            set subject [lindex $message 4]
            set body    [lindex $message 5]
            
            ::piLog::log [clock milliseconds] "debug" "to : $to - subject : $subject - body : $body"
            
            send_email $to $subject $body
            
        }
        "sendmailtest" {
            ::piLog::log [clock milliseconds] "info" "Asked to send mail"
            
            set to      [::piTools::lindexRobust $message 3]
            set subject [lindex $message 4]
            set body    [lindex $message 5]
            
            ::piLog::log [clock milliseconds] "debug" "to : $to - subject : $subject - body : $body"
            
            set response [send_email $to $subject $body]
            
            ::piLog::log [clock milliseconds] "info" "response : $serverForResponse $indexForResponse _sendmailtest - $response - to $networkhost"
            ::piServer::sendToServer $serverForResponse "$serverForResponse $indexForResponse _sendmailtest $response" $networkhost
            
        }
        "reloadxml" {
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
        "getrepere" {
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
            # Si on reçoit le retour d'une commande, le nom du serveur est le notre
            if {$serverForResponse == $::piServer::portNumber(${::moduleLocalName})} {
            
                if {[array names ::TrameSended -exact $indexForResponse] != ""} {
                    
                    switch [lindex $::TrameSended($indexForResponse) 0] {
                        "update_plug_value" {
                            set plugumber [lindex $::TrameSended($indexForResponse) 1]
                        
                            set ::plug($plugumber,updateStatus) $commande
                            set ::plug($plugumber,updateStatusComment) ${message}
                        
                            ::piLog::log [clock milliseconds] "info" "I2C Update plug $plugumber updateStatus : -$commande- updateStatusComment : -${message}-"
                        
                            # On supprime cette donnée de la mémoire
                            unset ::TrameSended($indexForResponse)
                        }
                        default {
                            ::piLog::log [clock milliseconds] "error" "Not recognize keyword response -${message}-"
                        }                    
                    }
                    
                } else {
                    ::piLog::log [clock milliseconds] "error" "Not requested response -${message}-"
                }
            
                
            } else {
                ::piLog::log [clock milliseconds] "error" "Received -${message}- but not interpreted"
            }
        }
    }
}