#!/usr/bin/env python
# -*- coding: utf-8 -*-

import socket, threading
from piLog import *
from piTools import *
from serveurMessage import *

class piServer():

    serverBulckypi =    6000
    serverLog =        6003
    serverPlugUpdate = 6004
    serverAcqSensor =  6006
    serverHisto =      6009
    serverIrrigation = 6011
    serverCultibox =   6013
    serverMail =       6015
    serverSupervision =6019
    serverGet =        6022
    serverGetCommand = 6023
    serverSet =        6024
    serverSetCommand = 6025
    serverTrigger =    6026
    serverPHP =        6027
    serverAcqSensorUSB =  6028
    debug = 1

    def __init__(self, moduleLocalName, verboseLevelName, host, port):
        
        # On sauvegarde les niveaux de traces
        self.moduleLocal = moduleLocalName
        self.verboseLevel = verboseLevelName
        
        # On initialise la communication avec le module de log
        self.lg = piLog()
        self.lg.openLog(piServer.serverLog, self.moduleLocal, self.verboseLevel)

        # On initialise le serveur
        self.tcpsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.tcpsock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        
        # On trace le lancement
        self.lg.log(clock_milliseconds(), "debug", "piServer Start server " + host + " : " + str(port))
        
        #print("piServer Start server " + host + " : " + str(port))
        self.tcpsock.bind((host,port))
        self.tcpsock.settimeout(0.1) 
        
    def listen(self):
    
        try:
    
            self.tcpsock.listen(4)
            #self.lg.log(clock_milliseconds(), "debug", "piServer Listening for incoming connections...")

            (clientsock, (ip, port)) = self.tcpsock.accept()

            #pass clientsock to the ClientThread thread object being created
            newthread = ClientThread(self.moduleLocal, self.verboseLevel, ip, port, clientsock)
            newthread.start()
        except Exception: 
            pass
            
    def sendToServer(portNumber, message, ip="localhost"):
    
        # Création de la connection
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        # Connexion vers le serveur
        s.connect((ip, portNumber))

        # Envoi de la donnée
        s.send(bytes(message, 'UTF-8'))

        # Fermeture de la connexion
        s.close()
        


class ClientThread(threading.Thread):

    def __init__(self, moduleLocalName, verboseLevelName ,ip ,port ,clientsocket):
    
        # On sauvegarde les niveaux de traces
        self.moduleLocal = moduleLocalName
        self.verboseLevel = verboseLevelName
        
        # On initialise la communication avec le module de log
        self.lg = piLog()
        self.lg.openLog(piServer.serverLog, self.moduleLocal, self.verboseLevel)

        # On initialise le module de réception des messages
        self.srvMsg = messageGestion(piServer.serverLog, self.moduleLocal, self.verboseLevel)
        
        threading.Thread.__init__(self)
        self.ip = ip
        self.host = ip
        self.port = port
        self.csocket = clientsocket

        self.lg.log(clock_milliseconds(), "debug", "ClientThread piServer Ouverture connexion par")

    def run(self):    
    
        self.lg.log(clock_milliseconds(), "debug", "ClientThread Connection from : "+self.ip+":"+str(self.port))
    
        data = self.csocket.recv(2048)
        self.lg.log(clock_milliseconds(), "debug", "ClientThread Client sent : " + data.decode())
        
        self.srvMsg.parseMsg(data.decode(),self.ip)

        self.lg.log(clock_milliseconds(), "debug", "ClientThread disconnected..." )

    
