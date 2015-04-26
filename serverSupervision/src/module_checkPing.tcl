namespace eval ::checkPing {
    variable nbEchec
    variable IDAfter
    variable adressIP
    variable timeMax
    variable processID 0
    variable action
    variable actionParam
    variable actionStatus
}

proc checkPing::start {arrayIn} {
    variable nbEchec
    variable IDAfter
    variable adressIP
    variable timeMax
    variable processID
    variable action
    variable actionParam
    variable actionStatus

    array set params $arrayIn
    
    # On ajoute � la liste les adresses IP
    for {set i 0} {$i < $params(nbIP)} {incr i} {
        lappend adressIP($processID) $params(IP,$i)
        set nbEchec($processID,$params(IP,$i)) 0
        set IDAfter($processID) ""
        set actionStatus($processID) ""
    }

    set timeMax($processID) $params(timeMax)
    set action($processID)  $params(error,action)

    ::piLog::log [clock milliseconds] "info" "checkPing::start ipList : $adressIP($processID) , timeMax : $timeMax($processID) , action $action($processID)"
    
    ::checkPing::check $processID
    
    incr processID
}

proc checkPing::stop {} {
    variable IDAfter
    variable processID
    
    for {set i 0} {$i < $processID} {incr i} {
        if  {$IDAfter($i) != ""} {
            after cancel $IDAfter($i)
        }
    }

}


# Cette proc�dure v�rifie que le ping 8.8.8.8 est bien fonctionnel. Dans le cas inverse, le syst�me doit red�marrer
proc checkPing::check {processID} {
    variable nbEchec
    variable IDAfter
    variable adressIP
    variable timeMax
    variable action
    variable actionParam
    variable actionStatus
    
    set errorsFind 0
    
    foreach IP $adressIP($processID) {
        if {[catch {exec ping $IP -n 1} result]} {
            set result 0
        } 
        if { [regexp "0% loss"  $result]} {
            set nbEchec($processID,$IP) 0
            ::piLog::log [clock milliseconds] "debug" "checkPing::check Check $IP OK"
        } else {
            set nbEchec($processID,$IP) [expr $nbEchec($processID,$IP) + 1]
            ::piLog::log [clock milliseconds] "info" "checkPing::check Check $IP Fail"
            set errorsFind 1
        }

        if {$nbEchec($processID,$IP) > $timeMax($processID)} {

            if {$actionStatus($processID) == ""} {
        
                set actionToDo [string tolower [lindex $action($processID) 0]]

                switch $actionToDo {
                    "reboot" {
                        ::piLog::log [clock milliseconds] "warning" "checkPing::check Check $IP Fail more than $timeMax($processID) so ask reboot"
                        exec sudo reboot
                    }
                    "sendmail" {
                        ::piLog::log [clock milliseconds] "warning" "checkPing::check Check $IP Fail more than $timeMax($processID) so sendMail"
                        ::piServer::sendToServer $::port(serverMail) "$::port(serverSupervision) [incr ::TrameIndex] sendMail [lindex $action($processID) 1] \"Cultibox : Probl�me de communication\" \"Plus de communication avec $IP depuis plus de $timeMax($processID) secondes.\""
                    }
                    default {
                        ::piLog::log [clock milliseconds] "error" "checkPing::check Not recognize action $actionToDo"
                    }
                }
                
                set actionStatus($processID) "sended"
            } else {
                ::piLog::log [clock milliseconds] "debug" "checkPing::check Action already sended"
            }
        }
    }
    
    # Le cas d'un retour � la normal
    if {$errorsFind == 0 && $actionStatus($processID) != ""} {
         ::piServer::sendToServer $::port(serverMail) "$::port(serverSupervision) [incr ::TrameIndex] sendMail [lindex $action($processID) 1] \"Cultibox : Fin Probl�me de communication\" \"Retour � la normal pour le probl�me de communication.\""
         set actionStatus($processID) ""
    }
    
    # On ajuste le temps si on trouv� des erreurs
    set nextTry 10000
    if {$errorsFind != 0} {
        set nextTry 1000
    }

    set IDAfter($processID) [after $nextTry checkPing::check $processID]
}