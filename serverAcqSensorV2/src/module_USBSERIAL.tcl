
# set fh [open //./COM23  RDWR]
# fconfigure $fh -blocking 0 -mode 38400,n,8,1
# puts $fh "i"
# flush $fh 
# read $fh
# close $fh

namespace eval ::USBSERIAL {

}

# Cette proc est utilisée pour initialiser les modules
proc ::USBSERIAL::init {index} {

}

proc ::USBSERIAL::read {index sensor} {
    return "NA"
}
