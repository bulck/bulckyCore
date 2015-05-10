namespace eval ::report {
    variable XMLprocess
    variable processID 0
    variable nbDayPerMonth [list 0 31 28 31 30 31 30 31 31 30 31 30 31]
}

proc report::start {arrayIn} {
    variable XMLprocess
    variable processID

    # Save params
    array set XMLprocess [list \
        $processID,frequency    daily \
        $processID,hour         18 \
        $processID,done         0 \
        $processID,IDAfter      0 \
        $processID,eMail        "NA" \
    ]
    
    for {set i 0} {$i < [llength $arrayIn]} {incr i 2} {
        set XMLprocess($processID,[lindex $arrayIn $i]) [lindex $arrayIn [expr $i + 1]]
    }
    
    # On affiche les éléments du process 
    foreach elemName [array names XMLprocess -glob "$processID,*"] {
        ::piLog::log [clock milliseconds] "info" "report::start $elemName : $XMLprocess($elemName)"
    }

    

    set timeToWait 0
    
    switch $XMLprocess($processID,frequency) {
        "now" {
            set timeToWait 1
        }
        "daily" {
            set timeToWait [report::computeTimeWait 1 $XMLprocess($processID,hour)]
        }
        "monthly" {
            set timeToWait [report::computeTimeWait 7 $XMLprocess($processID,hour) forceStartASAP]
        }
        default {
            ::piLog::log [clock milliseconds] "info" "report::start not understand frequency $XMLprocess($processID,frequency)"
        }
    }
    
    ::piLog::log [clock milliseconds] "info" "report::start send first report in $timeToWait"
    
    if {$timeToWait != 0} {
        set XMLprocess($processID,IDAfter) [after [expr $timeToWait * 1000] [list ::report::check $processID]]
    }
    incr processID
}

proc report::stop {} {
    variable XMLprocess
    variable processID
    
    for {set i 0} {$i < $processID} {incr i} {
        if  {$XMLprocess($i,IDAfter) != ""} {
            after cancel $XMLprocess($i,IDAfter)
        }
    }

}

proc report::computeTimeWait {nbDay hourToSend {forceStartASAP 0}} {
    
    variable nbDayPerMonth
    
    set actualNbSeconds [clock seconds]
    
    set actualHour [string trimleft [clock format $actualNbSeconds -format "%H"] "0"]
    if {$actualHour == ""} {set actualHour 0}
    
    set actualDay [string trimleft [clock format $actualNbSeconds -format "%d"] "0"]
    if {$actualDay == ""} {set actualDay 0}
        
    set actualMonth [string trimleft [clock format $actualNbSeconds -format "%m"] "0"]
    if {$actualMonth == ""} {set actualMonth 0}
    
    set actualYear [string trimleft [clock format $actualNbSeconds -format "%y"] "0"]
    if {$actualYear == ""} {set actualYear 0}
    
    set actualDate           [clock format $actualNbSeconds -format "%y-%m-%d"]
    set actualDateWithoutDay [clock format $actualNbSeconds -format "%y-%m-"]
    
    set timeToWait 1
    
    # Si l'heure est inférieur à l'heure demandée, on envoi aujourd'hui le prochain rapport
    if {$actualHour < $hourToSend} {

        if {$hourToSend < 10} {
            set hourToSend "0${hourToSend}"
        }
    
        set futurNbSeconds [clock scan "$actualDate ${hourToSend}:00:00" -format "%y-%m-%d %H:%M:%S"]
        
        set timeToWait [expr $futurNbSeconds - $actualNbSeconds]
    
    } elseif {$nbDay == 1 || $forceStartASAP != 0} {
    
        # Sinon on envoi le suivant

        incr actualDay
        if {$actualDay > [lindex $nbDayPerMonth $actualMonth]} {
            set actualDay 1
            incr actualMonth
            if {$actualMonth > 12} {
                set actualMonth 1
                incr actualYear
            }
        }
        
        if {$actualYear < 10} {
            set actualYear "0$actualYear"
        }
        
        if {$actualMonth < 10} {
            set actualMonth "0$actualMonth"
        }
        
        if {$actualDay < 10} {
            set actualDay "0$actualDay"
        }
        
        if {$hourToSend < 10} {
            set hourToSend "0${hourToSend}"
        }

        set futurNbSeconds [clock scan "${actualYear}-${actualMonth}-${actualDay} ${hourToSend}:00:00" -format "%y-%m-%d %H:%M:%S"]
        
        set timeToWait [expr $futurNbSeconds - $actualNbSeconds]
        
    } else {
    
        # Sinon on l'envoi dans n jours
        incr actualDay $nbDay
        if {$actualDay > [lindex $nbDayPerMonth $actualMonth]} {
            set actualDay 1
            incr actualMonth
            if {$actualMonth > 12} {
                set actualMonth 1
                incr actualYear
            }
        }
        
        if {$actualYear < 10} {
            set actualYear "0$actualYear"
        }
        
        if {$actualMonth < 10} {
            set actualMonth "0$actualMonth"
        }
        
        if {$actualDay < 10} {
            set actualDay "0$actualDay"
        }
        
        if {$hourToSend < 10} {
            set hourToSend "0${hourToSend}"
        }
        
        set futurNbSeconds [clock scan "${actualYear}-${actualMonth}-${actualDay} ${hourToSend}:00:00" -format "%y-%m-%d %H:%M:%S"]
        
        set timeToWait [expr $futurNbSeconds - $actualNbSeconds]
    }
    
    if {$timeToWait < 1} {
        ::piLog::log [clock milliseconds] "error" "report::start time is under 1 "
    }
    
    return $timeToWait
}

# Cette procédure vérifie que le ping 8.8.8.8 est bien fonctionnel. Dans le cas inverse, le système doit redémarrer
proc report::check {processID} {
    variable XMLprocess
   
    set title {[Cultibox : rapport]}
    
    set message "Rapport du [clock format [clock seconds] -format "%Y/%m/%d %H:%M:%S"] : "
    
    set message "${message}\\nAucun texte a envoyer ...."

    set message "${message}Message envoyé automatiquement par ma Cultibox"
    
    # On envoi le message
    ::piServer::sendToServer $::piServer::portNumber(serverMail) "$::piServer::portNumber(serverSupervision) [incr ::TrameIndex] sendMail $XMLprocess($processID,eMail) \"${title}\" \"${message}\""
    
    set timeToWait 0
    
    switch $XMLprocess($processID,frequency) {
        "daily" {
            set timeToWait [report::computeTimeWait 1 $XMLprocess($processID,hour)]
        }
        "monthly" {
            set timeToWait [report::computeTimeWait 7 $XMLprocess($processID,hour)]
        }
        default {
            ::piLog::log [clock milliseconds] "info" "report::check not understand frequency $XMLprocess($processID,frequency)"

            return
        }
    }
    
    ::piLog::log [clock milliseconds] "info" "report::check send new report in $timeToWait"
    
    if {$timeToWait != 0} {
        set XMLprocess($processID,IDAfter) [after [expr $timeToWait * 1000] [list ::report::check $processID]]
    }
    
}