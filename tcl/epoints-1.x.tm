
## This package provides a Trait to easily register closures to be called on specific events on the object
## The events are simply named
package provide odfi::epoints 1.0.0
package require odfi::closures 3.0.0
package require odfi::richstream 3.0.0
package require nx 2.0.0

namespace eval odfi::epoints {

    nx::Class create EventPointsSupport {

        ## Format: { {NAME ARGS {CLOSURE CLOSURE}} {NAME {CLOSURE CLOSURE}}  }
        :property -accessor public {__eventPoints {}}

        :method init args {
            next
            set :__eventPoints {}

        }

        ## Register an event point: Create an entry in events points list, and create:
        ##  - an "onName" method to register a closure 
        ##  - a  "callName" method to call the point
        ##  - args: A list of argument names passed to the closure using applyLambda
        :public method registerEventPoint {name args} {

            ##
            set nameWithFirstUpper [string toupper $name 0 0]

            ## Prepare Event point 
            ##  - Check existence 
            set eventPoint [lsearch -exact -index 0 ${:__eventPoints} $name]
            if {$eventPoint!=-1} {
                #error "Cannot register Event Point $name, already exists"
            } else {

                if {[llength $args]>0} {
                    lappend :__eventPoints [list $name $args {}]
                } else {
                    lappend :__eventPoints [list $name {} {}]
                }
                

                ## Record : Returns index in points closure list
                :public object method on$nameWithFirstUpper cl {

                    ## Prepare Closure 
                    set clObject [odfi::closures::newITCLLambda [odfi::richstream::template::stringToString $cl]]

                    ## Get Caller 
                    set caller -1
                    catch {set caller [uplevel current object]}

                    ## get Event Point 
                    set pointName [string tolower [string range [current method] 2 end] 0 0]
                    set eventPointIndex [lsearch -exact -index 0 ${:__eventPoints} $pointName]

                    if {$eventPointIndex>=0} {

                        set eventPoint [lindex ${:__eventPoints} $eventPointIndex]

                        ## Append closure to closure lists 
                        set closures [lindex $eventPoint 2]
                        set newIndex [llength $closures]
                        lappend closures [list $caller $clObject]

                        ## Replace point
                        set eventPoint [lreplace $eventPoint end end $closures]
                        set :__eventPoints [lreplace ${:__eventPoints} $eventPointIndex $eventPointIndex $eventPoint]

                    } else {
                        error "Cannot register closure for point $pointName, it has not been registered before"
                    }

                    return $clObject
                }

                :public object method call$nameWithFirstUpper args {

                    #puts "Calling point"

                    ## get Event Point 
                    set pointName [string tolower [string range [current method] 4 end] 0 0]
                    set eventPoint [lsearch -inline -exact -index 0 ${:__eventPoints} $pointName]

                    if {[llength $eventPoint]>0} {

                        ## Check args 
                        set pointArgs [lindex $eventPoint 1]

                        ## Closure is of format: {CALLER Closure}
                        #puts "Closure list in event point: [lindex $eventPoint 2] "
                        foreach closure [lindex $eventPoint 2] {

                           # puts "Closure to run no [current method]: $closure"

                            #odfi::closures::applyLambda [lindex $closure 1] __caller [lindex $closure 0]
                            [lindex $closure 1] apply [list __caller [lindex $closure 0]]
                           # puts "(Done)"

                        }
                    } else {
                        error "Cannot call point $pointName, it has not been registered before"
                    }
                    #set closures [lindex [lsearch -inline] 1]

                }
            }
            


            
        }

        ## Register a closure to an event point 


    }


}
