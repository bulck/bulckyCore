
# Module 0
# Init : /usr/local/sbin/i2cset -y 1 0x20 0x00 0x00
# Pilotage pin0 : /usr/local/sbin/i2cset -y 1 0x20 0x09 0x01

namespace eval ::ADS1015 {
    variable adresse_I2C
    variable register

    # Pointer Register
    set register(POINTER_MASK) 0x03
    set register(POINTER_CONVERT) 0x00
    set register(POINTER_CONFIG) 0x01
    set register(POINTER_LOWTHRESH) 0x02
    set register(POINTER_HITHRESH) 0x03

    # Config Register
    set register(CONFIG_OS_MASK) 0x8000
    set register(CONFIG_OS_SINGLE) 0x8000   ;# Write: Set to start a single-conversion
    set register(CONFIG_OS_BUSY) 0x0000     ;# Read: Bit) 0 when conversion is in progress
    set register(CONFIG_OS_NOTBUSY) 0x8000  ;# Read: Bit) 1 when device is not performing a conversion

    set register(CONFIG_MUX_MASK) 0x7000
    set register(CONFIG_MUX_DIFF_0_1) 0x0000  ;# Differential P) AIN0, N) AIN1 (default)
    set register(CONFIG_MUX_DIFF_0_3) 0x1000  ;# Differential P) AIN0, N) AIN3
    set register(CONFIG_MUX_DIFF_1_3) 0x2000  ;# Differential P) AIN1, N) AIN3
    set register(CONFIG_MUX_DIFF_2_3) 0x3000  ;# Differential P) AIN2, N) AIN3
    set register(CONFIG_MUX_SINGLE_0) 0x4000  ;# Single-ended AIN0
    set register(CONFIG_MUX_SINGLE_1) 0x5000  ;# Single-ended AIN1
    set register(CONFIG_MUX_SINGLE_2) 0x6000  ;# Single-ended AIN2
    set register(CONFIG_MUX_SINGLE_3) 0x7000  ;# Single-ended AIN3

    set register(CONFIG_PGA_MASK) 0x0E00
    set register(CONFIG_PGA_6_144V) 0x0000  ;# +/-6.144V range
    set register(CONFIG_PGA_4_096V) 0x0200  ;# +/-4.096V range
    set register(CONFIG_PGA_2_048V) 0x0400  ;# +/-2.048V range (default)
    set register(CONFIG_PGA_1_024V) 0x0600  ;# +/-1.024V range
    set register(CONFIG_PGA_0_512V) 0x0800  ;# +/-0.512V range
    set register(CONFIG_PGA_0_256V) 0x0A00  ;# +/-0.256V range

    set register(CONFIG_MODE_MASK) 0x0100
    set register(CONFIG_MODE_CONTIN) 0x0000  ;# Continuous conversion mode
    set register(CONFIG_MODE_SINGLE) 0x0100  ;# Power-down single-shot mode (default)

    set register(CONFIG_DR_MASK) 0x00E0  
    set register(CONFIG_DR_128SPS) 0x0000  ;# 128 samples per second
    set register(CONFIG_DR_250SPS) 0x0020  ;# 250 samples per second
    set register(CONFIG_DR_490SPS) 0x0040  ;# 490 samples per second
    set register(CONFIG_DR_920SPS) 0x0060  ;# 920 samples per second
    set register(CONFIG_DR_1600SPS) 0x0080  ;# 1600 samples per second (default)
    set register(CONFIG_DR_2400SPS) 0x00A0  ;# 2400 samples per second
    set register(CONFIG_DR_3300SPS) 0x00C0  ;# 3300 samples per second (also 0x00E0)

    set register(CONFIG_CMODE_MASK) 0x0010
    set register(CONFIG_CMODE_TRAD) 0x0000  ;# Traditional comparator with hysteresis (default)
    set register(CONFIG_CMODE_WINDOW) 0x0010  ;# Window comparator

    set register(CONFIG_CPOL_MASK)      0x0008
    set register(CONFIG_CPOL_ACTVLOW)   0x0000  ;# ALERT/RDY pin is low when active (default)
    set register(CONFIG_CPOL_ACTVHI)    0x0008  ;# ALERT/RDY pin is high when active

    set register(CONFIG_CLAT_MASK)      0x0004  ;# Determines if ALERT/RDY pin latches once asserted
    set register(CONFIG_CLAT_NONLAT)    0x0000  ;# Non-latching comparator (default)
    set register(CONFIG_CLAT_LATCH)     0x0004  ;# Latching comparator

    set register(CONFIG_CQUE_MASK)  0x0003
    set register(CONFIG_CQUE_1CONV) 0x0000  ;# Assert ALERT/RDY after one conversions
    set register(CONFIG_CQUE_2CONV) 0x0001  ;# Assert ALERT/RDY after two conversions
    set register(CONFIG_CQUE_4CONV) 0x0002  ;# Assert ALERT/RDY after four conversions
    set register(CONFIG_CQUE_NONE)  0x0003  ;# Disable the comparator and put ALERT/RDY in high state (default)
    
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
    set register(CONFIG)     0x01
    set register(LO_THRESH)  0x02
    set register(HI_THRESH)  0x03

    # Initialisation réalisée
    set register($adresse_I2C(0),init_done) 0
    set register($adresse_I2C(1),init_done) 0
    set register($adresse_I2C(2),init_done) 0
    set register($adresse_I2C(3),init_done) 0
    
}

# Cette proc est utilisée pour initialiser les modules
proc ::ADS1015::init {index} {
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


# Lecture continue
# /usr/local/sbin/i2cset -y 1 0x48 0x01 0x04 0x83 i
proc ::ADS1015::read {index sensor} {
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
    
    # On construit la config 
    # CONFIG_CQUE_NONE      0x0003
    # CONFIG_CLAT_NONLAT    0x0000
    # CONFIG_CPOL_ACTVLOW   0x0000
    # CONFIG_CMODE_TRAD     0x0000
    # CONFIG_MODE_SINGLE    0x0100
    #                       0x0103 (259)
    set config [expr $register(CONFIG_CQUE_NONE)    | \
                     $register(CONFIG_CLAT_NONLAT)  | \
                     $register(CONFIG_CPOL_ACTVLOW) | \
                     $register(CONFIG_CMODE_TRAD)   | \
                     $register(CONFIG_MODE_SINGLE)]
                     
    # Sélection de la vitesse
    # CONFIG_DR_1600SPS     0x0080
    #                       0x0183
    set config [expr $config | $register(CONFIG_DR_1600SPS)]
    
    # Set PGA/voltage range, defaults to +-6.144V
    # CONFIG_PGA_4_096V     0x0200
    #                       0x0383
    # CONFIG_PGA_6_144V     0x0000
    #                       0x0103
    set config [expr $config | $register(CONFIG_PGA_4_096V)]
    
    # Select channel
    # CONFIG_MUX_SINGLE_0   0x4000
    #               4.096   0x4383
    #               6.144   0x4183
    # CONFIG_MUX_SINGLE_1   0x5000
    # CONFIG_MUX_SINGLE_2   0x6000
    # CONFIG_MUX_SINGLE_3   0x7000
    set config [expr $config | $register(CONFIG_MUX_SINGLE_0)]
    
    # Start acquisition
    # CONFIG_OS_SINGLE      0x8000
    #               4.096   0xC383 (50051)
    #               6.144   0xC183
    # 4.096 Voie 1 : 0xC383
    # 4.096 Voie 2 : 0xD383
    # 4.096 Voie 3 : 0xE383
    # 4.096 Voie 4 : 0xF383
    set config [expr $config | $register(CONFIG_OS_SINGLE)]
    
    # Exriture des registres 
    # On calcul les deux octets 
    set lsb [expr $config % 256]
    set msb [expr $config / 256]
    set RC [catch {
        # 4.096 
        # Voie 1  /usr/local/sbin/i2cset -y 1 0x48 0x01 0xC3 0x83 i
        # Voie 2  /usr/local/sbin/i2cset -y 1 0x48 0x01 0xD3 0x83 i
        # Voie 3  /usr/local/sbin/i2cset -y 1 0x48 0x01 0xE3 0x83 i
        # Voie 4  /usr/local/sbin/i2cset -y 1 0x48 0x01 0xF3 0x83 i
        exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $register(CONFIG) $msb $lsb i
    } msg]
    
    # On attend le temps de conversion 
    after 10
    
    # Tension   Valeure attendue
    # 2V        
    
    if {$RC != 0} {
        ::piLog::log [clock milliseconds] "error" "::ADS1015::read Module $moduleAdresse does not respond to setting config :$msg "
    } else {
        # lecture de l'état des entrées
        # /usr/local/sbin/i2cget -y 1 0x48 0x00 w
        set RC [catch {
            set value [exec /usr/local/sbin/i2cget -y 1 $moduleAdresse $register(CONVERSION) w ]
        } msg]
        if {$RC != 0} {
            ::piLog::log [clock milliseconds] "error" "::ADS1015::read Module $moduleAdresse does not respond :$msg "
        } else {

            # On remet dans le bon ordre
            set valueOrdre "0x[string range $value 4 5][string range $value 2 3]"
            
            # On applique les coefficients
            set max $::configXML(sensor,${sensor},max)
            set min $::configXML(sensor,${sensor},min)
            
            set tension [expr ($valueOrdre / 32768.0) * (4.096)]
            
            set goodValue [expr ($tension / 4.096) * ($max - $min) + $min ]
        }
    }
 
    return $goodValue
}
