
# Module 0
# Init : /usr/local/sbin/i2cset -y 1 0x20 0x00 0x00
# Pilotage pin0 : /usr/local/sbin/i2cset -y 1 0x20 0x09 0x01

namespace eval ::PCA9685 {
    variable adresse_module
    variable adresse_I2C
    variable register
    variable outputReversed
    
    # @0x40 cultibox : 0x80
    set adresse_module(31) 0x40
    set adresse_module(31,out) 0
    set adresse_module(32) 0x40
    set adresse_module(32,out) 1
    set adresse_module(33) 0x40
    set adresse_module(33,out) 2
    set adresse_module(34) 0x40
    set adresse_module(34,out) 3
    set adresse_module(35) 0x40
    set adresse_module(35,out) 4
    set adresse_module(36) 0x40
    set adresse_module(36,out) 5
    set adresse_module(37) 0x40
    set adresse_module(37,out) 6
    set adresse_module(38) 0x40
    set adresse_module(38,out) 7
    
    # @0x41 cultibox : 0x82
    set adresse_module(39) 0x41
    set adresse_module(39,out) 0
    set adresse_module(40) 0x41
    set adresse_module(40,out) 1
    set adresse_module(41) 0x41
    set adresse_module(41,out) 2
    set adresse_module(42) 0x41
    set adresse_module(42,out) 3
    set adresse_module(43) 0x41
    set adresse_module(43,out) 4
    set adresse_module(44) 0x41
    set adresse_module(44,out) 5

    # @0x42 cultibox : 0x84
    set adresse_module(45) 0x42
    set adresse_module(45,out) 0
    set adresse_module(46) 0x42
    set adresse_module(46,out) 1
    set adresse_module(47) 0x42
    set adresse_module(47,out) 2
    set adresse_module(48) 0x42
    set adresse_module(48,out) 3
    set adresse_module(49) 0x42
    set adresse_module(49,out) 4
#    set adresse_module(48) 0x42
#    set adresse_module(48,out) 5

    # Adresse des modules
    set adresse_I2C(0) 0x40
    set adresse_I2C(1) 0x41
    set adresse_I2C(2) 0x42
    
    # Définition des registres
    set register(MODE1)     0x00  ; #read/write Mode register 1     
    set register(MODE2)     0x01  ; #read/write Mode register 2     
    set register(SUBADR1)     0x02  ; #read/write I2C-bus subaddress 1     
    set register(SUBADR2)     0x03  ; #read/write I2C-bus subaddress 2     
    set register(SUBADR3)     0x04  ; #read/write I2C-bus subaddress 3     
    set register(ALLCALLADR)     0x05  ; #read/write LED All Call I2C-bus address   
    set register(LED0_ON_L)     0x06  ; #read/write LED0 output and brightness control byte 0 
    set register(LED0_ON_H)     0x07  ; #read/write LED0 output and brightness control byte 1 
    set register(LED0_OFF_L)     0x08  ; #read/write LED0 output and brightness control byte 2 
    set register(LED0_OFF_H)     0x09  ; #read/write LED0 output and brightness control byte 3 
    set register(LED1_ON_L)     0x0A  ; #read/write LED1 output and brightness control byte 0 
    set register(LED1_ON_H)     0x0B  ; #read/write LED1 output and brightness control byte 1 
    set register(LED1_OFF_L)     0x0C  ; #read/write LED1 output and brightness control byte 2 
    set register(LED1_OFF_H)     0x0D  ; #read/write LED1 output and brightness control byte 3 
    set register(LED2_ON_L)     0x0E  ; #read/write LED2 output and brightness control byte 0 
    set register(LED2_ON_H)     0x0F  ; #read/write LED2 output and brightness control byte 1 
    set register(LED2_OFF_L)     0x10  ; #read/write LED2 output and brightness control byte 2 
    set register(LED2_OFF_H)     0x11  ; #read/write LED2 output and brightness control byte 3 
    set register(LED3_ON_L)     0x12  ; #read/write LED3 output and brightness control byte 0 
    set register(LED3_ON_H)     0x13  ; #read/write LED3 output and brightness control byte 1 
    set register(LED3_OFF_L)     0x14  ; #read/write LED3 output and brightness control byte 2 
    set register(LED3_OFF_H)     0x15  ; #read/write LED3 output and brightness control byte 3 
    set register(LED4_ON_L)     0x16  ; #read/write LED4 output and brightness control byte 0 
    set register(LED4_ON_H)     0x17  ; #read/write LED4 output and brightness control byte 1 
    set register(LED4_OFF_L)     0x18  ; #read/write LED4 output and brightness control byte 2 
    set register(LED4_OFF_H)     0x19  ; #read/write LED4 output and brightness control byte 3 
    set register(LED5_ON_L)     0x1A  ; #read/write LED5 output and brightness control byte 0 
    set register(LED5_ON_H)     0x1B  ; #read/write LED5 output and brightness control byte 1 
    set register(LED5_OFF_L)     0x1C  ; #read/write LED5 output and brightness control byte 2 
    set register(LED5_OFF_H)     0x1D  ; #read/write LED5 output and brightness control byte 3 
    set register(LED6_ON_L)     0x1E  ; #read/write LED6 output and brightness control byte 0 
    set register(LED6_ON_H)     0x1F  ; #read/write LED6 output and brightness control byte 1 
    set register(LED6_OFF_L)     0x20  ; #read/write LED6 output and brightness control byte 2 
    set register(LED6_OFF_H)     0x21  ; #read/write LED6 output and brightness control byte 3 
    set register(LED7_ON_L)     0x22  ; #read/write LED7 output and brightness control byte 0 
    set register(LED7_ON_H)     0x23  ; #read/write LED7 output and brightness control byte 1 
    set register(LED7_OFF_L)     0x24  ; #read/write LED7 output and brightness control byte 2 
    set register(LED7_OFF_H)     0x25  ; #read/write LED7 output and brightness control byte 3 
    set register(LED8_ON_L)     0x26  ; #read/write LED8 output and brightness control byte 0 
    set register(LED8_ON_H)     0x27  ; #read/write LED8 output and brightness control byte 1 
    set register(LED8_OFF_L)     0x28  ; #read/write LED8 output and brightness control byte 2 
    set register(LED8_OFF_H)     0x29  ; #read/write LED8 output and brightness control byte 3 
    set register(LED9_ON_L)     0x2A  ; #read/write LED9 output and brightness control byte 0 
    set register(LED9_ON_H)     0x2B  ; #read/write LED9 output and brightness control byte 1 
    set register(LED9_OFF_L)     0x2C  ; #read/write LED9 output and brightness control byte 2 
    set register(LED9_OFF_H)     0x2D  ; #read/write LED9 output and brightness control byte 3 
    set register(LED10_ON_L)     0x2E  ; #read/write LED10 output and brightness control byte 0 
    set register(LED10_ON_H)     0x2F  ; #read/write LED10 output and brightness control byte 1 
    set register(LED10_OFF_L)     0x30  ; #read/write LED10 output and brightness control byte 2 
    set register(LED10_OFF_H)     0x31  ; #read/write LED10 output and brightness control byte 3 
    set register(LED11_ON_L)     0x32  ; #read/write LED11 output and brightness control byte 0 
    set register(LED11_ON_H)     0x33  ; #read/write LED11 output and brightness control byte 1 
    set register(LED11_OFF_L)     0x34  ; #read/write LED11 output and brightness control byte 2 
    set register(LED11_OFF_H)     0x35  ; #read/write LED11 output and brightness control byte 3 
    set register(LED12_ON_L)     0x36  ; #read/write LED12 output and brightness control byte 0 
    set register(LED12_ON_H)     0x37  ; #read/write LED12 output and brightness control byte 1 
    set register(LED12_OFF_L)     0x38  ; #read/write LED12 output and brightness control byte 2 
    set register(LED12_OFF_H)     0x39  ; #read/write LED12 output and brightness control byte 3 
    set register(LED13_ON_L)     0x3A  ; #read/write LED13 output and brightness control byte 0 
    set register(LED13_ON_H)     0x3B  ; #read/write LED13 output and brightness control byte 1 
    set register(LED13_OFF_L)     0x3C  ; #read/write LED13 output and brightness control byte 2 
    set register(LED13_OFF_H)     0x3D  ; #read/write LED13 output and brightness control byte 3 
    set register(LED14_ON_L)     0x3E  ; #read/write LED14 output and brightness control byte 0 
    set register(LED14_ON_H)     0x3F  ; #read/write LED14 output and brightness control byte 1 
    set register(LED14_OFF_L)     0x40  ; #read/write LED14 output and brightness control byte 2 
    set register(LED14_OFF_H)     0x41  ; #read/write LED14 output and brightness control byte 3 
    set register(LED15_ON_L)     0x42  ; #read/write LED15 output and brightness control byte 0 
    set register(LED15_ON_H)     0x43  ; #read/write LED15 output and brightness control byte 1 
    set register(LED15_OFF_L)     0x44  ; #read/write LED15 output and brightness control byte 2 
    set register(LED15_OFF_H)     0x45  ; #read/write LED15 output and brightness control byte 3 
    set register(ALL_LED_ON_L)     0xFA  ; #write/read zero load all the LEDn_ON registers, byte 0
    set register(ALL_LED_ON_H)     0xFB  ; #write/read zero load all the LEDn_ON registers, byte 1
    set register(ALL_LED_OFF_L)     0xFC  ; #write/read zero load all the LEDn_OFF registers, byte 2
    set register(ALL_LED_OFF_H)     0xFD  ; #write/read zero load all the LEDn_OFF registers, byte 3
    set register(PRE_SCALE)     0xFE  ; #read/write prescaler for output frequency    
    set register(TestMode)     0xFF  ; #read/write defines the test mode to be entered 

    
    # Dernière valeur de GPIO
    set register($adresse_I2C(0),GPIO_LAST) 0x00
    set register($adresse_I2C(1),GPIO_LAST) 0x00
    set register($adresse_I2C(2),GPIO_LAST) 0x00

    # Initialisation réalisée
    set register($adresse_I2C(0),init_done) 0
    set register($adresse_I2C(1),init_done) 0
    set register($adresse_I2C(2),init_done) 0
    
    # Pour inverser la sortie
    set outputReversed 0
}

# Cette proc est utilisée pour initialiser les modules
proc ::PCA9685::init {plugList} {
    variable adresse_module
    variable register
    variable outputReversed
    
    
    
    # On initialise le fonctionnement de la sortie
    if {[::piTools::readArrayElem [array get ::configXML] pwm_output "normal"] == "reversed"} {
        set outputReversed 1
        ::piLog::log [clock milliseconds] "info" "::PCA9685::init output must be reversed"
    }


    # Pour chaque adresse, on cherche le module et on l'initialise
    foreach plug $plugList {
    
        set address $::plug($plug,adress)
    
        # On cherche le nom du module correspondant
        set moduleAdresse "NA"
        set outputPin "NA"
        # Il faut que la clé existe
        if {[array get adresse_module $address] != ""} {
            set moduleAdresse $adresse_module($address)
            set outputPin     $adresse_module($address,out)
        }        
        
        if {$moduleAdresse == "NA"} {
            ::piLog::log [clock milliseconds] "error" "::PCA9685::init Adress $address does not exists "
            return
        }
        
        # On vérifie que le module est initialisé
        if {$register(${moduleAdresse},init_done) == 0} {
        
            # On démarre le module
            set RC [catch {               
                # Dans l'ordre : On passe Sleep
                # /usr/local/sbin/i2cget -y 1 0x40 0x10
                # Prescaler : 25 000 000 / (4096 * 1 000) -> 6
                # /usr/local/sbin/i2cset -y 1 0x40 0xFE 6
                # On retourne en mode normal 
                # /usr/local/sbin/i2cget -y 1 0x40 0x00
                exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(MODE1) 0x10
                exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(PRE_SCALE) 6
                exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(MODE1) 0x00
            } msg]
            if {$RC != 0} {
                ::piLog::log [clock milliseconds] "error" "::PCA9685::init Module $moduleAdresse does not respond :$msg "
            } else {
                ::piLog::log [clock milliseconds] "info" "::PCA9685::init init MODE1 to 0x10 OK"
                set register(${moduleAdresse},init_done) 1
            }
        }
    }
}

proc ::PCA9685::setValue {plugNumber value address} {
    variable adresse_module
    variable adresse_I2C
    variable register
    variable outputReversed
    
    set errorDuringSend 0
    
    # On cherche le nom du module correspondant
    set moduleAdresse "NA"
    set outputPin "NA"
    # Il faut que la clé existe
    if {[array get adresse_module $address] != ""} {
        set moduleAdresse $adresse_module($address)
        set outputPin     $adresse_module($address,out)
    }        
    
    if {$moduleAdresse == "NA"} {
        ::piLog::log [clock milliseconds] "error" "::PCA9685::setValue Adress $address does not exists "
        set errorDuringSend 1
        return $errorDuringSend
    }

    # On sauvegarde l'état de la prise
    ::savePlugSendValue $plugNumber $value

    # la valeur en entrée est entre 0 et 100
   
    if {$outputReversed == 0} {
        # Si la sortie est normale 
        # On met à jour le registre
        #   0 --> Off
        # 999 --> On
        # Par défaut on est inversé
        if {$value == 0 || $value == "off" } {
            #// Special value for signal fully on (so inverted : fully off).
            set ON_L   0xff
            set ON_H   0x1f
            set OFF_L  0x00
            set OFF_H  0x00

        } elseif {$value == 999 || $value == "on"} {
            #// Special value for signal fully off (so inverted : fully on).
            set ON_L   0x00
            set ON_H   0x00
            set OFF_L  0xff
            set OFF_H  0x1f
        } else {
            set ON_L   0x00
            set ON_H   0x00
            set OFF_L  [expr int(4095 - 4.096 * $value * 10) & 0x00ff]
            set OFF_H  [expr int(4095 - 4.096 * $value * 10) >> 8]
            #setPWM(num, 0, 4095-val);
        }
    } else {
        # la sortie est inversée
        # On met à jour le registre
        #   0 --> Off
        # 999 --> On
        # Par défaut on est inversé
        if {$value == 0 || $value == "off" } {
            #// Special value for signal fully on (so inverted : fully off).
            set ON_L   0x00
            set ON_H   0x00
            set OFF_L  0xff
            set OFF_H  0x1f
        } elseif {$value == 999 || $value == "on"} {
            #// Special value for signal fully off (so inverted : fully on).
            set ON_L   0xff
            set ON_H   0x1f
            set OFF_L  0x00
            set OFF_H  0x00
        } else {
            set ON_L   0x00
            set ON_H   0x00
            set OFF_L  [expr int(4.096 * $value * 10) & 0x00ff]
            set OFF_H  [expr int(4.096 * $value * 10) >> 8]
            #setPWM(num, 0, 4095-val);
        }
    }

    
    set RC [catch {
        # LED 8 25 % --> 3171 : 0x0B 0x0FF
        # /usr/local/sbin/i2cset -y 1 0x40 0x26 0
        # /usr/local/sbin/i2cset -y 1 0x40 0x27 0
        # /usr/local/sbin/i2cset -y 1 0x40 0x28 0xFF
        # /usr/local/sbin/i2cset -y 1 0x40 0x29 0x0B
        
        # LED 8 50 % --> 3171 : 0x0B 0x0FF
        # /usr/local/sbin/i2cset -y 1 0x40 0x26 0
        # /usr/local/sbin/i2cset -y 1 0x40 0x27 0
        # /usr/local/sbin/i2cset -y 1 0x40 0x28 0xFF
        # /usr/local/sbin/i2cset -y 1 0x40 0x29 0x07
        
        exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(LED${outputPin}_ON_L)  $ON_L
        exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(LED${outputPin}_ON_H)  $ON_H
        exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(LED${outputPin}_OFF_L) $OFF_L
        exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(LED${outputPin}_OFF_H) $OFF_H
    } msg]
    if {$RC != 0} {
        ::piLog::log [clock milliseconds] "error" "::PCA9685::setValue Module $moduleAdresse does not respond :$msg "
        set errorDuringSend 1
    } else {
        ::piLog::log [clock milliseconds] "info" "::PCA9685::setValue Output PWM  $ON_L $ON_H $OFF_L $OFF_H to $register(LED${outputPin}_ON_L) OK (output pin $outputPin) value $value"
    }

    return $errorDuringSend

}
