# Ce fichier définit pour chaque adresse le module à appeler

namespace eval ::address {
    variable val
    
    # Listing des adresses I2C
    # Module    @RPi    @CBx
    # SHT_1     0x01    0x02
    # SHT_2     0x02    0x04
    # SHT_3     0x03    0x06
    # SHT_4     0x04    0x08
    # DS18B20_2 0x05    0x10
    # DS18B20_3 0x06    0x12
    # DS18B20_4 0x07    0x14
    # WATER_L_5 0x08    0x16
    # WATER_L_6 0x09    0x18
    # DIMMER    0x10    0x20    
    # DIMMER    0x11    0x22   
    # DIMMER    0x12    0x24 
    # PH_2      0x13    0x26
    # PH_3      0x14    0x28
    # PH_4      0x15    0x2A
    # PH_5      0x16    0x2C
    # PH_6      0x17    0x2E
    # EC_2      0x18    0x30
    # EC_3      0x19    0x32
    # EC_4      0x1A    0x34
    # EC_5      0x1B    0x36
    # EC_6      0x1C    0x38
    # ORP_2     0x1D    0x3A
    # ORP_3     0x1E    0x3C
    # ORP_4     0x1F    0x3E
    # MCP230XX  0x20    0x40
    # MCP230XX  0x21    0x42
    # MCP230XX  0x22    0x44
    # NOT_USED  0x23    0x46    (RESERVED FOR MCP230XX)
    # NOT_USED  0x24    0x48    (RESERVED FOR MCP230XX)
    # NOT_USED  0x25    0x4A    (RESERVED FOR MCP230XX)
    # NOT_USED  0x26    0x4C    (RESERVED FOR MCP230XX)
    # NOT_USED  0x27    0x4E    (RESERVED FOR MCP230XX)
    # ORP_5     0x28    0x50
    # ORP_6     0x29    0x52
    # OD_2      0x2A    0x54
    # OD_3      0x2B    0x56
    # OD_4      0x2C    0x58
    # OD_5      0x2D    0x5A
    # OD_6      0x2E    0x5C
    # DS18B20_5 0x2F    0x5E
    # DS18B20_6 0x30    0x60
    # NOT_USED  0x31    0x62
    # NOT_USED  0x32    0x64
    # NOT_USED  0x33    0x66
    # NOT_USED  0x34    0x68
    # NOT_USED  0x35    0x6A
    # NOT_USED  0x36    0x6C
    # NOT_USED  0x37    0x6E
    # NOT_USED  0x38    0x70
    # NOT_USED  0x39    0x72
    # NOT_USED  0x3A    0x74
    # NOT_USED  0x3B    0x76
    # NOT_USED  0x3C    0x78
    # NOT_USED  0x3D    0x7A
    # NOT_USED  0x3E    0x7C
    # NOT_USED  0x3F    0x7E
    # PCA9685_1 0x40    0x80
    # PCA9685_2 0x41    0x82
    # PCA9685_3 0x42    0x84
    # NOT_USED  0x43    0x86    (CAN BE USED BY PCA9685)
    # NOT_USED  0x44    0x88    (CAN BE USED BY PCA9685)
    # NOT_USED  0x45    0x8A    (CAN BE USED BY PCA9685)
    # NOT_USED  0x46    0x8C    (CAN BE USED BY PCA9685)
    # NOT_USED  0x47    0x8E    (CAN BE USED BY PCA9685)
    # NOT_USED  0x48    0x90    (CAN BE USED BY PCA9685)
    # NOT_USED  0x49    0x92    (CAN BE USED BY PCA9685)
    # NOT_USED  0x4A    0x94    (CAN BE USED BY PCA9685)
    # NOT_USED  0x4B    0x96    (CAN BE USED BY PCA9685)
    # NOT_USED  0x4C    0x98    (CAN BE USED BY PCA9685)
    # NOT_USED  0x4D    0x9A    (CAN BE USED BY PCA9685)
    # NOT_USED  0x4E    0x9C    (CAN BE USED BY PCA9685)
    # NOT_USED  0x4F    0x9E    (CAN BE USED BY PCA9685)
    # NOT_USED  0x50    0xA0
    # NOT_USED  0x51    0xA2
    # NOT_USED  0x52    0xA4
    # NOT_USED  0x53    0xA6
    # NOT_USED  0x54    0xA8
    # émetteur  0x55    0xAA
    
    # @0x55 , cultibox : 0xaa
    set val(4) wireless
    set val(6) wireless
    set val(8) wireless
    set val(10) wireless
    set val(12) wireless
    set val(14) wireless
    set val(16) wireless
    set val(18) wireless
    set val(20) wireless
    set val(22) wireless
    set val(24) wireless
    set val(26) wireless
    set val(28) wireless
    set val(30) wireless
    set val(247) wireless
    set val(222) wireless
    set val(219) wireless
    set val(215) wireless
    set val(207) wireless
    set val(252) wireless
    set val(250) wireless
    set val(246) wireless
    set val(238) wireless
    set val(187) wireless
    set val(183) wireless
    set val(189) wireless
    set val(125) wireless
    set val(123) wireless
    set val(119) wireless

    # Adresses pour la commande directe
    set val(50) direct
    set val(51) direct
    set val(52) direct
    set val(53) direct
    set val(54) direct
    set val(55) direct
    set val(56) direct
    set val(57) direct
    
    # Adresse pour la commande en utilisant MCP23008 (optionnel-ment MCP23017)
    # @0x20 cultibox : 0x40
    set val(60) MCP230XX
    set val(61) MCP230XX
    set val(62) MCP230XX
    set val(63) MCP230XX
    set val(64) MCP230XX
    set val(65) MCP230XX
    set val(66) MCP230XX
    set val(67) MCP230XX
    set val(68) MCP230XX
    
    # @0x21 cultibox : 0x42
    set val(70) MCP230XX
    set val(71) MCP230XX
    set val(72) MCP230XX
    set val(73) MCP230XX
    set val(74) MCP230XX
    set val(75) MCP230XX
    set val(76) MCP230XX
    set val(77) MCP230XX
    set val(78) MCP230XX
    
    # @0x22 cultibox : 0x44
    set val(80) MCP230XX
    set val(81) MCP230XX
    set val(82) MCP230XX
    set val(83) MCP230XX
    set val(84) MCP230XX
    set val(85) MCP230XX
    set val(86) MCP230XX
    set val(87) MCP230XX
    set val(88) MCP230XX
    
    # Adresse pour la commande en utilisant le vario
    # @0x10 cultibox : 0x20
    set val(90) DIMMER
    set val(91) DIMMER
    set val(92) DIMMER
    set val(93) DIMMER
    
    # @0x11 cultibox : 0x22
    set val(95) DIMMER
    set val(96) DIMMER
    set val(97) DIMMER
    set val(98) DIMMER

    # @0x12 cultibox : 0x24
    set val(100) DIMMER
    set val(101) DIMMER
    set val(102) DIMMER
    set val(103) DIMMER
    
    # Adresse pour XMAX
    # @0x23 cultibox : 0x46
    set val(105) XMAX
    set val(106) XMAX
    set val(107) XMAX
    set val(108) XMAX
    
    # Adresse pour d'autre cultipi (10 modules)
    # @1000 --> 1176
    for {set j 0} {$j < 10} {incr j} {
        for {set i 0} {$i < 16} {incr i} {
            set val([expr 1000 + 16 * $j + $i]) CULTIPI
        }
    }
    
    # Adresses pour les modules PWM 
    # @0x40 cultibox : 0x80
    set val(31) PCA9685
    set val(32) PCA9685
    set val(33) PCA9685
    set val(34) PCA9685
    set val(35) PCA9685
    set val(36) PCA9685
    set val(37) PCA9685
    set val(38) PCA9685
    
    # @0x41 cultibox : 0x82
    set val(39) PCA9685
    set val(40) PCA9685
    set val(41) PCA9685
    set val(42) PCA9685
    set val(43) PCA9685
    set val(44) PCA9685
    
    # @0x42 cultibox : 0x84
    set val(45) PCA9685
    set val(46) PCA9685
    set val(47) PCA9685
    set val(48) PCA9685
    set val(49) PCA9685
    # set val(50) PCA9685
    
}

proc ::address::get_module {address} {
    variable val

    if {[array get val $address] != ""} {
        return $val($address)
    } else {
        return "NA"
    }
    

}