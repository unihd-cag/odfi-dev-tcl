## Systen tcl XML package ##

#package ifneeded dom [load /usr/lib/]

#source /usr/lib/Tclxml3.2/pkgIndex.tcl


## ODFi Common package ###############################################################
package ifneeded odfi::common 1.0.0 [list source [file join $dir common.tm]]
package ifneeded odfi::dom    1.0.0 [list source [file join $dir dom.tm]]
package ifneeded odfi::bits   1.0.0 [list source [file join $dir bits.tm]]
package ifneeded odfi::list   1.0.0 [list source [file join $dir list.tm]]

package ifneeded odfi::ewww   1.0.0 [list source [file join $dir ewww ewww-1.0.0.tm]]

## External :Tkcon ####################
package ifneeded tkcon::odfi 2.5 [subst {
    
     ## Check we have tkCon downloaded
    set ::tkConSrcPath "$dir/../external/tkcon.tcl"
    if {[file isfile "$dir/../external/tkcon.tcl"]==0} {
        
        catch {exec wget "http://tkcon.cvs.sourceforge.net/viewvc/tkcon/tkcon/tkcon.tcl?revision=HEAD" -O "$dir/../external/tkcon.tcl"} res
        
    }
     
     namespace eval ::tkcon {}
     set ::tkcon::PRIV(showOnStartup) 0
     set ::tkcon::PRIV(protocol) {tkcon hide}
     set ::tkcon::OPT(exec) ""
     package require Tk
     tclPkgSetup [list $dir] tkcon 2.5 {
         {"$dir/../external/tkcon.tcl" source {tkcon dump idebug observe}}
     }
 }]