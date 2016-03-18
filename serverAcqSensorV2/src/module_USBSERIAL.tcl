
# Module 0
# Init : /usr/local/sbin/i2cset -y 1 0x20 0x00 0x00
# Pilotage pin0 : /usr/local/sbin/i2cset -y 1 0x20 0x09 0x01

namespace eval ::USBSERIAL {
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
    
    # Définition des registres
    set register(IODIR1)     0x00
    set register(IODIR2)     0x00
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
    
    # Dernière valeur de GPIO
    set register($adresse_I2C(0),GPIO_LAST) 0x00
    set register($adresse_I2C(1),GPIO_LAST) 0x00
    set register($adresse_I2C(2),GPIO_LAST) 0x00

    # Initialisation réalisée
    set register($adresse_I2C(0),init_done) 0
    set register($adresse_I2C(1),init_done) 0
    set register($adresse_I2C(2),init_done) 0
    
}

# Cette proc est utilisée pour initialiser les modules
proc ::USBSERIAL::init {index} {
    variable adresse_module
    variable adresse_I2C
    variable register

}

proc ::USBSERIAL::read {index} {
    return "NA"
}
