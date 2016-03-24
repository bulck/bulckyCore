# Pour que ça marche, ajouter dans la conf :


namespace eval ::I2C {
    variable init
    variable sensorCO2Num
    variable errorMessage
    set init 0
    set sensorCO2Num ""
    set errorMessage ""
   
}

# Cette proc est utilisée pour initialiser les variables
proc ::I2C::init {nb_maxSensor} {

}


proc ::I2C::read {index sensor} {
    variable init
    variable sensorCO2Num
    variable errorMessage

    set value "NA"
    
    return $value
}
