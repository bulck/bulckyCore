#!/usr/bin/tclsh
 
# Init directory
set rootDir [file dirname [file dirname [info script]]]
set logDir $rootDir
set serverLogFileName [file join $rootDir serverLog serverLog.tcl]

puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : bulckyPi : Starting bulckyPi - PID : [pid]"
set TimeStartbulckyPi [clock milliseconds]

set fileName(bulckyPi,confRootDir) [lindex $argv 0]
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : bulckyPi : server : XML Conf directory : $fileName(bulckyPi,confRootDir)"
if {$fileName(bulckyPi,confRootDir) == ""} {
    puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : Error : conf directory must be defined"
    return
}
set fileName(bulckyPi,conf) [file join $fileName(bulckyPi,confRootDir) conf.xml]

# Load lib
lappend auto_path [file join $rootDir lib tcl]
package require piLog
package require piServer
package require piXML
package require piTools

# Source files
source [file join $rootDir bulckyPi src stop.tcl]
source [file join $rootDir bulckyPi src serveurMessage.tcl]
source [file join $rootDir bulckyPi src checkAlive.tcl]
source [file join $rootDir bulckyPi src checkI2C.tcl]


# Initialisation de la variable status
set ::statusInitialisation "starting"

# Initialisation d'un compteur pour les commandes externes envoyées
set TrameIndex 0

# Chargement du fichier qui donne la configuration
set fileName(bulckyPi,confDir) [file join $fileName(bulckyPi,confRootDir) [lindex [::piXML::open_xml $fileName(bulckyPi,conf)] 2 0 1 1]]
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : conf : conf to start is $fileName(bulckyPi,confDir) - File exists ? [file exists $fileName(bulckyPi,confDir)]"

# Load bulckyPi configuration
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : start.xml file : [file join $fileName(bulckyPi,confDir) bulckyPi start.xml]"
set confStart(start) [lindex [::piXML::open_xml [file join $fileName(bulckyPi,confDir) bulckyPi start.xml]] 2]

# On initialise les variables
foreach moduleXML $::confStart(start) {
    set moduleName [::piXML::searchOptionInElement name $moduleXML]
    set ::confStart(${moduleName},pid) ""
    set ::confStart(${moduleName},pipeID) ""
    puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : Slave to start : $moduleName"
}

# Load server BulckyPi 
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : Load server" ; update
::piServer::start messageGestion $::piServer::portNumber(serverBulckypi)

# Load serverLog
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : Starting serverLog"
set ::statusInitialisation "loading_serverLog"
set confStart(serverLog,pid) ""
set confStart(serverLog) [::piXML::searchItemByName serverLog $confStart(start)]
set confStart(serverLog,pathexe) [::piXML::searchOptionInElement pathexe $confStart(serverLog)]
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : serverLog pathexe : $confStart(serverLog,pathexe)"
# Le string map permet de prendre en compte le changement de path
set confStart(serverLog,path) [string map {"serveur" "server"} [file join $rootDir [::piXML::searchOptionInElement path $confStart(serverLog)]]]
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : serverLog path : $confStart(serverLog,path)"
set confStart(serverLog,xmlconf) [file join $fileName(bulckyPi,confDir) [::piXML::searchOptionInElement xmlconf $confStart(serverLog)]]
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : serverLog xmlconf : $confStart(serverLog,xmlconf) , file exists ? [file exists $confStart(serverLog,xmlconf)]"
set confStart(serverLog,waitAfterUS) [::piXML::searchOptionInElement waitAfterUS $confStart(serverLog)]
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : serverLog waitAfterUS : $confStart(serverLog,waitAfterUS)"
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : serverLog port : $::piServer::portNumber(serverLog)"
set TimeStartserverLog [clock milliseconds]
#open "| tclsh \"$serverLogFileName\" $::piServer::portNumber(serverLog) \"$logDir\""
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : serverLog : $confStart(serverLog,pathexe) \"$confStart(serverLog,path)\" \"$confStart(serverLog,xmlconf)\""

set confStart(serverLog,pipeID) [open "| $confStart(serverLog,pathexe) \"$confStart(serverLog,path)\" \"$confStart(serverLog,xmlconf)\""]
after $confStart(serverLog,waitAfterUS) 
update

# init log
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : Open log" ; update
set ::statusInitialisation "init_log"
::piLog::openLog $::piServer::portNumber(serverLog) "bulckypi"
::piLog::log $TimeStartbulckyPi "info" "starting serveur"
::piLog::log $TimeStartserverLog "info" "starting serverLog"
::piLog::log $TimeStartserverLog "info" "Port : $::piServer::portNumber(serverBulckypi)"

# On démarre les esclaves
restartSlave puts


# On attend que la date soit correcte
proc checkDate {} {
    if {[clock seconds] > 1419700000} {
        set ::dateIsCorrect 1
    } else {
        puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : Date is not correct ([clock seconds] under 1419700000) , waiting ..."; update
        ::piLog::log [clock millisecond] "info" "Date is not correct, waiting ..."
        after 1000 checkDate
        update
    }
}

set ::statusInitialisation "checking_date"
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : Check date" ; update
after 200 checkDate ; update
vwait dateIsCorrect
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : Date is OK, continue" ; update

# Lancement de tous les modules
foreach moduleXML $::confStart(start) {
    set moduleName [::piXML::searchOptionInElement name $moduleXML]
    if {$moduleName != "serverLog"} {
        set ::confStart(${moduleName},pathexe) [::piXML::searchOptionInElement pathexe $moduleXML]
        puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : $moduleName pathexe : $::confStart(${moduleName},pathexe)"
        set ::confStart($moduleName,path) [file join $rootDir [::piXML::searchOptionInElement path $moduleXML]]
        puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : $moduleName path : $::confStart($moduleName,path)"
        set ::confStart($moduleName,xmlconf) [file join $fileName(bulckyPi,confDir) [::piXML::searchOptionInElement xmlconf $moduleXML]]
        puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : $moduleName xmlconf : $::confStart($moduleName,xmlconf) , file exists ? [file exists $::confStart($moduleName,xmlconf)]"
        set ::confStart($moduleName,waitAfterUS) [::piXML::searchOptionInElement waitAfterUS $moduleXML]
        puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : $moduleName waitAfterUS : $::confStart($moduleName,waitAfterUS)"
        puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : $moduleName port : $::piServer::portNumber($moduleName)"

        ::piLog::log [clock milliseconds] "info" "Load $moduleName"
        puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : start : $moduleName exec : $::confStart($moduleName,pathexe) \"$::confStart($moduleName,path)\" \"$::confStart($moduleName,xmlconf)\""
        set ::confStart($moduleName,pipeID) [open "| $::confStart($moduleName,pathexe) \"$::confStart($moduleName,path)\" \"$::confStart($moduleName,xmlconf)\""]
        
        set ::statusInitialisation "loading_${moduleName}"
        
        after $::confStart($moduleName,waitAfterUS)
        update
    }
}

# On attend que tous les modules ait démarré
proc askPid {} {
    foreach moduleXML $::confStart(start) {
        set moduleName [::piXML::searchOptionInElement name $moduleXML]
        if {$moduleName != "serverLog"} {
            # on lui demande son PID
            # Trame standard : [FROM] [INDEX] [commande] [argument]
            ::piServer::sendToServer $::piServer::portNumber($moduleName) "$::piServer::portNumber(serverBulckypi) [incr ::TrameIndex] pid"
        }
    }
}
after 5000 askPid
update

proc updateRepere {} {

    # pour chaque repère, on met à jour la valeur dans le serveur

    
    after 1000 updateRepere

}

updateRepere

set ::statusInitialisation "initialized"
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : BulckyPi : started"

vwait ::forever

# tclsh "D:\CBX\06_bulckyCore\bulckyPi\bulckyPi.tcl" "D:\CBX\06_bulckyCore\_conf"

# Linux start
# tclsh /home/pi/bulckypi/01_Software/01_bulckyPi/bulckyPi/bulckyPi.tcl /home/pi/bulckypi/02_conf
# tclsh /opt/bulckypi/bulckyPi/bulckyPi.tcl /etc/bulckypi
# tclsh /opt/bulckypi/bulckyPi/bulckyPi.tcl /etc/bulckypi
