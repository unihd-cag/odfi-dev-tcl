package provide odfi::log 1.0.0
package require odfi::common

namespace eval odfi::log {

    variable prefix ""

    variable pipeOut stdout
    variable pipeIn  stdin

    proc prefix args {
        return $odfi::log::prefix
    }

    proc getLogPath args {
  

            ## Get Log Realm
            set argRealm [lsearch -exact $args -realm]
            if {$argRealm!=-1} {
                set logRealm [lindex $args [expr $argRealm+1]]
            } else {
                set logRealm [uplevel 2 namespace current]  
            }

            set logRealm [regsub -all {::} $logRealm "."]

            ## Get Command path 
            set frameInfo [::info frame 2]
            set commandName [lindex [lindex $frameInfo 5] 0]
            set commandName [regsub -all {:} $commandName ""]

           # ::puts "Log frame info: $frameInfo"
            
            return $logRealm.$commandName
    }
    proc info {message args} {


        ::puts $odfi::log::pipeOut "[prefix][getLogPath] \[INFO\] $message"
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
