# Init directory
set rootDir [file dirname [file dirname [info script]]]

# Read argv
set port(serverMail)  [lindex $argv 0]
set confXML                 [lindex $argv 1]
set port(serverLogs)        [lindex $argv 2]
set port(serverCultiPi)     [lindex $argv 3]
set port(serverAcqSensor)   6006
set port(serverPlugUpdate)  6004
set port(serverHisto)       6009

# Load lib
lappend auto_path [file join $rootDir lib tcl]
package require piLog
package require piServer
package require piTools
package require piTime
package require piXML

# Chargement des fichiers externes
source [file join $rootDir serverMail src serveurMessage.tcl]

package require smtp
package require mime

# Initialisation d'un compteur pour les commandes externes envoyées
set TrameIndex 0

# On initialise la conf XML
array set configXML {
    verbose     debug
    serverSMTP  NA
    port        25
    username    NA
    password    NA
}

# Chargement de la conf XML
set RC [catch {
    array set configXML [::piXML::convertXMLToArray $confXML]
} msg]
if {$RC != 0} {
    ::piLog::log [clock milliseconds] "error" "$msg"
}

# On initialise la connexion avec le server de log
::piLog::openLog $port(serverLogs) "serverMail" $configXML(verbose)

::piLog::log [clock milliseconds] "info" "starting serverMail - PID : [pid]"
::piLog::log [clock milliseconds] "info" "port serverMail : $port(serverMail)"
::piLog::log [clock milliseconds] "info" "confXML : $confXML"
::piLog::log [clock milliseconds] "info" "port serverLogs : $port(serverLogs)"
::piLog::log [clock milliseconds] "info" "port serverCultiPi : $port(serverCultiPi)"
# On affiche les infos dans le fichier de debug
foreach element [array names configXML] {
    ::piLog::log [clock milliseconds] "info" "$element : $configXML($element)"
}


proc bgerror {message} {
    ::piLog::log [clock milliseconds] error_critic "bgerror in $::argv - pid [pid] -$message-"
}

# Load server
::piLog::log [clock millisecond] "info" "starting serveur"
::piServer::start messageGestion $port(serverMail)
::piLog::log [clock millisecond] "info" "serveur is started"

proc stopIt {} {
    ::piLog::log [clock milliseconds] "info" "Start stopping serverMail"
    set ::forever 0
    ::piLog::log [clock milliseconds] "info" "End stopping serverMail"
    
    # Arrêt du server de log
    ::piLog::closeLog
}

proc send_email {from to subject body} { 

    set token [mime::initialize -canonical "text/plain" -encoding "7bit" -string $body]
      mime::setheader $token Subject $subject
      smtp::sendmessage $token \
                    -servers [list $::configXML(serverSMTP)] -ports [list $::configXML(port)]\
                    -usetls true\
                    -debug true\
                    -username $::configXML(username) \
                    -password $::configXML(password) \
                    -queue false\
                    -atleastone true\
                    -header [list From $from] \
                    -header [list To $to] \
                    -header [list Subject $subject]\
                    -header [list Date "[clock format [clock seconds]]"]
      mime::finalize $token
} 


vwait forever

# tclsh "D:\CBX\cultipiCore\serverMail\serverMail.tcl" 6004 "D:\CBX\cultipiCore\serverMail\confExample\conf.xml" 6003 6000
# tclsh /opt/cultipi/serverMail/serverMail.tcl 6004 /etc/cultipi/01_defaultConf_RPi/./serverMail/conf.xml 6003 6000
