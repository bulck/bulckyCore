# A ajouter dans la conf pour que �a marche :
#  <item name="module_CULTIPI,ip,0" ip="192.168.1.10" />

namespace eval ::CULTIPI {
    variable adresse_module

    # Adresse pour d'autre cultipi (10 modules)
    # @1000 --> 1176
    for {set j 0} {$j < 10} {incr j} {
        for {set i 0} {$i < 16} {incr i} {
            set adresse_module([expr 1000 + 16 * $j + $i],module_numero) $j
            set adresse_module([expr 1000 + 16 * $j + $i],prise) $i
        }
    }

}

# Cette proc est utilis�e pour initialiser les modules
proc ::CULTIPI::init {plugList} {

    for {set j 0} {$j < 10} {incr j} {
        if {[array get ::configXML module_CULTIPI,ip,$j] == ""} {
            set ::configXML(module_CULTIPI,ip,$j) "NA"
        }
    }

}

proc ::CULTIPI::setValue {plugNumber value address} {
    variable adresse_module

    set errorDuringSend 0
    
    # On cherche le nom du module correspondant
    set cultipi_numero "NA"
    # Il faut que la cl� existe
    if {[array get adresse_module $address,module_numero] != ""} {
        set cultipi_numero $adresse_module($address,module_numero)
        set cultipi_prise $adresse_module($address,prise)
    }        

    if {$cultipi_numero == "NA"} {
        ::piLog::log [clock milliseconds] "error" "::CULTIPI::setValue Adress $address does not exists "
        set errorDuringSend 1
        return $errorDuringSend
    }

    if {$::configXML(module_CULTIPI,ip,$cultipi_numero) == "NA"} {
        ::piLog::log [clock milliseconds] "error" "::CULTIPI::setValue Adress of module does not exists "
        set errorDuringSend 1
        return $errorDuringSend
    }

    # On sauvegarde l'�tat de la prise
    ::savePlugSendValue $plugNumber $value

    # On pilote la prise en sortie
    ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(serverPlugUpdate) 0 setRepere $cultipi_prise $value 86399" $::configXML(module_CULTIPI,ip,$cultipi_numero)

    return $errorDuringSend
}