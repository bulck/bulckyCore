#!/bin/sh
#\
exec tclsh "$0" ${1+"$@"}

package provide piServer 1.0

namespace eval ::piServer {
    variable callBackMessage ""
    variable debug 0
    variable portNumber
    variable portNumberReverse
    
    set portNumber(serverCultipi)     6000
    set portNumber(serverLog)         6003
    set portNumber(serverPlugUpdate)  6004
    set portNumber(serverAcqSensor)   6006
    set portNumber(serverHisto)       6009
    set portNumber(serverIrrigation)  6011
    set portNumber(serverCultibox)    6013
    set portNumber(serverMail)        6015
    set portNumber(serverSupervision) 6019

    set portNumber(serverGet)         6022
    set portNumber(serverGetCommand)  6023
    set portNumber(serverSet)         6024
    set portNumber(serverSetCommand)  6025
    
    set portNumber(serverTrigger)     6026
    
    set portNumber(serverPHP)         6027
    set portNumber(serverAcqSensorUSB)   6028
    set portNumber(serverAcqSensorV2)   6029
    set portNumber(serverSLF)           6030
    
    foreach name [array names portNumber] {
        set portNumberReverse($portNumber($name)) $name
    }
    
}

# Load Cultipi server
proc ::piServer::server {channel host port} \
{
    variable debug
    variable portNumberReverse

    # save client info
    set ::($channel:host) $host
    set ::($channel:port) $port
    # log
    if {$debug == 1} {
        ::piLog::log [clock milliseconds] "debug" "::piServer::server Ouverture connexion par $host : $port - socket $channel"
    }
    set rc [catch \
    {
        # set call back on reading
        fileevent $channel readable [list ::piServer::input $channel]
    } msg]
    if {$rc == 1} \
    {
        # i/o error -> log
        ::piLog::log [clock milliseconds] "error" "::piServer::server i/o error - $msg"
    }
}

proc ::piServer::input {channel} {
    variable callBackMessage
    variable debug

    if {[eof $channel]} \
    {
        # client closed -> log & close
        if {$debug == 1} {
            ::piLog::log [clock milliseconds] "debug" "::piServer::input closed $channel"
        }
        
        catch { close $channel }
    } \
    else \
    {
        # receiving
        set rc [catch { set count [gets $channel data] } msg]
        if {$rc == 1} \
        {
            # i/o error -> log & close
            ::piLog::log [clock milliseconds] "error" "${msg}"
            catch { close $channel }
        } \
        elseif {$count == -1} \
        {
            # client closed -> log & close
            if {$debug == 1} { 
                ::piLog::log [clock milliseconds] "debug" "::piServer::input closed $channel"
            }
            catch { close $channel }
        } \
        else \
        {
            if {$debug == 1} { 
                ::piLog::log [clock milliseconds] "debug" "::piServer::input message received -${data}- send by $channel"
            }
            # got data -> do some thing
            ::${callBackMessage} ${data} $::($channel:host)
        }
    }
}

proc ::piServer::start {callBackMessageIn portIn} {
    variable callBackMessage
    variable debug

    set callBackMessage $callBackMessageIn

    set rc [catch \
    {
        set channel [socket -server ::piServer::server $portIn]
        if {$portIn == 0} \
        {
            set portIn [lindex [fconfigure $channel -sockname] end]
            ::piLog::log [clock milliseconds] "debug" "--> server port: $portIn"
        }
    } msg]
    if {$rc == 1} \
    {
        ::piLog::log [clock milliseconds] "error_critic" "::piServer::start erreur exiting msg: $msg"
        puts "::piServer::start erreur exiting msg: $msg"
        exit
    }
}

proc ::piServer::sendToServer {portNumber message {ip localhost}} {
    variable debug
    variable portNumberReverse
    
    set retVal 0
    
    set channel ""

    set rc [catch { set channel [socket ${ip} $portNumber] } msg]
    if {$rc == 1} {
        ::piLog::log [clock milliseconds] "error" "::piServer::sendToServer try to open socket to -$ip : $portNumber - $portNumberReverse($portNumber)- - erreur :  -$msg-"
        set retVal 1
        return $retVal
    }

    set rc [catch \
    {
        puts $channel "$message"
        flush $channel
    } msg]
    if {$rc == 1} {
        ::piLog::log [clock milliseconds] "error" "::piServer::sendToServer try to send message to -$ip : $portNumber - $portNumberReverse($portNumber)- - erreur :  -$msg-"
        set retVal 1
    } else {
        if {$debug == 1} { 
            ::piLog::log [clock milliseconds] "debug" "::piServer::sendToServer message send to -$ip : $portNumber - $portNumberReverse($portNumber) - message : -$message-"
        }
    }

    set rc [catch \
    {
        close $channel
    } msg]
    if {$rc == 1} \
    {
        ::piLog::log [clock milliseconds] "error" "::piServer::sendToServer erreur closing channel -$channel-"
        set retVal 1
    }
    
    return $retVal
}

# Cette procédure est utilisée pour trouver un port de dispo
proc ::piServer::findAvailableSocket {start} {

    for {set index 0} {$index < 1000} {incr index} {
    
        set RC [catch {
            set sock [socket -server [list ::piServer::testForfindAvailableSocket [clock seconds]] [expr $start + $index]]
        } msg]
        
        if {$RC != 1} {
            close $sock
            return [expr $start + $index]
        }
        
    }

    return "No socket found"
}
proc ::piServer::testForfindAvailableSocket {test} {

}