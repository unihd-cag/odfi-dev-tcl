package provide odfi::log 1.0.0
package require odfi::common

namespace eval odfi::log {

    variable prefix ""

    variable pipeOut stdout
    variable pipeIn  stdin

    ## Filtering 
    ###################
    
    ## FORMAT: {PATH LEVEL PATH LEVEL}
    variable loggersLevels {}

    proc setLogLevel {path level} {

        ##search 
        set pathIndex [lsearch -exact $::odfi::log::loggersLevels $path]
    }

    ## Methods 
    #######################

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
            set frameInfo [::info frame -2]

            ## Get 'method', otherwise pick first element in cmd
            set methodIndex [lsearch -exact $frameInfo method] 
            if {$methodIndex!=-1} {
                set commandName [lindex $frameInfo [expr $methodIndex+1]]
            } else {
                set commandName [lindex [lindex $frameInfo 5] 0]
            }

            set commandName [regsub -all {:} $commandName ""]

            #::puts "Log frame info: $frameInfo"
            
            return $logRealm.$commandName
    }
    proc info {message args} {


        ::puts $odfi::log::pipeOut "[prefix][getLogPath] \[INFO\] $message"
        ::flush $odfi::log::pipeOut


    }

    proc fine {message args} {


        ::puts $odfi::log::pipeOut "[prefix][getLogPath] \[FINE\] $message"
        ::flush $odfi::log::pipeOut
       

      


    }

    proc error {message args} {

        ::puts stderr "[prefix][getLogPath] \[ERROR\] $message"
        ::flush stderr


    }

    proc warning {message args} {

        
        ::puts $odfi::log::pipeOut "[prefix][getLogPath] \[WARN\] $message"
        ::flush $odfi::log::pipeOut



    }


 


}
