#!/usr/bin/env python

# Load lib
import socket, threading, sys, os

# Lecture des arguments : seul le path du fichier XML est donné en argument
confXML = sys.argv[1]

moduleLocalName = "serverAcqSensorUSB"

# Chargement des librairies
libPath = os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(__file__))),"lib","py")
sys.path.append(os.path.join(libPath,"piServer"))
sys.path.append(os.path.join(libPath,"piLog"))
sys.path.append(os.path.join(libPath,"piTools"))
from piServer import *
from piLog import *
from piTools import *

# On initialise la conf XML
class configXML :
    verbose = "debug"

# Chargement de la conf XML

# On initialise la connexion avec le server de log
lg = piLog()
lg.openLog(piServer.serverLog, moduleLocalName, configXML.verbose)
lg.log(clock_milliseconds(), "info", "starting " + moduleLocalName + " - PID : " + str(os.getpid()))
lg.log(clock_milliseconds(), "info", "port " + moduleLocalName + " : ") #$::piServer::portNumber(${::moduleLocalName})"
lg.log(clock_milliseconds(), "info", "confXML : ") #$confXML")

# On affiche les infos dans le fichier de debug
for element in [attr for attr in dir(configXML()) if not callable(attr) and not attr.startswith("__")]:
    lg.log(clock_milliseconds(), "info", element + " : " + getattr(configXML,element)) 

# Démarrage du serveur
lg.log(clock_milliseconds(), "info", "starting serveur")

piServ = piServer( moduleLocalName, configXML.verbose, "0.0.0.0", piServer.serverAcqSensorUSB)


while True:

    # On écoute si un client veut se connecter
    piServ.listen()

    
# py "D:\CBX\cultipiCore\serverAcqSensorUSB\serverAcqSensorUSB.py" "D:\CBX\cultipiCore\serverAcqSensorUSB\confExample\conf.xml"