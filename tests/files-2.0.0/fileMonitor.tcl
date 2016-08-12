
source  [file dirname [info script]]/../../tcl/pkgIndex.tcl

package require odfi::files 2.0.0


set monitor [::odfi::files::newFileMonitor ""  [file dirname [info script]]/filechange {

    puts "File Changed $f "
}]

$monitor start

vwait forever