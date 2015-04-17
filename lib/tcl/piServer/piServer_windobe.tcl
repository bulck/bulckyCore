#!/bin/sh
#\
exec tclsh "$0" ${1+"$@"}

package provide piServer 1.0

namespace eval ::piServer {

}

# Load Cultipi server
proc ::piServer::server {channel host port} \
{

}

proc ::piServer::input {channel} {

}

proc ::piServer::start {callBackMessageIn portIn} {

}

proc ::piServer::sendToServer {portNumber message {ip localhost}} {

}

# Cette procédure est utilisée pour trouver un port de dispo
proc ::piServer::findAvailableSocket {start} {


    
    return 10
}
proc ::piServer::testForfindAvailableSocket {test} {

}