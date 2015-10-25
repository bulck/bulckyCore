#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
from piTools import *
from piLog import *
from piServer import *

class messageGestion:

    def __init__(self, serverLogIndex, moduleLocalName, verboseLevelName):
        # On sauvegarde les niveaux de traces
        self.moduleLocal = moduleLocalName
        self.verboseLevel = verboseLevelName
        self.serverLog = serverLogIndex
        
        # On initialise la communication avec le module de log
        self.lg = piLog()
        self.lg.openLog(self.serverLog, self.moduleLocal, self.verboseLevel)
    
    def parseMsg(self, message, networkhost):
        # Trame standard : [FROM] [INDEX] [commande] [argument]
        messageList = message.split(' ') 
        
        serverForResponse  = messageList[0]
        indexForResponse   = messageList[1]
        commande           = messageList[2]
        
        self.lg.log(clock_milliseconds(), "debug", "parseMsg message a parser " + message)
        
        if commande == "stop" :
            self.lg.log(clock_milliseconds(), "info", "Asked stop")
            os._exit(0)
        elif commande == "pid" :
            # On initialise l'objet
            piSrv = piServer()
            
            # On envoi la commande
            piSrv.sendToServer(serverForResponse, str(os.getpid()), networkhost)
            
        elif commande == "reloadXML" :
            piSrv.sendToServer(serverForResponse, str(os.getpid()), networkhost)
        elif commande == "getRepere" :
        
            self.lg.log(clock_milliseconds(), "debug", "parseMsg Asked getRepere : " + message)
            
            for index in range(3, len(messageList))
                self.lg.log(clock_milliseconds(), "debug", "parseMsg Asked variable : " + messageList[index])
                if messageList[index].find("sensor(") != -1 :
                    # On demande la valeur d'un capteur 
                    msgSplitted = messageList[index].replace('(',' ').replace(')',' ').replace(',',' ').split()
                    
                    sensorIndex = msgSplitted[0]
                    
                    
        
            piSrv.sendToServer(serverForResponse, str(os.getpid()), networkhost)
        elif commande == "setRepere" :
            piSrv.sendToServer(serverForResponse, str(os.getpid()), networkhost)
        else:
            self.lg.log(clock_milliseconds(), "error", "Command" + commande + "non reconnue")


    
    # switch ${commande} {
        # "stop" {
            # ::piLog::log [clock milliseconds] "info" "Asked stop"
            # stopIt
        # }
        # "pid" {
            # ::piLog::log [clock milliseconds] "info" "Asked pid"
            # ::piServer::sendToServer $serverForResponse "$::piServer::portNumber(${::moduleLocalName}) $indexForResponse _pid ${::moduleLocalName} [pid]" $networkhost
        # }
        # "reloadXML" {
            # ::piLog::log [clock milliseconds] "info" "messageGestion : Asked reloadXML"
            # set RC [catch {
                # array set ::configXML [::piXML::convertXMLToArray $::confXML]
            # } msg]
            # if {$RC != 0} {
                # ::piLog::log [clock milliseconds] "error" "messageGestion : Asked reloadXML error : $msg"
            # } else {
                # # On affiche les infos dans le fichier de debug
                # foreach element [lsort [array names ::configXML]] {
                    # ::piLog::log [clock milliseconds] "info" "$element : $::configXML($element)"
                # }
            # }
        # }
        # "getRepere" {
        
            # # Pour toutes les variables demand�es
            # set indexVar 3
            # set returnList ""
            # while {[set variable [::piTools::lindexRobust $message $indexVar]] != ""} {
                # # La variable est le nom de la variable � lire
                
                # ::piLog::log [clock milliseconds] "info" "Asked getRepere $variable by $networkhost"
                
                # if {[info exists ::$variable] == 1} {
                
                    # eval set returnValue $$variable
                    
                    # # Condition particuliere : pour les regroupement de variable, on met DEFCOM si null
                    # if {$variable == "::sensor(1,value)" || 
                        # $variable == "::sensor(2,value)"  ||
                        # $variable == "::sensor(3,value)"  ||
                        # $variable == "::sensor(4,value)"  ||
                        # $variable == "::sensor(5,value)"  ||
                        # $variable == "::sensor(6,value)" } {
                        # if {$returnValue == ""} {
                            # set returnValue "DEFCOM"
                        # }
                    # }
                    
                    # lappend returnList $returnValue
                # } else {
                    # ::piLog::log [clock milliseconds] "error" "Asked variable $variable by $networkhost - variable doesnot exists"
                # }
                
                # incr indexVar
            # }

            # ::piLog::log [clock milliseconds] "info" "response : $serverForResponse $indexForResponse _getRepere - $returnList - to $networkhost"
            # ::piServer::sendToServer $serverForResponse "$serverForResponse $indexForResponse _getRepere $returnList" $networkhost

        # }
        # "setRepere" {
            # set variable [::piTools::lindexRobust $message 3]
            # set value [::piTools::lindexRobust $message 4]
            
            # set ::${variable} $value

            # ::piLog::log [clock milliseconds] "info" "Asked setRepere : force $variable to $value"
        # }
        # "subscription" {
            # # Le rep�re est l'index des capteurs
            # set repere [::piTools::lindexRobust $message 3]
            # set frequency [::piTools::lindexRobust $message 4]
            # if {$frequency == 0} {set frequency 1000}
            # set BandeMorteAcquisition [::piTools::lindexRobust $message 5]
            # if {$BandeMorteAcquisition == ""} {set BandeMorteAcquisition 0}
            
            # ::piLog::log [clock milliseconds] "info" "Subscription of $repere by $serverForResponse frequency $frequency ms BMA $BandeMorteAcquisition"

            # set ::subscriptionVariable($::SubscriptionIndex) ""
            
            # # On cr� la proc associ�e
            # proc subscription${::SubscriptionIndex} {repere frequency SubscriptionIndex serverForResponse BandeMorteAcquisition networkhost} {
                # set reponse $::sensor($repere)
                # if {$reponse == ""} {
                    # set reponse "DEFCOM"
                # }
                
                # set time [clock milliseconds]
                # if {[array name ::sensor -exact $repere,time] != ""} {
                    # set time    $::sensor($repere,time)
                # }
            
                # # On envoi la nouvelle valeur uniquement si la valeur a chang�e
                # if {$::subscriptionVariable($SubscriptionIndex) != $reponse} {
                
                    # # Dans le cas d'un double, on v�rifie la bande morte
                    # if {[string is double $reponse] == 1} {
                        # # R�ponse doit �tre > � l'ancienne valeur + BMA ou < � l'ancienne valeur - BMA
                        # set oldValue $::subscriptionVariable($SubscriptionIndex)
                        # if {[string is double $oldValue] != 1} {
                            # set oldValue -100
                        # }
                        # if {$reponse >= [expr $oldValue + $BandeMorteAcquisition] || $reponse <= [expr $oldValue - $BandeMorteAcquisition]} {
                            # ::piServer::sendToServer $serverForResponse "$serverForResponse [incr ::TrameIndex] _subscription ::sensor($repere) $reponse $time" $networkhost
                            # set ::subscriptionVariable($SubscriptionIndex) $reponse
                        # } else {
                            # ::piLog::log [clock milliseconds] "debug" "Doesnot send ::sensor($repere) besause it's between BMA $reponse sup [expr $oldValue + $BandeMorteAcquisition] OR $reponse inf [expr $oldValue - $BandeMorteAcquisition]"
                        # }
                        
                    # } else {
                        # ::piServer::sendToServer $serverForResponse "$serverForResponse [incr ::TrameIndex] _subscription ::sensor($repere) $reponse $time" $networkhost
                        # set ::subscriptionVariable($SubscriptionIndex) $reponse
                        # ::piLog::log [clock milliseconds] "debug" "Response is not a double _subscription ::sensor($repere) reponse : $reponse - to $serverForResponse"
                    # }
                # } else {
                    # #::piLog::log [clock milliseconds] "debug" "Doesnot resend ::sensor($repere) besause it's same value -$reponse-"
                # }
                
                # after $frequency "subscription${SubscriptionIndex} $repere $frequency $SubscriptionIndex $serverForResponse $BandeMorteAcquisition $networkhost"
            # }
            
            # # on la lance
            # subscription${::SubscriptionIndex} $repere $frequency $::SubscriptionIndex $serverForResponse $BandeMorteAcquisition $networkhost
            
            # incr ::SubscriptionIndex
        # }
        # "_subscription" -
        # "_subscriptionEvenement" {
            # # On parse le retour de la commande
            # set variable    [::piTools::lindexRobust $message 3]
            # set valeur      [::piTools::lindexRobust $message 4]
            # set time        [::piTools::lindexRobust $message 5]
            
            # # On enregistre le retour de l'abonnement
            # set ${variable} $valeur

            # # On traite imm�diatement cette info
            # set splitted [split ${variable} "(,)"]
            # set variableName [lindex $splitted 0]
            # set networkSensor [lindex $splitted 1]
            
            # # On analyse pour savoir quelle capteur en local �a correspond
            # set localSensor [::network_read::getSensor $networkhost $networkSensor]
            # if {$localSensor == "NA"} {
                # return
            # }
            
            # switch $variableName {
                # "::sensor" {
                    # switch [lindex $splitted 2] {
                        # "type" {
                            # # Si c'est le type de capteur
                            # ::piLog::log [clock milliseconds] "debug" "_subscription response : save sensor type (local sensor $localSensor ): $message"
                            # set ::sensor($localSensor,type) $valeur
                        # }
                        # "value" {
                            # set valeur1      [::piTools::lindexRobust $message 4]
                            # set valeur2      [::piTools::lindexRobust $message 5]
                            # set time         [::piTools::lindexRobust $message 6]
                            # # Si c'est la valeur
                            # # ::piLog::log [clock milliseconds] "debug" "_subscription response : save sensor value : $message - [lindex $splitted 1] $valeur1 $valeur2 $time"
                            # if {$valeur1 == "DEFCOM"} {
                                # ::piLog::log [clock milliseconds] "warning" "_subscription response : save sensor value : DEFCOM so not saved - msg : $message"
                            # } else {
                                # set ::sensor($localSensor,value,1) $valeur1
                                # set ::sensor($localSensor,value)   $valeur1
                                # set ::sensor($localSensor,value,time) $time
                            # }
                            
                        # } 
                        # default {
                            # ::piLog::log [clock milliseconds] "error" "_subscription response : not rekognize type [lindex $splitted 2]  - msg : $message"
                        # }
                    # }
                # }
                # "::plug" {
                # }
                # default {
                    # ::piLog::log [clock milliseconds] "error" "_subscription response : unknow variable name $variableName - msg : $message"
                # }
            # }

            # # ::piLog::log [clock milliseconds] "debug" "subscription response : variable $variable valeur -$valeur-"
        # }
        # default {
            # # Si on re�oit le retour d'une commande, le nom du serveur est le notre
            # if {$serverForResponse == $::piServer::portNumber(${::moduleLocalName})} {
            
                # if {[array names ::TrameSended -exact $indexForResponse] != ""} {
                    
                    # switch [lindex $::TrameSended($indexForResponse) 0] {
                        # default {
                            # ::piLog::log [clock milliseconds] "error" "Not recognize keyword response -${message}-"
                        # }                    
                    # }
                    
                # } else {
                    # ::piLog::log [clock milliseconds] "error" "Not requested response -${message}-"
                # }
            
                
            # } else {
                # ::piLog::log [clock milliseconds] "error" "Received -${message}- but not interpreted"
            # }
        # }
    # }
# }
