
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
    
    # Définition des registres
    set register(IODIRA)    0x00
    set register(IODIRB)    0x01
    set register(GPPUA)     0x0C
    set register(GPPUB)     0x0D
    set register(GPIOA)     0x12
    set register(GPIOB)     0x13


    # Initialisation réalisée
    for {set i 0} {$i < 8} {incr i} {
        # Initialisation réalisée
        set register($i,init_done) 0
    }
}

# Cette proc est utilisée pour initialiser les modules
proc ::MCP230XX::init {index} {
    variable adresse_I2C
    variable register

    set moduleAdresse "NA"
    if {[array get adresse_I2C $index] != ""} {
        set moduleAdresse $adresse_I2C($index)
    }
    
    if {$moduleAdresse == "NA"} {
        ::piLog::log [clock milliseconds] "error" "::MCP230XX::init index $index does not exists "
        return
    }
    
    # On vérifie que l module est initialisé
    if {$register(${index},init_done) == 0} {
        # On définit chaque pin en entrée
        # /usr/local/sbin/i2cset -y 1 0x27 0x00 0xff 0xff i
        # On définit met les pull up 
        # /usr/local/sbin/i2cset -y 1 0x27 0x0C 0xff 0xff i
        # lecture de l'état des sorties
        # /usr/local/sbin/i2cget -y 1 0x27 0x00 w
        set RC [catch {
            exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(IODIRA) 0xff 0xff i
            
            # On met les pull up
            after 10
            exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(GPPUA) 0xff 0xff i
            
        } msg]
        if {$RC != 0} {
            ::piLog::log [clock milliseconds] "error" "::MCP230XX::init index $index Module $moduleAdresse does not respond :$msg "
        } else {
            ::piLog::log [clock milliseconds] "info" "::MCP230XX::init index $index Module $moduleAdresse init IODIRA & IODIRB to 0xFF OK"
            set register(${index},init_done) 1
        }
    } else {
        ::piLog::log [clock milliseconds] "debug" "::MCP230XX::init index $index Module $moduleAdresse already initialized"
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
        ::piLog::log [clock milliseconds] "error" "::MCP230XX::read index $index does not exists "
        return $value
    }
    
    # Si l'initialisation n'est pas faite, on l'a fait 
    if {$register($index,init_done) == 0} {
        ::MCP230XX::init $index
    } else {
        # lecture de l'état des entrées
        # /usr/local/sbin/i2cget -y 1 0x27 0x12 w
        set RC [catch {
            set registerVal [exec /usr/local/sbin/i2cget -y 1 $moduleAdresse $register(GPIOA) w]
        } msg]
        if {$RC != 0} {
            ::piLog::log [clock milliseconds] "error" "::MCP230XX::init Module $moduleAdresse does not respond :$msg "
        } else {

            # On calcul la valeur
            set value 0
            for {set j 1} {$j <= $::configXML(sensor,${sensor},nbinput)} {incr j} {
            
                set input       $::configXML(sensor,${sensor},input,$j)
                set incrValue   $::configXML(sensor,${sensor},value,$j)
            
                # Registre
                if {[expr $registerVal & 1 << ($input - 1)] == 0} {
                    set value [expr $value + $incrValue] 
                }

            }
        
        }
    }

    return $value
}
