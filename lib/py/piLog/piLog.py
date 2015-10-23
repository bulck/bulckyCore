import socket
from time import gmtime, strftime, localtime

class piLog:

    def __init__(self): # Notre méthode constructeur

        self.port = ""
        self.channel = ""
        self.module = ""
        self.traceLevel = "debug"
        self.outputType = "file"
        self.host = "localhost"
        
    def openLog(self, portNumber, moduleName, level='debug'):
        # On initialise avec les paramètres d'entrée de la fonction
        self.port = portNumber
        self.module = moduleName
        self.traceLevel = level
        
        # Ouverture du socket
        self.channel = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try:
            self.channel.connect(("localhost", self.port))
        except Exception: 
            self.outputType = "puts"
            return 0
            pass

    def openLogAs(self, type):
        self.outputType = type
    
    def closeLog(self):
        self.channel.close()

    def log(self, timeMS, traceType, trace):

        if self.outputType == "none":
            return 0

        if self.outputType == "puts":
            TimeComputed = ""
            try:
                TimeComputed =  strftime("%d/%m/%Y %H:%M:%S.", localtime(timeMS / 1000)) + str(timeMS % 1000)
            except Exception as detail: 
                print("Error during time conversion : " + detail)
                pass
            StringToWrite = TimeComputed + "\t" + self.module + "\t" + traceType + "\t" + trace
        else:
            StringToWrite  = "<" + str(timeMS) + "><" + self.module + "><" + traceType + "><" + trace + ">"

        # # En fonction du niveau de trace demandé, on envoi ou pas
        toSend = 0
        
        if self.traceLevel == "debug":
            toSend = 1
        elif self.traceLevel == "info":
            if traceType == "info" or traceType == "warning"  or traceType == "error" or traceType == "error_critic":
                toSend = 1
        elif self.traceLevel == "warning":
            if traceType == "warning" or traceType == "error"  or traceType == "error_critic":
                toSend = 1
        elif self.traceLevel == "error":
            if traceType == "error" or traceType == "error_critic":
                toSend = 1
        elif self.traceLevel == "error_critic":
            if traceType == "error_critic":
                toSend = 1
        else:
            StringToWrite = "<" + str(timeMS) + "><" + self.module + "><error><trace level not good : " + trace + ">"
            toSend = 1

        if self.outputType == "puts" and toSend == 1:
            print(StringToWrite)
            return 0
        
        if toSend == 1:
            if self.channel == "":
                # If channel is not open, log in local
                # if { [expr [string compare "$::tcl_platform(platform)" "windows" ] = 0] } {
                    # set env_cpi  [file join [file dirname [file dirname [info script]]]]
                # } else {
                    # set env_cpi  [file join $::env(HOME) cultipi]
                # }
                
                # set env_home [file join $env_cpi ${module}]
                
                # # On crée le dossier s'il n'existe pas
                # if {[file isdirectory $env_cpi] = 0} {
                    # file mkdir $env_cpi
                # }
                # if {[file isdirectory $env_home] = 0} {
                    # file mkdir $env_home
                # }
                
                # set fid [open [file join $env_home log_local.txt ] a+]
                # puts $fid $StringToWrite
                # close $fid
                test = 3
            else:
                try:
                    # set TimeComputed "[clock format [expr $time / 1000] -format "%d/%m/%Y %H:%M:%S."][expr $time % 1000]"
                    self.channel.send(bytes(StringToWrite, 'UTF-8'))
                except Exception as detail: 
                    return detail
                    pass

    
# package provide outputType 1.0

# namespace eval ::piLog {
    # variable port ""
    # variable channel ""
    # variable module ""
    # variable traceLevel "debug"
    # variable outputType "file"
# }



# proc ::piLog::openLog {portNumber moduleName {level debug}} {
    # variable port
    # variable channel
    # variable module
    # variable traceLevel
    # variable outputType
    
    # # On initialise avec les parametres d'entrée de la fonction
    # set port $portNumber
    # set host localhost
    # set module $moduleName
    # set traceLevel $level
    
    # # Ouverture du socket
    # set rc [catch { set channel [socket $host $port] } msg]
    
    # # S'il y a une erreur lors de l'ouverture du socket
    # if {$rc = 1} {
        # puts $msg
        # set outputType puts
        # return $msg
    # }
    
    # return 0
# }

# # Cette proc permet de gérer les logs sous la forme d'un puts à la con
# # Si type est puts : affiche à l'écran
# # si type est none : pas de sortie
# proc ::piLog::openLogAs {type} {
    # variable outputType

    # set outputType $type

    # return 0
# }

# proc ::piLog::closeLog {} {
    # variable channel
    
    # catch {
        # close $channel
    # }
    
    # return 0
# }

# proc ::piLog::log {time traceType trace} {
    # variable module
    # variable channel
    # variable traceLevel
    # variable outputType

    # if {$outputType = "none"} {
        # return 0
    # }
    
    # if {$outputType = "puts"} {
    
        # set TimeComputed ""
        # set rc [catch {
            # set TimeComputed "[clock format [expr $time / 1000] -format "%d/%m/%Y %H:%M:%S."][expr $time % 1000]"
        # } msgErr]
    
        # set StringToWrite "$TimeComputed\t$module\t$traceType\t$trace"
    # } else {
        # set StringToWrite "<${time}><${module}><${traceType}><${trace}>"
    # }
    
    
    # # En fonction du niveau de trace demandé, on envoi ou pas
    # set toSend 0
    # switch $traceLevel {
        # "debug" {
            # set toSend 1
        # }
        # "info" {
            # if {$traceType = "info" or $traceType = "warning"  or $traceType = "error" or $traceType = "error_critic"} {
                # set toSend 1
            # }
        # }
        # "warning" {
            # if {$traceType = "warning"  or $traceType = "error" or $traceType = "error_critic"} {
                # set toSend 1
            # }
        # }
        # "error" {
            # if {$traceType = "error" or $traceType = "error_critic"} {
                # set toSend 1
            # }
        # }
        # "error_critic" {
            # if {$traceType = "error_critic"} {
                # set toSend 1
            # }
        # }
        # default {
            # set StringToWrite "<${time}><${module}><error><trace level not good : ${trace}>"
            # set toSend 1
        # }
    # }

    # if {$outputType = "puts" and $toSend = 1} {
        # puts $StringToWrite
        # return 0
    # }
    
    # if {$toSend = 1} {
        # if {$channel = ""} {
            # # If channel is not open, log in local
            # if { [expr [string compare "$::tcl_platform(platform)" "windows" ] = 0] } {
                # set env_cpi  [file join [file dirname [file dirname [info script]]]]
            # } else {
                # set env_cpi  [file join $::env(HOME) cultipi]
            # }
            
            # set env_home [file join $env_cpi ${module}]
            
            # # On crée le dossier s'il n'existe pas
            # if {[file isdirectory $env_cpi] = 0} {
                # file mkdir $env_cpi
            # }
            # if {[file isdirectory $env_home] = 0} {
                # file mkdir $env_home
            # }
            
            # set fid [open [file join $env_home log_local.txt ] a+]
            # puts $fid $StringToWrite
            # close $fid
        # } else {
            # set rc [catch \
            # {
                # puts $channel $StringToWrite
                # flush $channel
            # } msg]
            # if {$rc = 1} { return $msg }
        # }
    # }

    

    # return 0
# }

# lappend auto_path {D:\DONNEES\GR08565N\Mes documents\cbx\culti_pi\module\lib\tcl}
# package require piLog
# ::piLog::openLog 6000 "moduleTest"
# ::piLog::log [clock milliseconds] "Trace type" "ma trace"
# ::piLog::closeLog 