
# Module 0
# Init : /usr/local/sbin/i2cset -y 1 0x20 0x00 0x00
# Pilotage pin0 : /usr/local/sbin/i2cset -y 1 0x20 0x09 0x01

namespace eval ::PCA9685 {
    variable adresse_module
    variable adresse_I2C
    variable register
    
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

    # @0x41 cultibox : 0x82
    set adresse_module(37) 0x41
    set adresse_module(37,out) 0
    set adresse_module(38) 0x41
    set adresse_module(38,out) 1
    set adresse_module(39) 0x41
    set adresse_module(39,out) 2
    set adresse_module(40) 0x41
    set adresse_module(40,out) 3
    set adresse_module(41) 0x41
    set adresse_module(41,out) 4
    set adresse_module(42) 0x41
    set adresse_module(42,out) 5

    # @0x42 cultibox : 0x84
    set adresse_module(43) 0x42
    set adresse_module(43,out) 0
    set adresse_module(44) 0x42
    set adresse_module(44,out) 1
    set adresse_module(45) 0x42
    set adresse_module(45,out) 2
    set adresse_module(46) 0x42
    set adresse_module(46,out) 3
    set adresse_module(47) 0x42
    set adresse_module(47,out) 4
    set adresse_module(48) 0x42
    set adresse_module(48,out) 5

    # Adresse des modules
    set adresse_I2C(0) 0x40
    set adresse_I2C(1) 0x41
    set adresse_I2C(2) 0x42
    
    # D�finition des registres
    set register(MODE1)     0x0  ; #read/write Mode register 1     
    set register(MODE2)     0x1  ; #read/write Mode register 2     
    set register(SUBADR1)     0x2  ; #read/write I2C-bus subaddress 1     
    set register(SUBADR2)     0x3  ; #read/write I2C-bus subaddress 2     
    set register(SUBADR3)     0x4  ; #read/write I2C-bus subaddress 3     
    set register(ALLCALLADR)     0x5  ; #read/write LED All Call I2C-bus address   
    set register(LED0_ON_L)     0x6  ; #read/write LED0 output and brightness control byte 0 
    set register(LED0_ON_H)     0x7  ; #read/write LED0 output and brightness control byte 1 
    set register(LED0_OFF_L)     0x8  ; #read/write LED0 output and brightness control byte 2 
    set register(LED0_OFF_H)     0x9  ; #read/write LED0 output and brightness control byte 3 
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
    set register(PRE_SCALE[1])     0xFE  ; #read/write prescaler for output frequency    
    set register(TestMode[2])     0xFF  ; #read/write defines the test mode to be entered 

    
    # Derni�re valeur de GPIO
    set register($adresse_I2C(0),GPIO_LAST) 0x00
    set register($adresse_I2C(1),GPIO_LAST) 0x00
    set register($adresse_I2C(2),GPIO_LAST) 0x00

    # Initialisation r�alis�e
    set register($adresse_I2C(0),init_done) 0
    set register($adresse_I2C(1),init_done) 0
    set register($adresse_I2C(2),init_done) 0
    
}

# Cette proc est utilis�e pour initialiser les modules
proc ::PCA9685::init {plugList} {
    variable adresse_module
    variable register

    # Pour chaque adresse, on cherche le module et on l'initialise
    foreach plug $plugList {
    
        set address $::plug($plug,adress)
    
        # On cherche le nom du module correspondant
        set moduleAdresse "NA"
        set outputPin "NA"
        # Il faut que la cl� existe
        if {[array get adresse_module $address] != ""} {
            set moduleAdresse $adresse_module($address)
            set outputPin     $adresse_module($address,out)
        }        
        
        if {$moduleAdresse == "NA"} {
            ::piLog::log [clock milliseconds] "error" "::PCA9685::init Adress $address does not exists "
            return
        }
        
        # On v�rifie que le module est initialis�
        if {$register(${moduleAdresse},init_done) == 0} {
        
            # On d�marre le module
            set RC [catch {
                exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(MODE1) 0x10
            } msg]
            if {$RC != 0} {
                ::piLog::log [clock milliseconds] "error" "::PCA9685::init Module $moduleAdresse does not respond :$msg "
            } else {
                ::piLog::log [clock milliseconds] "info" "::PCA9685::init init MODE1 to 0x10 OK"
                set register(${moduleAdresse},init_done) 1
            }
        
            if {0} {
                # D�finition de la fr�quence
                set freq [expr 1000 * 0.9]; # // Correct for overshoot in the frequency setting (see issue #11).
                set prescaleval = 25000000;
                set prescaleval [expr $prescaleval / 4096];
                set prescaleval [expr $prescaleval / $freq];
                set prescaleval [expr $prescaleval * -1];

                set prescale [expr floor($prescaleval + 0.5)];

                #set oldmode = read8(PCA9685_MODE1);
                set oldmode [exec /usr/local/sbin/i2cget -y 1 $moduleAdress $register(MODE1)]

                set newmode [expr ($oldmode & 0x7F) | 0x10] ;# // sleep

                # write8(PCA9685_MODE1, newmode); // go to sleep
                exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(MODE1) $newmode

                #write8(PCA9685_PRESCALE, prescale); // set the prescaler
                exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(PRESCALE) $prescale

                #write8(PCA9685_MODE1, oldmode);
                exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(MODE1) $oldmode

                #delay(5);
                after 5

                #write8(PCA9685_MODE1, oldmode | 0xa1);  //  This sets the MODE1 register to turn on auto increment.
                #                                        // This is why the beginTransmission below was not working.
                exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(MODE1) [expr $oldmode | 0xa1]
            
            }
        }
    
    }
}

proc ::PCA9685::setValue {plugNumber value address} {
    variable adresse_module
    variable adresse_I2C
    variable register

    set errorDuringSend 0
    
    # On cherche le nom du module correspondant
    set moduleAdresse "NA"
    set outputPin "NA"
    # Il faut que la cl� existe
    if {[array get adresse_module $address] != ""} {
        set moduleAdresse $adresse_module($address)
        set outputPin     $adresse_module($address,out)
    }        
    
    if {$moduleAdresse == "NA"} {
        ::piLog::log [clock milliseconds] "error" "::PCA9685::setValue Adress $address does not exists "
        set errorDuringSend 1
        return $errorDuringSend
    }

    # On sauvegarde l'�tat de la prise
    ::savePlugSendValue $plugNumber $value

    # On met � jour le registre
    #   0 --> Off
    # 999 --> On
    # Par d�faut on est invers�
    if {$value == 0} {
        #// Special value for signal fully on (so inverted : fully off).
        set ON_L   0xff
        set ON_H   0xff
        set OFF_L  0x00
        set OFF_H  0x00

    } elseif {$value == 999} {
        #// Special value for signal fully off (so inverted : fully on).
        set ON_L   0x00
        set ON_H   0x00
        set OFF_L  0xff
        set OFF_H  0xff
    } else {
        set ON_L   0x00
        set ON_H   0x00
        set OFF_L  [expr int(4095 - 4.096 * $value) >> 8]
        set OFF_H  [expr int(4095 - 4.096 * $value) & 0x00ff]
        #setPWM(num, 0, 4095-val);
    }
    
    set RC [catch {
        exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(LED${outputPin}_ON_L)  $ON_L
        exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(LED${outputPin}_ON_H)  $ON_H
        exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(LED${outputPin}_OFF_L) $OFF_L
        exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(LED${outputPin}_OFF_H) $OFF_H
    } msg]
    if {$RC != 0} {
        ::piLog::log [clock milliseconds] "error" "::PCA9685::setValue Module $moduleAdresse does not respond :$msg "
        set errorDuringSend 1
    } else {
        ::piLog::log [clock milliseconds] "info" "::PCA9685::setValue Output PWM  $ON_L $ON_H $OFF_L $OFF_H to $register(LED${outputPin}_ON_L) OK (output pin $outputPin)"
    }

    return $errorDuringSend

}
