

proc checkbutton {} {


    
    for {set i 0} {$i < $::configXML(nbzone)} {incr i} {
        
        set listeButton ""
        
        for {set j 0} {$j < $::configXML(nbzone)} {incr i} {
        
        
        # Cette proc permet de mettre à jour les variable de cuve
        lappend listeButton

    }
    
    after [expr 1000] [list after idle checkbutton]
    
}


