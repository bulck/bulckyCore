namespace eval ::checkGoogle {
    variable nbEchec 0
    variable IDAfter ""
    variable adressIP 8.8.8.8
    variable timeMax 30
}

proc checkGoogle::start {IP timeMaxAllowed} {
    variable nbEchec
    variable IDAfter
    variable adressIP
    variable timeMax

    set nbEchec 0
    set IDAfter ""
    set adressIP $IP
    set timeMax $timeMaxAllowed
    
    ::piLog::log [clock milliseconds] "info" "checkGoogle::start ip : $adressIP , timeMax : $timeMax"
    
    ::checkGoogle::check
}

proc checkGoogle::stop {} {
    variable IDAfter
    if  {$IDAfter != ""} {
        after cancel $IDAfter
    }
}


# Cette procédure vérifie que le ping 8.8.8.8 est bien fonctionnel. Dans le cas inverse, le système doit redémarrer
proc checkGoogle::check {} {
    variable nbEchec
    variable IDAfter
    variable adressIP
    variable timeMax
    
    set adressIP 8.8.8.8

    if {[catch {exec ping $adressIP -n 1} result]} {
        set result 0
    } 
    
    if { [regexp "0% loss"  $result]} {
        set nbEchec 0
        set nextTry 10000
        ::piLog::log [clock milliseconds] "debug" "checkGoogle::check Check OK"
    } else {
        set nbEchec [expr $nbEchec + 1]
        set nextTry 1000
        ::piLog::log [clock milliseconds] "info" "checkGoogle::check Check Fail"
    }

    if {$nbEchec > $timeMax} {
        ::piLog::log [clock milliseconds] "warning" "checkGoogle::check Check Fail more than $timeMax so ask reboot"
        exec sudo reboot
    }
    
    set IDAfter [after $nextTry checkGoogle::check]
}