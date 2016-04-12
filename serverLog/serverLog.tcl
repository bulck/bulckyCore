# Lecture des arguments : seul le path du fichier XML est donné en argument
set confXML                 [lindex $argv 0]

set moduleLocalName serverLog

# Init directory
set rootDir [file dirname [file dirname [info script]]]

# Load lib
lappend auto_path [file join $rootDir lib tcl]
package require piLog
package require piTools
package require piServer
package require piXML

# Initialisation d'un compteur pour les commandes externes envoyées
set TrameIndex 0

# On initialise la conf XML
array set configXML {
    verbose     debug
    logPath     "/var/log/bulcky"
}

# Chargement de la conf XML
set RC [catch {
    array set configXML [::piXML::convertXMLToArray $confXML]
} msg]
if {$RC != 0} {
    puts "[clock milliseconds] info ${::moduleLocalName} [clock milliseconds] error $msg"
}


# ###############
#
# server side
#
# ###############

set logFile "/var/log/bulcky/bulckypi.log"

if {$configXML(logPath) != "" && [file isdirectory $configXML(logPath)]} {
    set logFile [file join $configXML(logPath) bulckypi.log]
}
puts "Serveur Log , log file : $logFile"

set actualDay ""

# client connection
proc server {channel host port} \
{
    # save client info
    set ::($channel:host) $host
    set ::($channel:port) $port
    # log
    log "<[clock milliseconds]><serverLog><info><opened - $channel - port $port>"
    set rc [catch \
    {
        # set call back on reading
        fileevent $channel readable [list input $channel]
    } msg]
    if {$rc == 1} \
    {
        # i/o error -> log
        log "<[clock milliseconds]><serverLog><error><i/o error - $msg>"
    }
}

# client e/s

proc input {channel} \
{
    if {[eof $channel]} \
    {
      # client closed -> log & close
      log "<[clock milliseconds]><serverLog><info><closed $channel>"
      catch { close $channel }
    } \
    else \
    {
        # receiving
        set rc [catch { set count [gets $channel message] } msg]
        if {$rc == 1} \
        {
            # i/o error -> log & close
            log "<[clock milliseconds]><serverLog><error><${msg}>"
            catch { close $channel }
        } \
        elseif {$count == -1} \
        {
            # client closed -> log & close
            log "<[clock milliseconds]><serverLog><info><closed $channel>"
            catch { close $channel }
        } \
        else \
        {
            # got message -> do some thing
            set serverForResponse   [::piTools::lindexRobust $message 0]
            set indexForResponse    [::piTools::lindexRobust $message 1]
            set commande            [::piTools::lindexRobust $message 2]
            switch ${commande} {
                "stop" {
                    log "<[clock milliseconds]><serverLog><info><stopping log server>"
                    set ::forever 1
                }
                "pid" {
                    log "<[clock milliseconds]><serverLog><info><Asked pid response to $::($channel:host) : [::piTools::lindexRobust $message 1]>"
                    set serverForResponse [::piTools::lindexRobust $message 0]
                    ::piServer::sendToServer $serverForResponse "$::piServer::portNumber(${::moduleLocalName}) $indexForResponse _pid ${::moduleLocalName} [pid]" $::($channel:host)
                }
                default {
                    log $message
                }
            }
        }
    }
}

# log

proc log {msg} {

    set fid [open $::logFile a+]

    # Format the string
    set Splitted ""
    set rc [catch {
        set Splitted [split $msg "<>"]
    } msgErr]
    if {$rc} {
        log "<[clock milliseconds]><serverLog><info><could not split $msg error : $msgErr>"
    }
    
    # Convert time
    set Time ""
    set rc [catch {
        set Time "[clock format [expr [lindex $Splitted 1] / 1000] -format "%d/%m/%Y %H:%M:%S."][expr [lindex $Splitted 1] % 1000]"
    } msgErr]
    if {$rc} {
        log "<[clock milliseconds]><serverLog><info><log:: could not compute time error : $msgErr - message : $msg - Time is -[lindex $Splitted 1]->"
    }
    
    
    #puts $fid "$::($channel:host):$::($channel:port): $msg"
    puts $fid "${Time}\t[lindex $Splitted 3]\t[lindex $Splitted 5]\t[lindex $Splitted 7]"

    # Cas spécial dans le cas ou c'est bulckypi qui demande l'arret du serveur log
    if {[lindex $Splitted 3] == "bulckypi" && [lindex $Splitted 5] == "debug" && [lindex $Splitted 7] == "stop"} {
        puts $fid "${Time}\tserverLog\tinfo\tAsk to close serverLog by bulckypi"
        set ::forever 1
    }
    
    close $fid
}


# Cette procédure permet d'afficher dans le fichier de log les erreurs qui sont apparues
proc bgerror {message} {
    log "<[clock milliseconds]><serverLog><error_critic><bgerror in [info script] $::argv - $message - >"
    foreach elem [split $::errorInfo "\n"] {
         log "<[clock milliseconds]><serverLog><error_critic><bgerror * $elem >"
    }
}

# ===================
# start
# ===================

# open socket

catch { console show }
catch { wm protocol . WM_DELETE_WINDOW exit }
#set port 6000 ;# 0 if no known free port
set rc [catch \
{
    set channel [socket -server server $::piServer::portNumber(${::moduleLocalName})]
    if {$::piServer::portNumber(${::moduleLocalName}) == 0} \
    {
        set $::piServer::portNumber(${::moduleLocalName}) [lindex [fconfigure $channel -sockname] end]
        puts "--> server port: $::piServer::portNumber(${::moduleLocalName})"
    }
} msg]
if {$rc == 1} \
{
    log "<[clock milliseconds]><serverLog><info><exiting $msg>"
    exit
}
set (server:host) server
set (server:port) $::piServer::portNumber(${::moduleLocalName})

log "<[clock milliseconds]><serverLog><info><starting ${::moduleLocalName} - PID : [pid]>"
log "<[clock milliseconds]><serverLog><info><port ${::moduleLocalName} : $::piServer::portNumber(${::moduleLocalName})>"
log "<[clock milliseconds]><serverLog><info><confXML : $confXML>"
# On affiche les infos dans le fichier de debug
foreach element [lsort [array names configXML]] {
    log "<[clock milliseconds]><serverLog><info><$element : $configXML($element)>"
}

# enter event loop

vwait forever

# tclsh "C:\cultibox\04_CultiPi\01_Software\01_cultiPi\serverLog\serverLog.tcl" 6000 "C:\cultibox\04_CultiPi"
# tclsh D:\CBX\06_bulckyCore\serverLog\serverLog.tcl
# tclsh /opt/bulckypi/serverLog/serverLog.tcl 
