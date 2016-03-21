
# Module 0
# Init : /usr/local/sbin/i2cset -y 1 0x20 0x00 0x00
# Pilotage pin0 : /usr/local/sbin/i2cset -y 1 0x20 0x09 0x01

namespace eval ::ADS1015 {
    variable adresse_module
    variable adresse_I2C
    variable register
    
    # @0x20 cultibox : 0x40
    set adresse_module(60) 0x20
    set adresse_module(60,out) 0
    set adresse_module(61) 0x20
    set adresse_module(61,out) 1
    set adresse_module(62) 0x20
    set adresse_module(62,out) 2
    set adresse_module(63) 0x20
    set adresse_module(63,out) 3
    set adresse_module(64) 0x20
    set adresse_module(64,out) 4
    set adresse_module(65) 0x20
    set adresse_module(65,out) 5
    set adresse_module(66) 0x20
    set adresse_module(66,out) 6
    set adresse_module(67) 0x20
    set adresse_module(67,out) 7
    set adresse_module(68) 0x20
    set adresse_module(68,out) "all"

    # @0x22 cultibox : 0x42
    set adresse_module(70) 0x22
    set adresse_module(70,out) 0
    set adresse_module(71) 0x22
    set adresse_module(71,out) 1
    set adresse_module(72) 0x22
    set adresse_module(72,out) 2
    set adresse_module(73) 0x22
    set adresse_module(73,out) 3
    set adresse_module(74) 0x22
    set adresse_module(74,out) 4
    set adresse_module(75) 0x22
    set adresse_module(75,out) 5
    set adresse_module(76) 0x22
    set adresse_module(76,out) 6
    set adresse_module(77) 0x22
    set adresse_module(77,out) 7
    set adresse_module(78) 0x22
    set adresse_module(78,out) "all"

    # @0x24 cultibox : 0x44
    set adresse_module(80) 0x24
    set adresse_module(80,out) 0
    set adresse_module(81) 0x24
    set adresse_module(81,out) 1
    set adresse_module(82) 0x24
    set adresse_module(82,out) 2
    set adresse_module(83) 0x24
    set adresse_module(83,out) 3
    set adresse_module(84) 0x24
    set adresse_module(84,out) 4
    set adresse_module(85) 0x24
    set adresse_module(85,out) 5
    set adresse_module(86) 0x24
    set adresse_module(86,out) 6
    set adresse_module(87) 0x24
    set adresse_module(87,out) 7
    set adresse_module(88) 0x24
    set adresse_module(88,out) "all"

    # Adresse des modules
    # 1001000 0/1 --> 0xC0 --> 0x48
    # 1001001 0/1 --> 0xC2 --> 0x49
    # 1001010 0/1 --> 0xC4 --> 0x4A
    # 1001011 0/1 --> 0xC6 --> 0x4B
    set adresse_I2C(0) 0x48
    set adresse_I2C(1) 0x49
    set adresse_I2C(2) 0x4A
    set adresse_I2C(3) 0x4B
    
    # Définition des registres
    set register(CONVERSION) 0x00
    set register(CONFIG)     0x00
    set register(LO_THRESH)  0x01
    set register(HI_THRESH)  0x02

    # Initialisation réalisée
    set register($adresse_I2C(0),init_done) 0
    set register($adresse_I2C(1),init_done) 0
    set register($adresse_I2C(2),init_done) 0
    set register($adresse_I2C(3),init_done) 0
    
}

# Cette proc est utilisée pour initialiser les modules
proc ::ADS1015::init {index} {
    variable adresse_module
    variable adresse_I2C
    variable register

    set moduleAdresse "NA"
    if {[array get adresse_I2C $index] != ""} {
        set moduleAdresse $adresse_I2C($index)
    }
    
    if {$moduleAdresse == "NA"} {
        ::piLog::log [clock milliseconds] "error" "::ADS1015::init Adress $address does not exists "
        return
    }
    
    # On vérifie que l module est initialisé
    if {$register(${moduleAdresse},init_done) == 0} {
    
        # Il n'y a pas d'initilisation a faire

    } else {
        ::piLog::log [clock milliseconds] "debug" "::ADS1015::init Module $moduleAdresse already initialized"
    }
}


proc ::ADS1015::read {index sensor} {
    variable adresse_module
    variable adresse_I2C
    variable register
    
    set value "NA"

    set moduleAdresse "NA"
    if {[array get adresse_I2C $index] != ""} {
        set moduleAdresse $adresse_I2C($index)
    }
    
    if {$moduleAdresse == "NA"} {
        ::piLog::log [clock milliseconds] "error" "::ADS1015::read Adress $address does not exists "
        return
    }
    
    # Si l'initialisation n'est pas faite, on l'a fait 
    if {$register($index,init_done) == 0} {
        ::ADS1015::init $index
    } else {
        # lecture de l'état des entrées
        # /usr/local/sbin/i2cget -y 1 0x20 0x12
        set RC [catch {
            set registerA [exec /usr/local/sbin/i2cget -y 1 $moduleAdresse $register(GPIOA)]
            # Petite tempo au cas ou
            after 10
            set registerB [exec /usr/local/sbin/i2cget -y 1 $moduleAdresse $register(GPIOB)]
        } msg]
        if {$RC != 0} {
            ::piLog::log [clock milliseconds] "error" "::ADS1015::init Module $moduleAdresse does not respond :$msg "
        } else {

            # On calcul la valeur
            set value 0
            for {set $j 1} {$j <= $::configXML(sensor,${sensor},nbinput)} {incr j} {
            
                set input       $::configXML(sensor,${sensor},input,$j)
                set incrValue   $::configXML(sensor,${sensor},value,$j)
            
                # Registre A
                if {$input <= 8} {
                    if {[expr $registerB & 1 << ($input - 1)] != 0} {
                        set value [expr $value + $incrValue] 
                    }
                } else {
                    # Registre B
                    if {[expr $registerB & 1 << ($input - 1 - 8)] != 0} {
                        set value [expr $value + $incrValue] 
                    }
                }
            }
        
        }
    }

    return $value
}
