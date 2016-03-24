
# Module 0
# Init : /usr/local/sbin/i2cset -y 1 0x20 0x00 0x00
# Pilotage pin0 : /usr/local/sbin/i2cset -y 1 0x20 0x09 0x01

namespace eval ::DIRECT {
    variable adresse_module
    variable adresse_I2C
    variable register
    variable pin

    set pin(1,GPIO) 16
    set pin(2,GPIO) 20
    set pin(3,GPIO) 21
    set pin(4,GPIO) 26
    set pin(5,GPIO) 19
    set pin(6,GPIO) 13
    set pin(7,GPIO) 6
    set pin(8,GPIO) 5
    
    # Pin 1 bis
    set pin(10,GPIO) 23
    # Pin 2 bis
    set pin(11,GPIO) 24

    # Initialisation réalisée
    for {set i 1} {$i < 12} {incr i} {
        set register($i,init_done) 0
        set register($i,errormessage) 0
    }

}

# Cette proc est utilisée pour initialiser les modules
proc ::DIRECT::init {index} {
    variable adresse_module
    variable adresse_I2C
    variable register
    variable pin

    set pinIndex "NA"
    if {[array get adresse_I2C $index] != ""} {
        set pinIndex $pin($index,GPIO)
    }
    
    if {$pinIndex == "NA"} {
        ::piLog::log [clock milliseconds] "error" "::DIRECT::init Pin for $index does not exists "
        return
    }
    
    # On définit la pin en entrée
    set RC [catch {
        exec gpio -g mode $pin($index,GPIO) in
    } msg]
    if {$RC != 0} {
        ::piLog::log [clock milliseconds] "error" "::DIRECT::initPin Not able to defined pin $pin($index,GPIO) as input -$msg-"
    } else {
        ::piLog::log [clock milliseconds] "info" "::DIRECT::init Pin $pin($index,GPIO) init Input OK"
        set register($index,init_done) 1
    }
}

proc ::DIRECT::read {index sensor} {
    variable register
    variable pin
    
    # S'il elle n'est pas initialisée, on le fait
    if {$register($index,init_done) == 0} {
        ::DIRECT::init $index
    }
    
    set value "NA"
    set RC [catch {
        set value [exec gpio -g read $pin($index,GPIO)]
    } msg]

    if {$RC != 0} {
        if {$register($index,errormessage) == ""} {
            ::piLog::log [clock milliseconds] "error" "::DIRECT::read default when reading value of input $index (GPIO : $pin($index,GPIO)) message:-$msg-"
        }
        set register($index,errormessage) "error is already send"
    } else {
        ::piLog::log [clock milliseconds] "debug" "::DIRECT::read input $index (GPIO : $pin($index,GPIO)) value $value"
        set register($index,errormessage) ""
    }
    
    return $value
}
