
set dir [file dirname [file normalize [info script]]]


## ODFi Common package ###############################################################
package ifneeded odfi::common 1.0.0 [list source [file join $dir common.tm]]

package ifneeded odfi::log 1.0.0 [list source [file join $dir log-1.0.0.tm]]

package ifneeded odfi::dom    1.0.0 [list source [file join $dir dom.tm]]

package ifneeded odfi::bits   1.0.0 [list source [file join $dir bits.tm]]

package ifneeded odfi::list   1.0.0 [list source [file join $dir list.tm]]
package ifneeded odfi::list   2.0.0 [list source [file join $dir list-2.0.0.tm]]
package ifneeded odfi::list   3.0.0 [list source [file join $dir list-3.0.0.tm]]
package ifneeded odfi::flist  1.0.0 [list source [file join $dir flist-1.0.tm]]

package ifneeded odfi::flextree 1.0.0 [list source [file join $dir flextree-1.0.tm]]

package ifneeded odfi::attributes 1.0.0 [list source [file join $dir attributes-1.0.tm]]


package ifneeded odfi::tests   1.0.0 [list source [file join $dir tests-1.0.0.tm]]

package ifneeded odfi::closures   2.0.0 [list source [file join $dir closures-2.0.0.tm]]
package ifneeded odfi::closures   2.1.0 [list source [file join $dir closures-2.1.0.tm]]
package ifneeded odfi::closures   3.0.0 [list source [file join $dir closures-3.0.0.tm]]

package ifneeded odfi::richstream   3.0.0 [list source [file join $dir richstream-3.0.0.tm]]

package ifneeded odfi::events   1.0.0 [list source [file join $dir events-1.0.0.tm]]



package ifneeded odfi::tool       1.0.0 [list source [file join $dir tool-1.0.0.tm]]
package ifneeded odfi::tool       2.0.0 [list source [file join $dir tool-2.0.0.tm]]

package ifneeded odfi::files   1.0.0 [list source [file join $dir files-1.0.0.tm]]
package ifneeded odfi::files   2.0.0 [list source [file join $dir files-2.0.0.tm]]

package ifneeded odfi::git   1.0.0 [list source [file join $dir git-1.0.0.tm]]

package ifneeded odfi::ewww             1.0.0 [list source [file join $dir ewww ewww-1.0.0.tm]]
package ifneeded odfi::ewww::webdata   1.0.0 [list source [file join $dir ewww webdata-1.0.0.tm]]

package ifneeded odfi::nx::domainmixin   1.0.0 [list source [file join $dir nx-domainmixin.tm]]

package ifneeded odfi::language 1.0.0 [list source [file join $dir language/language-1.0.0.tm]]


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
