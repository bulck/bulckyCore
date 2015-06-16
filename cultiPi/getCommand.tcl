#!/usr/bin/tclsh

# Init directory
set rootDir [file dirname [file dirname [info script]]]

# Load lib
lappend auto_path [file join $rootDir lib tcl]
package require piLog
package require piServer
package require piTools

::piLog::openLogAs "none"

set module   [lindex $argv 0]
set adresseIP [lindex $argv 1]

#puts "Reading variable [lrange $argv 1 [expr $argc - 1]] of module $module"

set killID ""

proc messageGestion {message host} {

    # Trame standard : [FROM] [INDEX] [commande] [argument]
    set serverForResponse   [::piTools::lindexRobust $message 0]
    set indexForResponse    [::piTools::lindexRobust $message 1]
    set commande            [::piTools::lindexRobust $message 2]

    puts [join [lrange $message 3 end] "\t"]

    # On supprime le killID
    after cancel $::killID
    
    set ::forever 1
}
::piServer::start messageGestion $::piServer::portNumber(serverGetCommand)

# On regarde sur quel serveur il souhaite lancer la commande

# Demande lecture du repere
# Trame standard : [FROM] [INDEX] [commande] [argument]
::piServer::sendToServer $::piServer::portNumber($module) "$::piServer::portNumber(serverGetCommand) 0 [lrange $argv 2 [expr $argc - 1]]" $adresseIP

# Après 2 secondes, s'il n'a pas répondu on le tue
set killID [after 4000 {
    set ::forever 1
    puts "TIMEOUT"
}]

vwait forever

# tclsh /opt/cultipi/cultiPi/getCommand.tcl serverAcqSensor localhost getRepere "::sensor(1,value)" "::sensor(2,value)"
# tclsh /opt/cultipi/cultiPi/getCommand.tcl serverPlugUpdate localhost getRepere "::plug(1,value)" "::plug(2,value)" "::plug(3,value)" "::plug(4,value)"
# tclsh /opt/cultipi/cultiPi/getCommand.tcl serverAcqSensor localhost getRepere "::sensor(firsReadDone)" 
# tclsh "D:\CBX\cultipiCore\cultiPi\getCommand.tcl" serverAcqSensor 192.168.0.100 getRepere "::sensor(1,value)"
# tclsh "D:\CBX\cultipiCore\cultiPi\getCommand.tcl" serverAcqSensor localhost getRepere "::sensor(1,value)"
# tclsh "D:\CBX\cultipiCore\cultiPi\getCommand.tcl" serverAcqSensor localhost getRepere "::sensor(1,value)" "::sensor(2,value)"
# tclsh "D:\CBX\cultipiCore\cultiPi\getCommand.tcl" serverCultipi localhost getRepere "statusInitialisation"
# tclsh "D:\CBX\cultipiCore\cultiPi\getCommand.tcl" serverCultipi localhost  getRepere statusInitialisation cultipiActualHour
# tclsh "D:\CBX\cultipiCore\cultiPi\getCommand.tcl" serverPlugUpdate localhost setGetRepere 2 on 10
# tclsh /home/sdf/Bureau/Cultipi/cultiPi/getCommand.tcl serverAcqSensor 192.168.1.55 getRepere "::sensor(1,value)"
# tclsh /home/sdf/Bureau/Cultipi/cultiPi/getCommand.tcl serverAcqSensor localhost pid
# tclsh D:\CBX\cultipiCore\cultiPi/getCommand.tcl serverAcqSensor localhost pid
