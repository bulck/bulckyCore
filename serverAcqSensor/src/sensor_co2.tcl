# Pour que �a marche, ajouter dans la conf :


namespace eval ::sensor_co2 {
    variable init
    variable sensorCO2Num
    variable errorMessage
    set init 0
    set sensorCO2Num ""
    set errorMessage ""
   
}

# Cette proc est utilis�e pour initialiser les variables
proc ::sensor_co2::init {nb_maxSensor} {

    variable init
    variable sensorCO2Num
    variable errorMessage
    
    for {set i 1} {$i <= $nb_maxSensor} {incr i} {
        if {[array get ::configXML sensor,$i,source] == ""} {
            set ::configXML(sensor,$i,source) "rj12"
        }
        
        if {[array get ::configXML sensor,$i,type] == ""} {
            set ::configXML(sensor,$i,type) "0"
        }
                
        if {$::configXML(sensor,$i,source) == "rs232" && $::configXML(sensor,$i,type) == "10"} {
        
            # Il y a un capteur de CO�, on l'initialise
            ::piLog::log [clock milliseconds] "debug" "::sensor_co2::init CO� sensor : Init it !"
            
            set RC [catch {
                set fid [open /dev/ttyAMA0 RDWR]
                fconfigure $fid -blocking 0 -buffering none \
                        -mode 9600,n,8,1 -translation binary -eofchar {}
                puts -nonewline $fid "K 2\r\n"
                flush $fid
                
                after 30
                
                read $fid
                
                close $fid
            } msg]
            if {$RC != 0} {
                ::piLog::log [clock milliseconds] "error" "::sensor_co2::init default when initializing CO� sensor  message:-$msg-"
            } else {
                ::piLog::log [clock milliseconds] "debug" "::sensor_co2::init CO� sensor initialized"
            }
            
            set init 1
            
            # On sauvegarde le num�ro du capteur
            set sensorCO2Num $i
            
            set ::sensor($sensorCO2Num,type) 10
            # Il ne peut y avoir qu'un seul capteur
            break
            
        }
    }
}


proc ::sensor_co2::read_value {} {
    variable init
    variable sensorCO2Num
    variable errorMessage

    if {$init == 0 || $sensorCO2Num == ""} {
        return ""
    }
    
    set value "NA"
    set RC [catch {
        set fid [open /dev/ttyAMA0 RDWR]
        fconfigure $fid -blocking 0 -buffering none \
                -mode 9600,n,8,1 -translation binary -eofchar {}
        # On purge les donn�es en attente
        read $fid
        
        # On demande une donn�e
        puts -nonewline $fid "Z\r\n"
        flush $fid
        after 30
        
        # On lit la valeur
        set rawData [read $fid]
        close $fid
    } msg]

    # On analyse la chaine de caract�re
    set data [lindex $rawData 1]
    set value [string trimleft $data "0"]
    
    if {$RC != 0} {
        if {$errorMessage == ""} {
            ::piLog::log [clock milliseconds] "error" "::sensor_co2::read_value default when reading value of CO� sensor  message:-$msg-"
        }
        set errorMessage "error is already send"
    } else {
        ::piLog::log [clock milliseconds] "debug" "::sensor_co2::read_value CO� sensor value $value"
        set errorMessage ""
    }
    
    # On sauvegarde dans le rep�re global
    set ::sensor($sensorCO2Num,value,1) $value
    set ::sensor($sensorCO2Num,value)   "$value NULL"
    set ::sensor($sensorCO2Num,value,time) [clock milliseconds]
    
    
    return $value
}
