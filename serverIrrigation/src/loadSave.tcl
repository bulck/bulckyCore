
proc loadConfig {} {

    set rootDir [file dirname [info script]]
    source [file join $rootDir config.tcl]

}

proc saveConfig {} {

    # Vérification avant sauvegarde
    if {$::TempEngraisEau == 0 && 
        $::TempEngrais1 == 0 && 
        $::TempEngrais2 == 0 && 
        $::TempEngrais3 == 0} {
        tk_messageBox -message "Vous devez sélectionner au moins un type d'engrais. Sauvegarde annulée"
        return
    }

    set rootDir [file dirname [info script]]

    set fid [open [file join $rootDir config.tcl] w+]

    foreach plateforme $::listePlateforme {
    
        for {set i 1} {$i < 4} {incr i} {
        
            if {$::prise(${plateforme},ev,${i}) != "NA"} {
                puts $fid "set TempTempsOn(${plateforme},ev,${i}) $::TempTempsOn(${plateforme},ev,${i})"
                puts $fid "set TempsOn(${plateforme},ev,${i}) $::TempTempsOn(${plateforme},ev,${i})"
                set ::TempsOn(${plateforme},ev,${i}) $::TempTempsOn(${plateforme},ev,${i})
                
                puts $fid "set TempTempsOff(${plateforme},ev,${i}) $::TempTempsOff(${plateforme},ev,${i})"
                puts $fid "set TempsOff(${plateforme},ev,${i}) $::TempTempsOff(${plateforme},ev,${i})"
                set ::TempsOff(${plateforme},ev,${i}) $::TempTempsOff(${plateforme},ev,${i})
                
                puts $fid "set TempActiv(${plateforme},ev,${i}) $::TempActiv(${plateforme},ev,${i})"
                puts $fid "set Activ(${plateforme},ev,${i}) $::TempActiv(${plateforme},ev,${i})"
                set ::Activ(${plateforme},ev,${i}) $::TempActiv(${plateforme},ev,${i})
            }
        


        }
        
        puts $fid "set TempActiv(${plateforme}) $::TempActiv(${plateforme})"
        puts $fid "set Activ(${plateforme}) $::TempActiv(${plateforme})"
        set ::Activ(${plateforme}) $::TempActiv(${plateforme})
        
        puts $fid "set TempTempsPerco(${plateforme}) $::TempTempsPerco(${plateforme})"
        puts $fid "set TempsPerco(${plateforme}) $::TempTempsPerco(${plateforme})"
        set ::TempsPerco(${plateforme}) $::TempTempsPerco(${plateforme})
        
        puts $fid ""
    
    }
    
    puts $fid "set TempEngraisEau $::TempEngraisEau"
    puts $fid "set EngraisEau $::TempEngraisEau"
    set ::EngraisEau $::TempEngraisEau
    puts $fid "set TempEngrais1 $::TempEngrais1"
    puts $fid "set Engrais1 $::TempEngrais1"
    set ::Engrais1 $::TempEngrais1
    puts $fid "set TempEngrais2 $::TempEngrais2"
    puts $fid "set Engrais2 $::TempEngrais2"
    set ::Engrais2 $::TempEngrais2
    puts $fid "set TempEngrais3 $::TempEngrais3"
    puts $fid "set Engrais3 $::TempEngrais3"
    set ::Engrais3 $::TempEngrais3
    
    puts $fid "set TempTempsMaxRegul(general) $::TempTempsMaxRegul(general)"
    puts $fid "set TempsMaxRegul(general) $::TempTempsMaxRegul(general)"
    set ::TempsMaxRegul(general) $::TempTempsMaxRegul(general)
        
    
    close $fid
    
    tk_messageBox -message "Valeurs sauvegardées et mis à jour dans le programme"

}