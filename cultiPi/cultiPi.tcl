#!/usr/bin/tclsh
 
# Init directory
set rootDir [file dirname [file dirname [info script]]]
set logDir $rootDir
set serverLogFileName [file join $rootDir serverLog serverLog.tcl]

puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : cultiPi : Starting cultiPi - PID : [pid]"
set TimeStartcultiPi [clock milliseconds]

set fileName(cultiPi,confRootDir) [lindex $argv 0]
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : cultiPi : server : XML Conf directory : $fileName(cultiPi,confRootDir)"
if {$fileName(cultiPi,confRootDir) == ""} {
    puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : Error : conf directory must be defined"
    return
}
set fileName(cultiPi,conf) [file join $fileName(cultiPi,confRootDir) conf.xml]

# Load lib
lappend auto_path [file join $rootDir lib tcl]
package require piLog
package require piServer
package require piXML
package require piTools

# Source files
source [file join $rootDir cultiPi src stop.tcl]
source [file join $rootDir cultiPi src serveurMessage.tcl]
source [file join $rootDir cultiPi src checkAlive.tcl]
source [file join $rootDir cultiPi src checkI2C.tcl]


# Initialisation de la variable status
set ::statusInitialisation "starting"

# Initialisation d'un compteur pour les commandes externes envoyées
set TrameIndex 0

# Chargement du fichier qui donne la configuration
set fileName(cultiPi,confDir) [file join $fileName(cultiPi,confRootDir) [lindex [::piXML::open_xml $fileName(cultiPi,conf)] 2 0 1 1]]
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : conf : conf to start is $fileName(cultiPi,confDir) - File exists ? [file exists $fileName(cultiPi,confDir)]"

# Load cultiPi configuration
set confStart(start) [lindex [::piXML::open_xml [file join $fileName(cultiPi,confDir) cultiPi start.xml]] 2]

# On initialise les variables
foreach moduleXML $::confStart(start) {
    set moduleName [::piXML::searchOptionInElement name $moduleXML]
    set ::confStart(${moduleName},pid) ""
}

# Load server Culti Pi
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : start : Load server" ; update
::piServer::start messageGestion $::piServer::portNumber(serverCultipi)

# Load serverLog
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : start : Starting serverLog"
set ::statusInitialisation "loading_serverLog"
set confStart(serverLog,pid) ""
set confStart(serverLog) [::piXML::searchItemByName serverLog $confStart(start)]
set confStart(serverLog,pathexe) [::piXML::searchOptionInElement pathexe $confStart(serverLog)]
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : start : serverLog pathexe : $confStart(serverLog,pathexe)"
set confStart(serverLog,path) [file join $rootDir [::piXML::searchOptionInElement path $confStart(serverLog)]]
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : start : serverLog path : $confStart(serverLog,path)"
set confStart(serverLog,xmlconf) [file join $fileName(cultiPi,confDir) [::piXML::searchOptionInElement xmlconf $confStart(serverLog)]]
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : start : serverLog xmlconf : $confStart(serverLog,xmlconf) , file exists ? [file exists $confStart(serverLog,xmlconf)]"
set confStart(serverLog,waitAfterUS) [::piXML::searchOptionInElement waitAfterUS $confStart(serverLog)]
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : start : serverLog waitAfterUS : $confStart(serverLog,waitAfterUS)"
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : start : serverLog port : $::piServer::portNumber(serverLog)"
set TimeStartserverLog [clock milliseconds]
#open "| tclsh \"$serverLogFileName\" $::piServer::portNumber(serverLog) \"$logDir\""
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : start : serverLog : $confStart(serverLog,pathexe) \"$confStart(serverLog,path)\" \"$confStart(serverLog,xmlconf)\""

set confStart(serverLog,pipeID) [open "| $confStart(serverLog,pathexe) \"$confStart(serverLog,path)\" \"$confStart(serverLog,xmlconf)\""]
after $confStart(serverLog,waitAfterUS) 
update

# init log
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : start : Open log" ; update
set ::statusInitialisation "init_log"
::piLog::openLog $::piServer::portNumber(serverLog) "culipi"
::piLog::log $TimeStartcultiPi "info" "starting serveur"
::piLog::log $TimeStartserverLog "info" "starting serverLog"
::piLog::log $TimeStartserverLog "info" "Port : $::piServer::portNumber(serverCultipi)"

# On démarre les esclaves
restartSlave puts


# On attend que la date soit correcte
proc checkDate {} {
    if {[clock seconds] > 1419700000} {
        set ::dateIsCorrect 1
    } else {
        puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : start : Date is not correct ([clock seconds] under 1419700000) , waiting ..."; update
        ::piLog::log [clock millisecond] "info" "Date is not correct, waiting ..."
        after 1000 checkDate
        update
    }
}

set ::statusInitialisation "checking_date"
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : start : Check date" ; update
after 200 checkDate ; update
vwait dateIsCorrect
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : start : Date is OK, continue" ; update

# Lancement de tous les modules
foreach moduleXML $::confStart(start) {
    set moduleName [::piXML::searchOptionInElement name $moduleXML]
    if {$moduleName != "serverLog"} {
        set ::confStart(${moduleName},pathexe) [::piXML::searchOptionInElement pathexe $moduleXML]
        puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : start : $moduleName pathexe : $::confStart(${moduleName},pathexe)"
        set ::confStart($moduleName,path) [file join $rootDir [::piXML::searchOptionInElement path $moduleXML]]
        puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : start : $moduleName path : $::confStart($moduleName,path)"
        set ::confStart($moduleName,xmlconf) [file join $fileName(cultiPi,confDir) [::piXML::searchOptionInElement xmlconf $moduleXML]]
        puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : start : $moduleName xmlconf : $::confStart($moduleName,xmlconf) , file exists ? [file exists $::confStart($moduleName,xmlconf)]"
        set ::confStart($moduleName,waitAfterUS) [::piXML::searchOptionInElement waitAfterUS $moduleXML]
        puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : start : $moduleName waitAfterUS : $::confStart($moduleName,waitAfterUS)"
        puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : start : $moduleName port : $::piServer::portNumber($moduleName)"

        ::piLog::log [clock milliseconds] "info" "Load $moduleName"
        puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : start : $moduleName exec : $::confStart($moduleName,pathexe) \"$::confStart($moduleName,path)\" \"$::confStart($moduleName,xmlconf)\""
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
            ::piServer::sendToServer $::piServer::portNumber($moduleName) "$::piServer::portNumber(serverCultipi) [incr ::TrameIndex] pid"
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
puts "[clock format [clock seconds] -format "%b %d %H:%M:%S"] : CultiPi : started"

vwait ::forever

# tclsh "D:\CBX\cultipiCore\cultiPi\cultiPi.tcl" "D:\CBX\cultipiCore\_conf"

# Linux start
# tclsh /home/pi/cultipi/01_Software/01_cultiPi/cultiPi/cultiPi.tcl /home/pi/cultipi/02_conf
# tclsh /opt/cultipi/cultiPi/cultiPi.tcl /etc/cultipi