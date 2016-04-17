# Pour que ça marche, ajouter dans la conf :


namespace eval ::I2C {
    variable adresse_I2C
    variable register

    # Adresse des modules
    set adresse_I2C(0) 0x01
    set adresse_I2C(1) 0x01
    set adresse_I2C(2) 0x02
    set adresse_I2C(3) 0x02
    set adresse_I2C(4) 0x03
    set adresse_I2C(5) 0x03
    set adresse_I2C(6) 0x04
    set adresse_I2C(7) 0x04
    
    # Numéro de sortie a utiliser 
    set register(SENSOR_GENERIC_HP_ADR)  0x20
    set register(SENSOR_GENERIC_LP_ADR)  0x21
    set register(SENSOR_GENERIC_HP2_ADR) 0x22
    set register(SENSOR_GENERIC_LP2_ADR) 0x23
    set register(0,output,HP) $register(SENSOR_GENERIC_HP_ADR)
    set register(0,output,LP) $register(SENSOR_GENERIC_LP_ADR)
    set register(1,output,HP) $register(SENSOR_GENERIC_HP2_ADR)
    set register(1,output,LP) $register(SENSOR_GENERIC_LP2_ADR)
    set register(2,output,HP) $register(SENSOR_GENERIC_HP_ADR)
    set register(2,output,LP) $register(SENSOR_GENERIC_LP_ADR)
    set register(3,output,HP) $register(SENSOR_GENERIC_HP2_ADR)
    set register(3,output,LP) $register(SENSOR_GENERIC_LP2_ADR)
    set register(4,output,HP) $register(SENSOR_GENERIC_HP_ADR)
    set register(4,output,LP) $register(SENSOR_GENERIC_LP_ADR)
    set register(5,output,HP) $register(SENSOR_GENERIC_HP2_ADR)
    set register(5,output,LP) $register(SENSOR_GENERIC_LP2_ADR)
    set register(6,output,HP) $register(SENSOR_GENERIC_HP_ADR)
    set register(6,output,LP) $register(SENSOR_GENERIC_LP_ADR)
    set register(7,output,HP) $register(SENSOR_GENERIC_HP2_ADR)
    set register(7,output,LP) $register(SENSOR_GENERIC_LP2_ADR)

}

# Cette proc est utilisée pour initialiser les variables
proc ::I2C::init {index} {

}


proc ::I2C::read {index sensor} {
    variable adresse_I2C
    variable register
    
    set value "NA"

    # On cherche l'adresse I2C
    set moduleAdresse "NA"
    if {[array get adresse_I2C $index] != ""} {
        set moduleAdresse $adresse_I2C($index)
    }
    if {$moduleAdresse == "NA"} {
        ::piLog::log [clock milliseconds] "error" "::I2C::read index $index pas d'adresse I2C "
        return $value
    }
    
    # On cherche le registre de lecture
    set moduleRegistreHP "NA"
    set moduleRegistreLP "NA"
    if {[array get register "${index},output,HP"] != ""} {
        set moduleRegistreHP $register(${index},output,HP)
    }
    if {$moduleRegistreHP == "NA"} {
        ::piLog::log [clock milliseconds] "error" "::I2C::read index $index sortie HP non définie "
        return $value
    }
    if {[array get register "${index},output,LP"] != ""} {
        set moduleRegistreLP $register(${index},output,LP)
    }
    if {$moduleRegistreLP == "NA"} {
        ::piLog::log [clock milliseconds] "error" "::I2C::read index $index sortie LP non définie "
        return $value
    }
    

    # On vient lire la valeur
    set valueHP ""
    set valueLP ""
    set RC [catch {
        exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $moduleRegistreHP
        set valueHP [exec /usr/local/sbin/i2cget -y 1 $moduleAdresse]
        after 10
        exec /usr/local/sbin/i2cset -y 1 $moduleAdresse $moduleRegistreLP
        set valueLP [exec /usr/local/sbin/i2cget -y 1 $moduleAdresse]
    } msg]

    if {$RC != 0} {
        ::piLog::log [clock milliseconds] "error" "::I2C::read index $index : Erreur lors de la lecture $msg"
        return $value
    } 

    set computedValue [expr ($valueHP * 256 + $valueLP) / 100.0]
    
    # Seulement si la valeur est cohérente
    if {$computedValue < 100 && $computedValue > -30} {
        set value $computedValue
    } else {
        ::piLog::log [clock milliseconds] "error" "::I2C::read index $index : La valeur n'est pas cohérente $computedValue"
    }
    
    return $value
}
