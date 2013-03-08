## Systen tcl XML package ##

#package ifneeded dom [load /usr/lib/]

#source /usr/lib/Tclxml3.2/pkgIndex.tcl


## ODFi Common package ###############################################################
package ifneeded odfi::common 1.0.0 [list source [file join $dir common.tm]]
package ifneeded odfi::dom    1.0.0 [list source [file join $dir dom.tm]]
package ifneeded odfi::bits   1.0.0 [list source [file join $dir bits.tm]]
package ifneeded odfi::list   1.0.0 [list source [file join $dir list.tm]]