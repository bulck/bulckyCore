

proc displayProcess {} {

    catch {
        puts "* Liste des process : "
        puts [exec ps aux | grep tclsh]
    }

}