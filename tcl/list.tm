package provide odfi::list 1.0.0

package require odfi::common

namespace eval odfi::list {
    
    ## transforms given #lst list using provided #script, with $elt beeing the current element
    ## The #script output will be used to create a new list
    ## @return The new list transformed by #scriptClosure
    proc transform {lst scriptClosure} {
        
        set newlst {}
        foreach elt $lst {
            
            #puts "-> transforming: $elt ([llength $lst])"
            
            lappend newlst [eval $scriptClosure]
        }
        
       # puts "New List: $newlst"
        return [list $newlst]
        
    }
    
    ## \brief Evaluates script for each element of lst, providing $it variable as pointer to element, and $i as index
    # Script is called in one uplevel
    proc each {lst script} {
        
    
        
        for {set ::odfi::list::i 0} {$::odfi::list::i < [llength $lst]} {incr ::odfi::list::i} {
            eval "uplevel 1 {" "set it [lindex $lst $::odfi::list::i];" "$script}"
                      
        }
        
    }

    
    ## \brief Evaluates script for each key/pair arrayVar, providing $key variable as pointer to key, and $value as value
    # Script is called in one uplevel
    proc arrayEach {arrayList script} {
        
        foreach {key value} $arrayList {
            eval "uplevel 1 {set key $key;set value $value;"  "$script}"
        }
        
    }

    ## \brief Runs the specified closure on each list element, and returns a grouped list based on closure output
    # \example array set [odfi::list:groupBy $myList {$it getName}]
    # @return A { grp {elts} grp {elts}} like list, to be used by array set 
    proc groupBy {lst closure} {

        set resList {}
        foreach it $lst {

            #puts "Group By on $it"

            ## Run Closure 
            ####
            set val [odfi::closures::evalClosure2 $closure]
            if {$val == ""} {
                continue
            }

            ## Group 
            ###############

            ## Search for entry with val 
            set existingEntry [lsearch -exact $resList $val]

            ## If there, append $it to $existingEntry+1 index 
            ## If not, just append both to the list 
            if {$existingEntry!=-1} {

                set groupContent [concat [lindex $resList [expr $existingEntry+1]] $it]
                set resList [lreplace $resList [expr $existingEntry+1] [expr $existingEntry+1] $groupContent]

            } else {
                lappend resList $val $it
            }

            #puts "Group By closure result: $val"

        }

        return $resList

    }
 
    
    ################################################################################
    ## Classes
    ################################################################################
    odfi::common::resetNamespaceClasses [namespace current]
    

    
    
}

namespace eval odfi::closures {
    
    ## \brief Evaluates a closure and make magic for variables to be resolved
    proc evalClosure {closure {execLevel 0}} {
     
        #puts "Evaluating closure $closure"
        
        set closureString "$closure"
        
        ## Level:
        ## - This is a utility proc, so level 1 is the caller.
        ## - So call level provided by caller must then be +1 to hide this procedure level
        ###################
        set execLevel [expr $execLevel+1]
        
        ## Resolution:
        ##  - Resolve variables in caller asked level +1 
        ##  - Execute in caller asked level
        ###################
        set resolveLevel [expr $execLevel+1]
        
        ## list of all upvaring to prepend to closure
        set requiredUpvars {}
        
       
        
        #puts "Search into [llength $closure]"
        
        foreach scriptElement [split $closureString { \n}] {
         
            ## Search for all variables
            ############
            #puts "Exploring $scriptElement"
            set vars [regexp -all -inline {\$[a-zA-Z0-9:{}_]+\s*} $scriptElement]
            foreach var $vars {
                
                set var [string trim [string range $var 1 end]]
                
               # puts "Found variable : $var"
                
                ## Ignore variables that are an explicit namespaced reference
                ##############
                
                ### Ignore certain patterns
                if {[string match "::*" $var] || $var=="this"} {
                    continue
                }
                
                #puts "Not ignored variable : $var"
                
                ### If variable is global, also ignore
                if {[catch [list set $var] res]==0} {
                    continue
                }
                
                
                ## Search for variable in: 
                #############
                set local       false
                set callerExec      false
                set callerExecUp    false
                
                ### 1: Closure level -> Do nothing
                set exp "set $var .+"
                if {[regexp -all $exp $closureString ->]>0} {
                    
                    #puts "-- Variable $var is defined in local"
                    
                    set local true
                    
                } else {
                 
                    #puts "Explored /$exp/ in closure string /$closureString/"
                    
                }
                
                ### 2: Caller Level -> Do nothing
                if {[catch [list uplevel $execLevel set $var] res]} {
                    
                    #puts "-- Variable $var not found in execlevel upvar ($execLevel)"
                    
                } else {
                    
                    #puts "-- Variable was found in execlevel upvar ($execLevel), with value $test"
                    
                    set callerExec true
                    #set requiredUpvars [concat upvar [expr $execLevel] $var $var $requiredUpvars]
                    #lappend requiredUpvars "upvar $execLevel $var $var"
                }
                
                ### 3: Caller +1 level -> upvar
                if {$callerExec==true || [catch [list uplevel $resolveLevel set $var] res]} {
                                    
                    #puts "-- Variable $var not found in resolveLevel upvar ($resolveLevel)"
                    
                } else {
                    
                    #puts "-- Variable was found in resolveLevel upvar ($resolveLevel)"
                    
                    ## Add to upvars only if, but level is dependend on execution level
                    set callerExecUp true
                    set requiredUpvars [concat upvar [expr $resolveLevel-$execLevel] $var $var ";" $requiredUpvars]
                    
                    
                }
                
                ## Verify Compatibilities
                ##########################
                
                ## If More than one level has true defined, there is a conflict
                if {$local==true && [llength [lsearch -all -exact [list $callerExec $callerExecUp] true]]>1} {
                    
                    error "Variable $var has been found defined in some up level, and local closure, there will probably be some conflicts:
                            - Found in closure $local
                            - Found in Closure Caller execution level $callerExec
                            - Found in Closure Caller execution level +1 $callerExecUp
                    "   
                    
                }
                        
            }
        }
        
        
        ## Evaluate closure
        #########################
        return [uplevel $execLevel [concat $requiredUpvars $closure ]]
        

        
    }
    
    ## \brief Evaluates a closure and make magic for variables to be resolved
    proc evalClosure2 {closure {execLevel 0} {resolveLevel 0}} {
     
        #puts "Evaluating closure $closure"
        
        
        
        set closureString "$closure"
        
        ## Level:
        ## - This is a utility proc, so level 1 is the caller.
        ## - So call level provided by caller must then be +1 to hide this procedure level
        ###################
        set execLevel [expr $execLevel+1]
        
        ## Resolution:
        ##  - Resolve variables in caller asked level +1 
        ##  - Execute in caller asked level
        ###################
        set resolveLevel [expr $execLevel+1]
        
        ## list of all upvaring to prepend to closure
        set requiredUpvars {}

       
        
        #puts "Search into [llength $closure]"
        
        #puts "Exploring closure **************************"

        #foreach scriptElement [split $closureString { }] {
         
            ## Search for all variables
            ############
            #puts "**** Exploring $scriptElement"
            set vars [regexp -all -inline {\$[a-zA-Z0-9:{}_]+\s*} $closureString]
            foreach var $vars {
                
                set var [string trim [string range $var 1 end]]
                set var [regsub -all {\{|\}} $var ""]

                #puts "Found variable : $var"
                
                ## Ignore variables that are an explicit namespaced reference
                ##############
                
                ### Ignore certain patterns
                set ignores {

                    "::*" {continue}
                    "this" {continue}
                    "it" {continue}

                }
                switch -- $var $ignores
                #if {[string match "::*" $var] || $var=="this"} {
                #    continue
                #}
                
                #puts "Not ignored variable : $var"
             
                ### If variable is global, also ignore
                #if {[catch [list set ::$var] res]==0} {
                #    continue
                #}
                
                
                ## Search for variable in: 
                #############
                set local       false
                set callerExec      false
                set callerExecUp    false
                
                ### 1: Closure level -> Do nothing
                set exp "set $var .+"
                if {[regexp -all $exp $closureString ->]>0} {
                    
                    #puts "-- Variable $var is defined in local"
                    
                    set local true
                    continue

                    
                } else {
                 
                    #puts "Explored /$exp/ in closure string /$closureString/"
                    
                }
                
                ##### 2: Caller Level -> Do nothing
                if {[catch [list uplevel $execLevel set $var] res]} {
                    
                    #puts "-- Variable $var not found in execlevel upvar ($execLevel)"
                    
                } else {
                    
                    #puts "-- Variable $var was found in execlevel upvar ($execLevel)"
                    
                    set callerExec true
                    #set requiredUpvars [concat upvar [expr $execLevel] $var $var $requiredUpvars]
                    #lappend requiredUpvars "upvar $execLevel $var $var"
                }
                
                ### 3: Caller +1 level -> upvar
                 if {$callerExec==false} {

                    #puts "**** Start Search at uplevel [uplevel $resolveLevel info level]"

                    while {[catch "uplevel $resolveLevel info level"]==0} {

                        #puts "**** Search $var at uplevel $resolveLevel [uplevel $resolveLevel namespace current]"

                        ## Test 
                        if {[catch [list uplevel $resolveLevel set $var] res]} {
                            ## not found
                        } else {
                            ## Found
                            #puts "********* Found $var at $resolveLevel"
                            set callerExecUp true
                            set requiredUpvars [concat upvar [expr $resolveLevel-$execLevel] $var $var ";" $requiredUpvars]
                            break
                        }

                        incr resolveLevel

                        ## Breaking because can'T search anywhere else
                        if {[expr [info level]-$resolveLevel]<0} {
                            break
                        }

                    }

                 }
                 ## EOF uplevels search
                
                
                ## Verify Compatibilities
                ##########################
                
                ## If More than one level has true defined, there is a conflict
                if {$local==true && [llength [lsearch -all -exact [list $callerExec $callerExecUp] true]]>1} {
                    
                    error "Variable $var has been found defined in some up level, and local closure, there will probably be some conflicts:
                            - Found in closure $local
                            - Found in Closure Caller execution level $callerExec
                            - Found in Closure Caller execution level +1 $callerExecUp
                    "   
                    
                } elseif {[lsearch -exact [list $local $callerExec $callerExecUp] true]==-1} {
                    #odfi::common::logWarn "Variable $var seems not to be resolvable:
                    #        - Found in closure $local
                    #        - Found in Closure Caller execution level $callerExec
                    #        - Found in Closure Caller execution level +1 $callerExecUp
                    #"  
                }
                        
            }
        #}
        
        
        ## Evaluate closure
        #########################
        return [uplevel $execLevel [concat $requiredUpvars $closure ]]
        

        
    }
        
        
        
    
}