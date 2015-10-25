#!/usr/bin/env python
# -*- coding: utf-8 -*-

import usb.core
import usb.util
import uuid , time
from threading import Timer
from piLog import *

# dev = usb.core.find(find_all=True)
# for cfg in dev:
  # print('Decimal VendorID=' + str(cfg.idVendor) + ' & ProductID=' + str(cfg.idProduct) + '\n')
  # print('Hexadecimal VendorID=' + hex(cfg.idVendor) + ' & ProductID=' + hex(cfg.idProduct) + '\n\n')


# print("All right")


class sensor_T_RH(object):
    
    VendorID = 0x4d8
    ProductID = 0x3f
    
    def __init__(self, dev):
        #dev = usb.core.find(idVendor=sensor_T_RH.VendorID, idProduct=sensor_T_RH.ProductID)
        
        #if dev is None:
        #    return None
            
        dev.set_configuration()
        
        cfg = dev.get_active_configuration()
        intf = cfg[(0,0)]

        ep = usb.util.find_descriptor(
            intf,
            # match the first OUT endpoint
            custom_match = \
            lambda e: \
                usb.util.endpoint_direction(e.bEndpointAddress) == \
                usb.util.ENDPOINT_OUT)

        self.ep_out = usb.util.find_descriptor(
                intf,   # first interface
                # match the first OUT endpoint
                custom_match = \
                    lambda e: \
                        usb.util.endpoint_direction(e.bEndpointAddress) == \
                        usb.util.ENDPOINT_OUT
            )

        self.ep_in = usb.util.find_descriptor(
                intf,   # first interface
                # match the first IN endpoint
                custom_match = \
                    lambda e: \
                        usb.util.endpoint_direction(e.bEndpointAddress) == \
                        usb.util.ENDPOINT_IN
            )

                
        assert self.ep_out is not None

    def getTemp(self) :
        return self.temperature

    def getHumi(self) :
        return self.humidity
        
    def getUUID(self) :
        return self.UUID
        
    def readSensor(self) :
    
        try :
            self.ep_out.write([0x01])
            ret = self.ep_in.read(64)
            self.temperature = (ret[1] + ret[2] * 256)/100
            self.humidity    = (ret[3] + ret[4] * 256)/100
            #print("temperature : " + str(self.temperature))
            #print("humidity : " + str(self.humidity))
        except:
            print("Erreur a la readSensor")

    def checkUUID(self) :
        """ Vérification de l'UUID de la clé 
        """
        try :
            self.ep_out.write([0x02])
            ret = self.ep_in.read(64)
        except:
            print("Erreur a la checkUUID")
        fail = 0
        for index in range(1,32):
            if len(str(ret[index])) != 1:
                fail = 1
                break
        if fail == 1 :
            print("not valid UUID")
            # Create a new UUID and send it 
            uu = str(uuid.uuid1()).replace("-", "")
            print("New UUID:" + uu + str(len(uu)))
            
            # Add 2 and W 
            #uu = "2W" + uu + "000000000000000000000000000000"
            #self.ep_out.write(uu)
            
        else :
            print("valid UUID")
        
    def readUUID(self) :
    
        try :
            self.ep_out.write([0x02])
            ret = self.ep_in.read(64)
        except:
            print("Erreur a la readUUID")
        sret = ''.join([str(x) for x in ret])
        #print(sret)
        self.UUID = ""
        for num in range(1,8):
            self.UUID = self.UUID + hex(ret[num])[2:]
        self.UUID = self.UUID + "-"
        for num in range(9,12):
            self.UUID = self.UUID + hex(ret[num])[2:]
        self.UUID = self.UUID + "-"
        for num in range(13,16):
            self.UUID = self.UUID + hex(ret[num])[2:]
        self.UUID = self.UUID + "-"
        for num in range(17,20):
            self.UUID = self.UUID + hex(ret[num])[2:]
        self.UUID = self.UUID + "-"
        for num in range(21,32):
            self.UUID = self.UUID + hex(ret[num])[2:]


#test = sensor_T_RH()
#test.readSensor()
#test.readUUID()
#test.checkUUID()
#test.readUUID()

#print ("getTemp : " + str(test.getTemp()))
#print ("getUUID : " + test.getUUID())

class sensor:

    #VendorID=0x4d8 & ProductID=0x3f
    sensorList = {}
    sensorListType = {}

    def __init__(self, moduleLocalName, verboseLevelName, serverLogIndex):
    
        # On sauvegarde les niveaux de traces
        self.moduleLocal = moduleLocalName
        self.verboseLevel = verboseLevelName
        self.serverLog = serverLogIndex
        
        # On initialise la communication avec le module de log
        self.lg = piLog()
        self.lg.openLog(self.serverLog, self.moduleLocal, self.verboseLevel)
        
        # On cherche tous les capteurs disponible
        dev = usb.core.find(idVendor=sensor_T_RH.VendorID, idProduct=sensor_T_RH.ProductID)
        
        if dev != None:
            # Pour chaque capteur 
            sensor.sensorListType[0] = "TRH"
            sensor.sensorList[0] = sensor_T_RH(dev)
            
            # On initialise la lecture
            sensor.sensorList[0].readSensor()
            
            # On vérifie l'UUID
            sensor.sensorList[0].checkUUID()
            
            # On l'enregistre
            sensor.sensorList[0].readUUID()
            
            
    def readSensor(self, sensorIndex):
        sensor.sensorList[sensorIndex].readSensor()

    def getTemp(self, sensorIndex):
        return sensor.sensorList[sensorIndex].getTemp()
    
            

        
        
        
        
        
        
        

