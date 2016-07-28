package provide odfi::log 1.0.0
package require odfi::common
package require odfi::flextree 1.0.0

namespace eval odfi::log {

    variable prefix ""

    variable pipeOut stdout
    variable pipeIn  stdin

    ## Filtering 
    ###################
    
    ## FORMAT: {PATH LEVEL PATH LEVEL}
    variable loggersLevels {}

    variable availableLevels {
        
        ERROR
        WARN
        INFO
        FINE
        FINER
        DEBUG
    }

    proc setLogLevel {path level} {

        ## verify level
        if {[getLevelValue $level]==-1} {
            error "Wrong Level in setLogLevel: $level, available: ${::odfi::log::availableLevels}"
        }

        ##search 
        set pathIndex [lsearch -exact ${::odfi::log::loggersLevels} $path]
        if {$pathIndex==-1} {
            lappend ::odfi::log::loggersLevels $path $level
        } else {
            set ::odfi::log::loggersLevels [lreplace ${::odfi::log::loggersLevels} [expr $pathIndex +1] [expr $pathIndex +1] $level]
        }
    }
    
    ## Return the value of the log level defined for the pat
    ## If not defined, stick to info
    proc getLogLevelValue path {
    
        
        set pathIndex [lsearch -exact ${::odfi::log::loggersLevels} $path]
        if {$pathIndex==-1} {
            getLevelValue INFO
        } else {
            getLevelValue [lindex ${::odfi::log::loggersLevels} [expr $pathIndex +1]]
        }
    }
    
    proc getLevelValue level {
        return [lsearch -exact ${::odfi::log::availableLevels} $level]
    }
    
    ## If the level for path is smaller than the tested level, refuse
    proc isLevelEnabled {path level} {
        
        if {[getLogLevelValue $path]<[getLevelValue $level]} {
            return false
        } else {
            return true
        }
    
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

        if {[isLevelEnabled [getLogPath] INFO]} {
            ::puts $odfi::log::pipeOut "[prefix][getLogPath] \[INFO\] $message"
            ::flush $odfi::log::pipeOut
        }


    }

    proc fine {message args} {

        if {[isLevelEnabled [getLogPath] FINE]} {
            ::puts $odfi::log::pipeOut "[prefix][getLogPath] \[FINE\] $message"
            ::flush $odfi::log::pipeOut
        } 

    }
    
    proc debug {message args} {
    
        if {[isLevelEnabled [getLogPath] DEBUG]} {
            ::puts $odfi::log::pipeOut "[prefix][getLogPath] \[DEBUG\] $message"
            ::flush $odfi::log::pipeOut
        } 

    }

    proc error {message args} {

        ::puts stderr "[prefix][getLogPath] \[ERROR\] $message"
        ::flush stderr


    }

    proc warning {message args} {

        
        if {[isLevelEnabled [getLogPath] WARN]} {
        
        ::puts $odfi::log::pipeOut "[prefix][getLogPath] \[WARN\] $message"
        ::flush $odfi::log::pipeOut
        }


    }
    
    proc warn {message args} {
    
        if {[isLevelEnabled [getLogPath] WARN]} {    
            ::puts $odfi::log::pipeOut "[prefix][getLogPath] \[WARN\] $message"
            ::flush $odfi::log::pipeOut
        
         }



    }


    ## Class Based Logging
    ###################
    nx::Class create Logger -superclass {::odfi::flextree::FlexNode} {
    
        :object variable -accessor public levels {
            ERROR
            WARN
            INFO
            FINE
            FINER
            DEBUG
        }
        
        :variable -accessor public prefix "" 
            
    
        :public method setPrefix p {
            set :prefix $p
            :prefix set $p
        }
    
        :public method info msg {
        
        }
        
        :public method debug msg {
            puts "[:prefix get] >> [:getCallingCommand] >> DEBUG >> $msg"
        }
        
        :public method getCallingCommand args {
        
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
            
            return $commandName
        }
        
    }
 


}
