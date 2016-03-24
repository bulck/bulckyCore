
# Module 0
# Init : /usr/local/sbin/i2cset -y 1 0x20 0x00 0x00
# Pilotage pin0 : /usr/local/sbin/i2cset -y 1 0x20 0x09 0x01

namespace eval ::MCP230XX {
    variable adresse_module
    variable adresse_I2C
    variable register
    
    # @0x20 cultibox : 0x40
    #   60 --> 68
    # @0x21 cultibox : 0x42
    #   70 --> 78
    # @0x24 cultibox : 0x44
    #   80 --> 88
    foreach adressI2C [list 0x20 0x21 0x22] startAdress [list 60 70 80] {
        for {set i 0} {$i < 8} {incr i} {
            set adresse_module([expr $startAdress + $i])     $adressI2C
            set adresse_module([expr $startAdress + $i],out) 0
        }
        set adresse_module([expr $startAdress + 8])     $adressI2C
        set adresse_module([expr $startAdress + 8],out) "all"
    }

    # Adresse : 
    #   0x20 --> 3000 - 3008
    #   0x21 --> 3010 - 3018
    foreach adressI2C [list 0x20 0x21 0x22 0x23 0x24 0x25 0x26 0x27] startAdress [list 3000 3010 3020 3030 3040 3050 3060 3070] {
        for {set i 0} {$i < 8} {incr i} {
            set adresse_module([expr $startAdress + $i])     $adressI2C
            set adresse_module([expr $startAdress + $i],out) 0
        }
        set adresse_module([expr $startAdress + 8])     $adressI2C
        set adresse_module([expr $startAdress + 8],out) "all"
    }

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
    set register(IODIR)     0x00
    set register(IPOL)      0x01
    set register(GPINTEN)   0x02
    set register(DEFVAL)    0x03
    set register(INTCON)    0x04
    set register(IOCON)     0x05
    set register(GPPU)      0x06
    set register(INTF)      0x07
    set register(INTCAP)    0x08
    set register(GPIO)      0x09
    set register(OLAT)      0x0A

    for {set i 0} {$i < 7} {incr i} {
        # Dernière valeur de GPIO
        set register($adresse_I2C($i),GPIO_LAST) 0x00
        # Initialisation réalisée
        set register($adresse_I2C($i),init_done) 0
    }
}

# Cette proc est utilisée pour initialiser les modules
proc ::MCP230XX::init {plugList} {
    variable adresse_module
    variable register

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
            ::piLog::log [clock milliseconds] "error" "::MCP230XX::init Adress $address does not exists "
            return
        }
        
        # On vérifie que l module est initialisé
        if {$register(${moduleAdresse},init_done) == 0} {
            # On définit chaque pin en sortie
            # /usr/local/sbin/i2cset -y 1 0x20 0x00 0x00
            # lecture de l'état des sorties
            # /usr/local/sbin/i2cget -y 1 0x20 0x00
            set RC [catch {
                exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(IODIR) 0x00
            } msg]
            if {$RC != 0} {
                ::piLog::log [clock milliseconds] "error" "::MCP230XX::init Module $moduleAdresse does not respond :$msg "
            } else {
                ::piLog::log [clock milliseconds] "info" "::MCP230XX::init init IODIR to 0x00 OK"
                set register(${moduleAdresse},init_done) 1
            }
        }
    
    }
}

proc ::MCP230XX::setValue {plugNumber value address} {
    variable adresse_module
    variable adresse_I2C
    variable register

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
        ::piLog::log [clock milliseconds] "error" "::MCP230XX::setValue Adress $address does not exists "
        set errorDuringSend 1
        return $errorDuringSend
    }

    # On sauvegarde l'état de la prise
    ::savePlugSendValue $plugNumber $value
    
    # On met à jour le registre
    # Si c'est la dernière adresse, c'est un pilotage générale
    if {$outputPin == "all"} {
        if {$value == "on"} {
            set register(${moduleAdresse},GPIO_LAST) [expr 0xff] 
        } else {
            set register(${moduleAdresse},GPIO_LAST) [expr 0x00]
        }
    } else {
        if {$value == "on"} {
            set register(${moduleAdresse},GPIO_LAST) [expr $register(${moduleAdresse},GPIO_LAST) | (1 << $outputPin)] 
        } else {
            set register(${moduleAdresse},GPIO_LAST) [expr $register(${moduleAdresse},GPIO_LAST) & ~(1 << $outputPin)]
        }
    }

    set RC [catch {
        exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(IODIR) 0x00
        after 10
    } msg]
    if {$RC != 0} {
        ::piLog::log [clock milliseconds] "error" "::MCP230XX::init Module $moduleAdresse does not respond :$msg "
        set errorDuringSend 1
    } else {
        ::piLog::log [clock milliseconds] "info" "::MCP230XX::init init IODIR to 0x00 OK"
        set register(${moduleAdresse},init_done) 1
    }
    
    # On pilote le registre de sortie
    # /usr/local/sbin/i2cset -y 1 0x20 0x09 0x0F
    # /usr/local/sbin/i2cget -y 1 0x20 0x09
    # lecture de l'état des sorties
    # /usr/local/sbin/i2cget -y 1 0x20 0x0A
    # Pin 1 du module 1 :
    # /usr/local/sbin/i2cset -y 1 0x20 0x09 0x01
    # /usr/local/sbin/i2cset -y 1 0x20 0x09 0x30
    
    set RC [catch {
        exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(GPIO) $register(${moduleAdresse},GPIO_LAST)
    } msg]
    if {$RC != 0} {
        ::piLog::log [clock milliseconds] "error" "::MCP230XX::setValue Module $moduleAdresse does not respond :$msg "
        set errorDuringSend 1
    } else {
        ::piLog::log [clock milliseconds] "info" "::MCP230XX::setValue Output GPIO  $moduleAdresse to $register(${moduleAdresse},GPIO_LAST) OK (output pin $outputPin)"
    }
    
    return $errorDuringSend

}
