
proc setPluga {filename adressList} {

    set fid [open $filename w+]

    set nbAdress [llength $adressList]
    if {$nbAdress < 10} {
        set nbAdress "$0{nbAdress}"
    }

    puts $fid $nbAdress

    foreach adress $adressList {
        puts $fid $adress
    }

    close $fid

}
