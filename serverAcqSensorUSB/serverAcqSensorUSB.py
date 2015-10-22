#!/usr/bin/env python

# Load lib
import socket, threading, sys, os

# Lecture des arguments : seul le path du fichier XML est donné en argument
confXML = sys.argv[1]

moduleLocalName = "serverAcqSensorUSB"

# Chargement des librairies
libPath = os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(__file__))),"lib","py")
sys.path.append(os.path.join(libPath,"piServer"))
from piServer import *
sys.path.append(os.path.join(libPath,"piLog"))
from piLog import *
sys.path.append(os.path.join(libPath,"piTools"))
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

# Load server

class ClientThread(threading.Thread):

    def __init__(self,ip,port,clientsocket):
        threading.Thread.__init__(self)
        self.ip = ip
        self.port = port
        self.csocket = clientsocket
        print("[+] New thread started for "+ip+":"+str(port))

    def run(self):    
        print("Connection from : "+ip+":"+str(port))

        data = "dummydata"

        while len(data):
            data = self.csocket.recv(2048)
            print("Client(%s:%s) sent : %s"%(self.ip, str(self.port), data))

        print("Client at "+self.ip+" disconnected...")

host = "0.0.0.0"
port = 6028

tcpsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
tcpsock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

tcpsock.bind((host,port))

while True:
    tcpsock.listen(4)
    print("Listening for incoming connections...")
    (clientsock, (ip, port)) = tcpsock.accept()

    #pass clientsock to the ClientThread thread object being created
    newthread = ClientThread(ip, port, clientsock)
    newthread.start()
    
# py "D:\CBX\cultipiCore\serverAcqSensorUSB\serverAcqSensorUSB.py" "D:\CBX\cultipiCore\serverAcqSensorUSB\confExample\conf.xml"