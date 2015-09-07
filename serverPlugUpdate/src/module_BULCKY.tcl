
# Module 0
# Init : /usr/local/sbin/i2cset -y 1 0x20 0x00 0x00
# Pilotage pin0 : /usr/local/sbin/i2cset -y 1 0x20 0x09 0x01

namespace eval ::BULCKY {
    variable module_bulcky
    variable prise_blucky
    variable register
    
    # Initialisation des variables de chaque prise
    for {set module 0} {$module < 3} {incr module} {
        for {set prise 0} {$prise < 4} {incr prise} {
            set prise_blucky([expr 2000 + 10 * $module + $prise],module) $module
            
            set prise_blucky([expr 2000 + 10 * $module + $prise],plug) [expr $prise + 1]
            
        }
    }

    # Initialisation des variable de chaque module
    for {set module 0} {$module < 3} {incr module} {
    
        set module_bulcky($module,peripherique) "NA"
        set module_bulcky($module,id) "NA"
        set module_bulcky($module,fid) ""
    
    }

    # Définition des registres
    set register(VARIABLE)  "a"
    set register(VERSION)   "i"
    set register(UUID)      "j"
    set register(HELP)      "h"
    set register(DIMMER,1,PERCENT)  "d"
    set register(DIMMER,2,PERCENT)  "e"
    set register(DIMMER,3,PERCENT)  "f"
    set register(DIMMER,4,PERCENT)  "g"
    set register(DIMMER,1,MODE)     "u"
    set register(DIMMER,2,MODE)     "v"
    set register(DIMMER,3,MODE)     "w"
    set register(DIMMER,4,MODE)     "x"
    set register(EOL)               ";"
    
}


proc ::BULCKY::putC {ComPort commande} {
    variable register
    variable module_bulcky
    
    set fid $module_bulcky($ComPort)
    
    # On purge les données en attente
    read $fid
    # On envoi la commande
    puts $fid "${commande}$register(EOL)"
    flush $fid

    return 0
}

proc ::BULCKY::getC {ComPort commande} {
    variable register
    variable module_bulcky
    
    set fid $module_bulcky($ComPort)
    
    # On purge les données en 
    read $fid
    
    # On envoi la commande
    puts $fid "${commande}$register(EOL)"
    flush $fid
    
    # On attend la réponse
    after 1000
    
    # On lit la réponse
    set rawData [read $fid]
    
    return $rawData
}



# Cette proc est utilisée pour initialiser les modules
proc ::BULCKY::init {plugList} {
    variable module_bulcky
    variable prise_blucky
    variable register

    # Lecture du fichier de config
    set confFileName [string map {"conf.xml" "bulcky.xml"} $::confXML]
    if {[file exists $confFileName]} {
        array set module_bulcky [::piXML::convertXMLToArray $confFileName]
    } else {
        ::piLog::log [clock milliseconds] "info" "::BULCKY::init  No XML conf file name bulcky.xml "
    }
    
    # On recherche les périphérique USB branché
    set ListCom {}
    switch [string tolower $::tcl_platform(os)] {
        "windows nt" {
            catch {
                package require registry
                set serial_base [join {
                        HKEY_LOCAL_MACHINE
                        HARDWARE
                        DEVICEMAP
                        SERIALCOMM} \\]
                set values [ registry values $serial_base ]
                foreach value $values {
                    lappend ListCom \\\\.\\[registry get $serial_base $value]
                }
            }
        }
        linux {
            set ListCom [glob -nocomplain {/dev/ttyS[0-9]} {/dev/ttyUSB[0-9]}]
        }
        netbsd {
            set ListCom [glob -nocomplain {/dev/tty0[0-9]} {/dev/ttyU[0-9]}]
        }
        openbsd {
            set ListCom [glob -nocomplain {/dev/tty0[0-9]} {/dev/ttyU[0-9]}]
        }
        freebsd {
                # todo
        }
        default {
                # shouldn't happen
        }
    }
    
    # Pour chaque périphérique 
    set listIDPort ""
    foreach ComPort $ListCom {
    
        # On ouvre la communication
        set module_bulcky($ComPort) [open $ComPort  w+]
        
        fconfigure $module_bulcky($ComPort)  -blocking 0 -buffering none -handshake none \
                        -mode 9600,n,8,1 -translation binary -eofchar {}
    
        # On attend un peu - Il a besoin de 1400ms pour démarrer
        ::piTools::waitMoment 1800 100
    
        # On demande l'identificateur unique UUID 
        set id [getC $ComPort $register(UUID)]
        
        if {[lindex $id 0] == "UUID"} {
            # On sauvegarde
            set idcom($ComPort) [lindex $id 2]
            set comid([lindex $id 2]) $ComPort
            set comid([lindex $id 2],used) 0
            lappend listIDPort [lindex $id 2]
        } else {
            ::piLog::log [clock milliseconds] "info" "::BULCKY::init  No bulcky plugged on $ComPort "
            
            close $module_bulcky($ComPort)
        }
    }

    # On regarde quel doivent être les modules bulcky 
    # Pour chaque prise 
    set listeModule ""
    foreach plug $plugList {
    
        set address $::plug($plug,adress)
    
        set moduleNumber $prise_blucky($address,module)
    
        # Si il n'est pas dans la liste, on l'ajoute
        if {[lsearch $listeModule $moduleNumber] == -1} {
            lappend listeModule $moduleNumber
        }
    }
    
    
    # Pour chaque module 
    foreach  module $listeModule {
    
        # On vérifie si l'identificateur unique est disponible
        set module_bulcky($module,peripherique) "NA"
        if {[array get comid $module_bulcky($module,id)] != ""} {
        
            # Dans ce cas on enregistre temporairement le nom du périphérique 
            set module_bulcky($module,peripherique) $comid($id)
            
            # On indique que l'on utilise 
            set comid($id,used) 1
            
        }
    }
    
    # Pour chaque module 
    foreach  module $listeModule {
        # Si le nom du périphérique n'est pas associé, on prend le premier de libre
        if {$module_bulcky($module,peripherique) == "NA"} {
        
            foreach id $listIDPort {
            
                # Il est disponible donc on l'utilise
                if {$comid($id,used) == 0} {
                
                    # Dans ce cas on enregistre temporairement le nom du périphérique 
                    set module_bulcky($module,peripherique) $comid($id) 
                    set module_bulcky($module,UUID)         $id
                    
                    # On indique que l'on utilise 
                    set comid($id,used) 1
                    
                    break
                }
            
            }
        }
    
        # Si on a pas trouvé de module 
        if {$module_bulcky($module,peripherique) == "NA"} {
            ::piLog::log [clock milliseconds] "error" "::BULCKY::init Not found Bulcky $module ... "
        } else {
            ::piLog::log [clock milliseconds] "info" "::BULCKY::init  Bulcky $module on port $module_bulcky($module,peripherique) UUID $module_bulcky($module,UUID) "
        }
    }
}

proc ::BULCKY::setValue {plugNumber value address} {
    variable module_bulcky
    variable prise_blucky
    variable register

    set errorDuringSend 0
    
    # On cherche le nom du module correspondant
    set moduleIndex "NA"
    set plugIndex   "NA"
    # Il faut que la clé existe
    if {[array get prise_blucky "$address,plug"] != ""} {
        set moduleIndex $prise_blucky($address,module)
        set plugIndex   $prise_blucky($address,plug)
    }        
    
    if {$moduleIndex == "NA"} {
        ::piLog::log [clock milliseconds] "error" "::BULCKY::setValue Address $address does not exists "
        set errorDuringSend 1
        return $errorDuringSend
    }
    
    if {$value == "on"} {set value 100}
    if {$value == "off"} {set value 0}
    
    # On vérifie que le module a bien un adaptateur connecté
    if {$module_bulcky($moduleIndex,peripherique) == "NA"} {
        ::piLog::log [clock milliseconds] "error" "::BULCKY::setValue Module $moduleIndex is not found "
        set errorDuringSend 1
        return $errorDuringSend
    }

    # On pilote le registre de sortie
    
    set RC [catch {
        putC $module_bulcky($moduleIndex,peripherique) "$register(DIMMER,$plugIndex,PERCENT)$value"
    } msg]
    if {$RC != 0} {
        ::piLog::log [clock milliseconds] "error" "::BULCKY::setValue Module $moduleIndex does not respond :$msg "
        set errorDuringSend 1
    } else {
        ::piLog::log [clock milliseconds] "info" "::BULCKY::setValue $moduleIndex to $register(DIMMER,$plugIndex,PERCENT)$value OK"
    }
    
    return $errorDuringSend

}

proc ::BULCKY::setMode {plugNumber mode} {
    variable module_bulcky
    variable prise_blucky
    variable register

    set errorDuringSend 0
    
    set address $::plug($plugNumber,adress)
    
    # On cherche le nom du module correspondant
    set moduleIndex "NA"
    set plugIndex   "NA"
    # Il faut que la clé existe
    if {[array get prise_blucky "$address,plug"] != ""} {
        set moduleIndex $prise_blucky($address,module)
        set plugIndex   $prise_blucky($address,plug)
    }        
    
    if {$moduleIndex == "NA"} {
        ::piLog::log [clock milliseconds] "error" "::BULCKY::setMode Address $address does not exists "
        set errorDuringSend 1
        return $errorDuringSend
    }

    # On traduit les modes 
    if {$mode == "phase"} {set mode 1}
    if {$mode == "cycle"} {set mode 0}
    
    # On vérifie que le module a bien un adaptateur connecté
    if {$module_bulcky($moduleIndex,peripherique) == "NA"} {
        ::piLog::log [clock milliseconds] "error" "::BULCKY::setMode Module $moduleIndex is not found "
        set errorDuringSend 1
        return $errorDuringSend
    }

    # On pilote le registre de sortie
    set RC [catch {
        putC $module_bulcky($moduleIndex,peripherique) "$register(DIMMER,$plugIndex,MODE)$mode"
    } msg]
    if {$RC != 0} {
        ::piLog::log [clock milliseconds] "error" "::BULCKY::setMode Module $moduleIndex does not respond :$msg "
        set errorDuringSend 1
    } else {
        ::piLog::log [clock milliseconds] "info" "::BULCKY::setMode $moduleIndex to $register(DIMMER,$plugIndex,MODE)$mode OK"
    }
    
    return $errorDuringSend

}