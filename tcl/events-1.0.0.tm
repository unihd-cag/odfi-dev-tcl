package provide odfi::events 1.0.0
package require odfi::closures 3.0.0
package require nx 2.0.0

namespace eval odfi::events {

    ## Facility to create a new Slot object 
    proc slot args {


    }


    ## Slot Class 
    ####################
    nx::Class create ValueSlot {

        :variable value ""

        :variable listeners {}

        ## Write value and call all the closures 
        :public method set value {
            set :value $value 

            ## Notify
            foreach l ${:listeners} {
                 odfi::closures::applyLambda $l [list value $value]
            }
        }

        :public method get args {
            return ${:value}
        }

        ## Register a listener notified when value is written
        :public method onWrite closure {
            lappend :listeners $closure
        } 

    }

}
