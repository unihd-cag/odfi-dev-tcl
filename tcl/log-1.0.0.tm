package provide odfi::log 1.0.0
package require odfi::common

namespace eval odfi::log {

    variable prefix ""

    variable pipeOut stdout
    variable pipeIn  stdin

    proc prefix args {
        return $odfi::log::prefix
    }

    proc info {message args} {

        set argRealm [lsearch -exact $args -realm]
        if {$argRealm!=-1} {
            set logRealm [lindex $args [expr $argRealm+1]]
        } else {
            set logRealm [uplevel 1 namespace current]  
        }

        set logRealm [regsub -all {::} $logRealm "."]

       

        ::puts $odfi::log::pipeOut "[prefix]$logRealm \[INFO\] $message"
        ::flush $odfi::log::pipeOut


    }

    proc fine {message args} {

        set argRealm [lsearch -exact $args -realm]
        if {$argRealm!=-1} {
            set logRealm [lindex $args [expr $argRealm+1]]
        } else {
            set logRealm [uplevel 1 namespace current]  
        }

        set logRealm [regsub -all {::} $logRealm "."]

       

        ::puts "${prefix}$logRealm \[FINE\] $message"


    }

    proc error {message args} {

        set argRealm [lsearch -exact $args -realm]
        if {$argRealm!=-1} {
            set logRealm [lindex $args [expr $argRealm+1]]
        } else {
            set logRealm [uplevel 1 namespace current]  
        }

        set logRealm [regsub -all {::} $logRealm "."]

       

        ::puts stderr "${prefix}$logRealm \[ERROR\] $message"
        ::error $message


    }

    proc warning {message args} {

        set argRealm [lsearch -exact $args -realm]
        if {$argRealm!=-1} {
            set logRealm [lindex $args [expr $argRealm+1]]
        } else {
            set logRealm [uplevel 1 namespace current]  
        }

        set logRealm [regsub -all {::} $logRealm "."]

    
        ::puts stderr "${prefix}$logRealm \[WARN\] $message"


    }


 


}
