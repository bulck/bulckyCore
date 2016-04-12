
proc cuveLoop {idxCuve} {

    set zoneNom         $::configXML(zone,${idxCuve},name)
    set engrais1Actif   $::configXML(zone,${idxCuve},engrais,1,actif)
    set engrais2Actif   $::configXML(zone,${idxCuve},engrais,2,actif)
    set engrais3Actif   $::configXML(zone,${idxCuve},engrais,3,actif)
    set IP              $::configXML(zone,${idxCuve},ip)

    # On vérifie toute les 10 secondes le niveau d'eau
    
    # Si il est inférieur au niveau bas on remplie
    
    
    #---------------  Aplication des engrais
    # Au début de chaque heure, on charge en engrais
    set heure  [expr [clock format [clock seconds] -format "%H"] + 0]
    set heure  [string trimleft $heure "0"]
    if {$heure == ""} {set heure 0}
    set minute [expr [clock format [clock seconds] -format "%M"] + 0]
    set minute  [string trimleft $minute "0"]
    if {$minute == ""} {set minute 0}
    
    if {$heure != $::configXML(zone,${idxCuve},engraisappliquee) && $minute < 10 } {
        # On applique les engrais
        for {set i 1} {$i < 4} {incr i} {
        
            set engraisActif   $::configXML(zone,${idxCuve},engrais,$i,actif)
        
            if {$engraisActif == "true"} {
                set engraistmps   $::configXML(zone,${idxCuve},engrais,${i},temps)
                set engraisprise  $::configXML(zone,${idxCuve},engrais,${i},prise)
                
                ::piLog::log [clock milliseconds] "info" "engrais : ZONE $zoneNom : ON ENGRAIS ${i} pendant $engraistmps s "; update
                ::piServer::sendToServer $::piServer::portNumber(serverPlugUpdate) "$::piServer::portNumber(${::moduleLocalName}) 0 setRepere $engraisprise on $engraistmps" $IP 
            }
        }


        # On sauvegarde la dernière heure 
        set ::configXML(zone,${idxCuve},engraisappliquee) $heure
    }
    

    # On lance l'iteration suivante 
    after [expr 1000 * 10] [list after idle cuveLoop $idxCuve]
}
