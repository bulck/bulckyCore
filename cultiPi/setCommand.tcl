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


# Demande d'écriture du repere
# Trame standard : [FROM] [INDEX] [commande] [argument]
::piServer::sendToServer $::piServer::portNumber($module) "$::piServer::portNumber(serverSetCommand) 0 [lrange $argv 2 [expr $argc - 1]]" $adresseIP


# tclsh /opt/cultipi/cultiPi/setCommand.tcl serverPlugUpdate localhost setRepere 1 on 10
# tclsh "D:\CBX\cultipiCore\cultiPi\setCommand.tcl" serverPlugUpdate localhost setRepere 1 on 10
# tclsh /opt/cultipi/cultiPi/setCommand.tcl serverMail localhost sendMail info@greenbox-botanic.com "Essai 2 " "Corps du message et contenu"
# tclsh "D:\CBX\cultipiCore\cultiPi\setCommand.tcl" serverMail localhost sendMail gl@greenbox-botanic.com "Essai 2 " "Corps du message et contenu"
# tclsh "D:\CBX\cultipiCore\cultiPi/setCommand.tcl" serverIrrigation localhost stop
