
# Module 0
# Init : /usr/local/sbin/i2cset -y 1 0x20 0x00 0x00
# Pilotage pin0 : /usr/local/sbin/i2cset -y 1 0x20 0x09 0x01

namespace eval ::MCP230XX {
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
    set adresse_I2C(0) 0x20
    set adresse_I2C(1) 0x22
    set adresse_I2C(2) 0x24
    
    # D�finition des registres
    set register(IODIRA)     0x00
    set register(IODIRB)     0x00
    set register(IPOL)      0x01
    set register(GPINTEN)   0x02
    set register(DEFVAL)    0x03
    set register(INTCON)    0x04
    set register(IOCON)     0x05
    set register(GPPU)      0x06
    set register(INTF)      0x07
    set register(INTCAP)    0x08
    set register(GPIOA)     0x12
    set register(GPIOB)     0x13
    set register(OLAT)      0x0A


    # Initialisation r�alis�e
    set register($adresse_I2C(0),init_done) 0
    set register($adresse_I2C(1),init_done) 0
    set register($adresse_I2C(2),init_done) 0
    
}

# Cette proc est utilis�e pour initialiser les modules
proc ::MCP230XX::init {index} {
    variable adresse_module
    variable adresse_I2C
    variable register

    set moduleAdresse "NA"
    if {[array get adresse_I2C $index] != ""} {
        set moduleAdresse $adresse_I2C($index)
    }
    
    if {$moduleAdresse == "NA"} {
        ::piLog::log [clock milliseconds] "error" "::MCP230XX::init Adress $address does not exists "
        return
    }
    
    # On v�rifie que l module est initialis�
    if {$register(${moduleAdresse},init_done) == 0} {
        # On d�finit chaque pin en entr�e
        # /usr/local/sbin/i2cset -y 1 0x20 0x00 0xff
        # /usr/local/sbin/i2cset -y 1 0x20 0x01 0xff
        # lecture de l'�tat des sorties
        # /usr/local/sbin/i2cget -y 1 0x20 0x00
        set RC [catch {
            exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(IODIRA) 0xff
            # Petite tempo au cas ou
            after 10
            exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(IODIRB) 0xff
        } msg]
        if {$RC != 0} {
            ::piLog::log [clock milliseconds] "error" "::MCP230XX::init Module $moduleAdresse does not respond :$msg "
        } else {
            ::piLog::log [clock milliseconds] "info" "::MCP230XX::init Module $moduleAdresse init IODIRA & IODIRB to 0xFF OK"
            set register(${moduleAdresse},init_done) 1
        }
    } else {
        ::piLog::log [clock milliseconds] "debug" "::MCP230XX::init Module $moduleAdresse already initialized"
    }
}


proc ::MCP230XX::read {index sensor} {
    variable adresse_module
    variable adresse_I2C
    variable register
    
    set value "NA"

    set moduleAdresse "NA"
    if {[array get adresse_I2C $index] != ""} {
        set moduleAdresse $adresse_I2C($index)
    }
    
    if {$moduleAdresse == "NA"} {
        ::piLog::log [clock milliseconds] "error" "::MCP230XX::read Adress $address does not exists "
        return
    }
    
    # Si l'initialisation n'est pas faite, on l'a fait 
    if {$register($index,init_done) == 0} {
        ::MCP230XX::init $index
    } else {
        # lecture de l'�tat des entr�es
        # /usr/local/sbin/i2cget -y 1 0x20 0x12
        set RC [catch {
            set registerA [exec /usr/local/sbin/i2cget -y 1 $moduleAdresse $register(GPIOA)]
            # Petite tempo au cas ou
            after 10
            set registerB [exec /usr/local/sbin/i2cget -y 1 $moduleAdresse $register(GPIOB)]
        } msg]
        if {$RC != 0} {
            ::piLog::log [clock milliseconds] "error" "::MCP230XX::init Module $moduleAdresse does not respond :$msg "
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
