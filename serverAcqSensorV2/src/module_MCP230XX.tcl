
# Module 0
# Init : /usr/local/sbin/i2cset -y 1 0x20 0x00 0x00
# Pilotage pin0 : /usr/local/sbin/i2cset -y 1 0x20 0x09 0x01

namespace eval ::MCP230XX {
    variable adresse_I2C
    variable register

    # Adresse des modules
    set adresse_I2C(0) 0x20
    set adresse_I2C(1) 0x21
    set adresse_I2C(2) 0x22
    set adresse_I2C(3) 0x23
    set adresse_I2C(4) 0x24
    set adresse_I2C(5) 0x25
    set adresse_I2C(6) 0x26
    set adresse_I2C(7) 0x27
    
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
    for {set i 0} {$i < 7} {incr i} {
        # Initialisation r�alis�e
        set register($i,init_done) 0
    }
}

# Cette proc est utilis�e pour initialiser les modules
proc ::MCP230XX::init {index} {
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
    if {$register(${index},init_done) == 0} {
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
            set register(${index},init_done) 1
        }
    } else {
        ::piLog::log [clock milliseconds] "debug" "::MCP230XX::init Module $moduleAdresse already initialized"
    }
}


proc ::MCP230XX::read {index sensor} {
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
