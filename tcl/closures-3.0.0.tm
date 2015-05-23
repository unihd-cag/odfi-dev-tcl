#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    Copyright (C) 2008 - 2014 Computer Architecture Group @ Uni. Heidelberg <http://ra.ziti.uni-heidelberg.de>
#

package provide odfi::closures 3.0.0
package require odfi::common


## \brief Closures utilities namespace
namespace eval odfi::closures {

    ## Creates a normal proc, whose body is run through closures
    proc ::cproc {name args body} {
        uplevel 1 "
        proc $name {$args} {
            odfi::closures::run {
                $body
            }
        }
        
        "
        
    }
    

    ## Creates a function that executes its body in uplevel1
    ## It is useful to create a function that has to execute in the context of an object
    proc oproc {name arg body} {

        ::set pName [string trimleft $name ::]

        #::set res "proc ::$pName {$arg} {
         #   uplevel 1 {$body}
        #}"

        ::set res "proc ::$pName {$arg} {
            
            foreach __ip {$arg} { odfi::closures::uplink \$__ip 1 }
            #puts \"Could run $pName from: \[uplevel namespace current]\"
            #uplevel {
                odfi::closures::run {$body} 2

            #}
           # 1
           foreach __ip {$arg} { uplevel unset \$__ip }

        }"

        #::puts "Function to define: $res"
        uplevel 1 $res

    }
    namespace export oproc


    ## Performs #resolveVariables and ::subst on the provided closure text
    proc subst {closure {execLevel 1}} {
    
        odfi::closures::resolveVariables $closure [expr $execLevel+1]
        return [uplevel "::subst \"$closure\""]
    }

    proc getCurrentLine args {

        set callerScript [file normalize [uplevel info script]]
        #::puts "Current script: -> $callerScript"

        set resLine 0
        set currentFrame [uplevel info frame]
        set backIndex 2
        set stopSource false
        while {[expr $currentFrame-$backIndex] >= 1} {

            set fdict [uplevel info frame -$backIndex]
            set l [lindex $fdict 3]

            ## We allow one source path to be considered, if it is the first or last one 
            ## backIndex==2 is the first call 
            ## $currentFrame-$backIndex == 1 is the last call
            ## Otherwiese Consider only if it is a type eval, with line > 1
            if {[lindex $fdict 1]=="source"} { 

                ## If source matches caller script, accept and stop
                set file [lindex $fdict 5]
                #::puts "-> "
                if {$file==$callerScript} {
                    set resLine [expr $resLine + $l]
                    break
                }

            } elseif {[expr $currentFrame-$backIndex] == 1} {
                set resLine [expr $resLine + $l]
            } elseif {([lindex $fdict 1]=="eval" && $l > 1)} {
                set resLine [expr $resLine + $l -1]
            } elseif {[lindex $fdict 1]=="source"} { 

                ## If source matches caller script, accept and stop
                set file [lindex $fdict 5]
                ::puts "-> "
                if {$file==$callerScript} {
                    set resLine [expr $resLine + $l]
                    break
                }

            }

         

            
           # ::puts "Parent frame $backIndex line: $l -> [lindex $fdict 1]"
            incr backIndex
        }

        return $resLine
    }

    #######################
    ## Special Functions for variables / overloaded in closure context 
    ####################
    
    proc incr {var {val 1}} {
        #::puts "Inside special incr for $var"

        ## Resolve variable, to find out if we must link before calling top incr
        ::set levels [resolve $var 1]

        ## Upvar if the first found level is > 1
        if {[lindex $levels 0]>0} {
            uplevel upvar [expr [lindex $levels 0]] "$var" "$var"
        } 

        ## Then just call the top version 
        uplevel ::incr $var $val

    }
    namespace export incr

    proc set {var value} {

        if {[llength $value]>0} {
            ::set value [list $value]
        } else {
            #::set value "{}"
        }
        
#        if {$value==""} {
#            ::set value  [list ]
#        }

        #puts "Inside set $var to [join $value] [uplevel info frame] [uplevel namespace current]"
        
        ## If on top frame, don't resolve anything
        if {[uplevel info frame]==0} {
            ::set $var $value
            
        } else {
            
            ## Resolve variable, to find out if we must link before calling top incr [join $value]
            ::set levels [resolve $var 1]
    
            #::puts "Set variable $var, links to $levels, value is "
    
            ## Upvar if the first found level is > 1
            if {[lindex $levels 0]>0} {
                
                #::set i 0
                #for {::set i 1} {$i < [info frame]} {incr i} {
                #    ::set ft [info frame -$i]
                #    ::puts "(CL) up ft: $ft"
                #}
            
                uplevel [list upvar [expr [lindex $levels 0]] "$var" "$var"]
            } 
    
            ## Then just call the top version 
            if { [join $value]==""} {
                upvar $var $var
                ::set $var {}
                #uplevel ::set $var {}
            } else {
                uplevel ::set $var $value
            }
            
            
        }

        

    }
    namespace export set

    proc lappend {var args} {
        
        #::puts "Inside Closure LAPPEND for $var"
        
        ## Resolve variable, to find out if we must link before calling top incr
        ::set levels [resolve $var 1]
        
        #::puts " ->available levels for $var: $levels"
        
        ## Upvar if the first found level is > 1
        if {[lindex $levels 0]>1} {
            uplevel [list upvar [expr [lindex $levels 0]] "$var" "$var"]
        } 
        
        ## Then just call the top version 
        foreach arg $args {
            uplevel [list ::lappend $var $arg]        
        }
        
    }
    namespace export lappend
    

    ## Resolves the provided variable and returns its value 
    proc value {var {initResolveLevel 1}} {

        
        ## Resolve variable, to find out if we must link before calling top incr
        ::set levels [resolve $var 1]
        
        #return "0"
        #return 0
        
        #::puts "(CL) Resolving value of $var Available levels $levels"        
        if {[lindex $levels 0]>0} {
            
            if {[string index $var 0]==":"} {
                
                return [uplevel [expr [lindex $levels 0]+1] ::set $var]                   
            } else {
                uplevel upvar [lindex $levels 0] $var $var                  
                return [uplevel ::set $var]                
            }
        #return [uplevel [expr [lindex $levels 0]+1] ::set $var]                     
        
            uplevel upvar [lindex $levels 0] $var $var  
            if {![catch [list uplevel ::set $var] res]} {
                return $res
            } else {
                return [uplevel [expr [lindex $levels 0]+1] ::set $var]                               
            }
#            return [uplevel ::set $var]      
                      
            #::set v  [uplevel [expr [lindex $levels 0]+1] ::set $var]         
            #return $v    
                       
              
        } else {
            return [uplevel ::set $var]             
        }     
        


    }

    ## Returns the Levels at which the variable name can be found
    ## arg: -allLevels forces retrieval of all levels
    proc resolve {var {initResolveLevel 0} args} {

        #::set var [lindex [string trimleft [lindex $var 0] $] 0]
        
        ## Args
        ::set allLevels [expr [lsearch -exact $args  "-allLevels"]==-1?false:true]
        
        # Try to resolve by searching levels up 
        ################
        ::set availableLevels {}         
       
        ::set baseLevel [expr $initResolveLevel+1]
        ::set ui $baseLevel
        ::set limit [uplevel $baseLevel info frame]
         
        #::puts "(RES) Going up frame levels to try find the variable $var (from $ui to $limit)"         
                 
         
        ## Fast level 0 search
        if {!$allLevels && ![catch [list uplevel $baseLevel ::set $var] res]} {
            return [list 0]
        }
         
         
        ::set targetEndLevel [uplevel $baseLevel info frame]
        for {} {$ui < $targetEndLevel} {::incr ui} {
            
            ::set ft [uplevel $baseLevel info frame -$ui]
            
            #::puts "(RES FT)"
            ::set levelindex [lsearch -exact $ft level] 
            
            if {$levelindex!=-1} {
                ::set level [lindex $ft [expr $levelindex+1]]
                
                ## Save First found level
                if {[catch {::set l0Frame}]} {
                    ::set l0Frame $ft                 
                }
                #if {$level==0} {
                #                
                #}
                
                ::set found [expr [catch [list uplevel [expr $level+$baseLevel] ::set $var]]==1?false : true]
                
           # ::puts "  (RES) Valid level $level, foudn $found on proc [lindex $ft end-2],l0 proc [lindex $l0Frame end-2]  "                    
               # ::puts "  (RES) Valid level $level on proc [lindex $ft end-2], found $found "                                
                
                #::puts "  (RES) Valid level $level, found $found "                                
                if {$found} {
                #::puts "  (RES) Valid level $level, found $found [lindex $ft end-2]!=[lindex $l0Frame end-2]"                      
                
                }
                
                if {$found} {
                    ::lappend availableLevels $level  
                    
                    if {!$allLevels} {
                        break
                    }
           
                }        
                        
                
                
                ## FIXME!
                ## Ignore if the target proc is the same as L0 proc and level > 0
                ## If level is 0, variable is already local
#                if {$found && $level==0} {
#                    ::lappend availableLevels $level
#                    #break               
#                } elseif {$found && [lindex $ft end-2]!=[lindex $l0Frame end-2]} {
#                    ::lappend availableLevels $level
#                }
                
            }
            ::unset ft            
           # ::puts "  (RES) Testing frame: $ft"
        }
        
        catch {
            ::unset l0Frame
        }
        
        #::puts "-> Found $availableLevels"
        
        return $availableLevels

    }

    ## Uplink resolves a variable, and copies its result from the calling level to the target level 
    ## It generates a warning if the variable is already to be found in the target level
    ## All levels are relative to this method
    proc uplink {name targetLevel args} {

        ## Target level is given from caller perspective, so add 1 to match this level 
        set targetLevel [expr $targetLevel+1]
        ::set levels [resolve $name 1]

        ## There must be a level 1 result as first element
        if {[lindex $levels 0]!=1} {
            odfi::log::error "Cannot uplink variable $name to $targetLevel, because it does not exists in caller ([dict get [info frame -1] proc])"
        } else {

            ## Emmit a warning if the target level is present in the levels list 
            if {[lsearch -exact $levels $targetLevel]!=-1} {
                odfi::log::warning "Uplinking $name from [dict get [info frame -1] proc] will overwrite an existing variable in [uplevel $targetLevel namespace current]"
            }

            ## Copy up
            uplevel $targetLevel ::set $name [uplevel ::set $name]

        }

    }

    proc retrieveClosure __closure__ {

        ## Get Closure Value 
        ##  - Either the "Closure" variable value 
        ##  - A variable in uplevel if the first character is "%", which is to be retrieved and killed
        if {[string match "%*" $__closure__]} {
            #odfi::log::info "Closure is a variable to be retrieved: $closure"

            ::set cname [string range $__closure__ 1 end]
            ::set availableAt  [resolve $cname 2 -allLevels]
            
            #puts "(RCL) Available levels: $availableAt [llength $availableAt]"
            
            if {[llength $availableAt]==0} {
                error "Cannot retrieve closure by variable name $cname, not available anywhere"
            } else {
                
                #::puts "Closure variable name is available there: $availableAt"

                ## Search for the first element > 2 
                ::set targetLevel false 
                foreach i  $availableAt {
                    #if {$i>2} {

                        ## Search
                        ::set cl [uplevel [expr $i+2] [list ::set $cname]]
                        
                       #puts " @$i $cl"                        

                        ## Check it is ok, else continue
                        if {![string match "%*" $cl]} {
                            uplevel  [expr $i+2]  [list ::unset $cname]
                            return $cl
                        } else {
                            uplevel  [expr $i+2]  [list ::unset $cname]
                        }
                    #}
                }
                #if {$targetLevel==false} {
                    error "Closure Variable named $cname cannot be found outside closures library scope"
                #}

                #::puts "Found target level $targetLevel"
               

                #::set cl [uplevel [expr $targetLevel-1] [list ::set $cname]]
                #uplevel  [expr $targetLevel-1]  [list ::unset $cname]
                #::puts "Closure: $cl"

                return $cl
            }
            #::puts "$cname available at: [resolve $cname 1]"

            #exit 0
        } else {
            return $__closure__
        }

    }

    ## Runs a closure
    proc run {closure args} {

        ::set closure [retrieveClosure $closure]

        ## Parameters 
        #####################
        ::set execLevel 0
        if {[lsearch -exact $args -level]!=-1} {
            ::set execLevel [lindex $args [expr [lsearch -exact $args -level]+1]]
            #puts "Exec level from here : $execLevel"
        }
        ::set execLevel [expr $execLevel+1]

        #puts "Closure level: [info level]"

        #::set execLevel [expr $execLevel+1]

        ::set targetLevel [uplevel $execLevel info level]
        ::set execNamespace [uplevel $execLevel namespace current]

        ## Find variables using regexp
        ::set newClosure [regsub -all {([^\\])\$(?:([a-zA-Z0-9:_]+)|(?:\{([a-zA-Z0-9:_]+)\}))} $closure "\\1\[odfi::closures::value {\\2\\3} \]"]
        #::set newClosure [regsub -all {([^\\])\$\{?([a-zA-Z0-9:_]+)\}?} $closure "\\1\[odfi::closures::value {\\2} \]"]

        #unset closure

        #puts "New Closure: $newClosure"
        try {
            


            ## Import incr 
            ################
            #set settersImport {incr set lappend}
            if {$execLevel>0 && $targetLevel!=0 && $execNamespace!=[namespace current] && $execNamespace!="::"} {
                uplevel $execLevel namespace import -force ::odfi::closures::incr ::odfi::closures::set ::odfi::closures::lappend
            }
            
            #puts "Running closure $newClosure in : $execNamespace // [uplevel $execLevel eval {namespace current}]"
            
            # uplevel $execLevel {
            #    puts "(CL) Running in NS  [uplevel namespace current]"
            # }
            uplevel $execLevel eval "{$newClosure}"
            #uplevel $execLevel $newClosure

        } on break {res resOptions} {

            #::puts "(CL) Caught break"
            uplevel $execLevel return -code break 0

        } on error {res resOptions} {

            ::set line [dict get $resOptions -errorline]
            ::set stack [dict get $resOptions -errorstack]
            ::set errorInfo [dict get $resOptions -errorinfo]
            ::set errorInfo [regsub -all {\[odfi::closures::value {([^{}]+)}\]} $errorInfo "\$\\1"]
            #puts "(CL) Found error: $res at line $line"
            #puts "(CL) last stack: $stack"

            dict set resOptions replace -errorinfo [regsub -all {\[odfi::closures::value {([^{}]+)}\]} $errorInfo "\$\\1"]

            error $errorInfo

        } on return {res resOptions} {

           # puts "Caught return $res" 
            #uplevel $execLevel return $res
            uplevel $execLevel [list ::return $res]
            #::return $res

        } finally {

            ##  Remove incr
            #::puts "--> Removing exports fomr [uplevel 2 namespace current]"
            
            ## Parent
            #set ft1 [info frame -2]
            #set ft2 [info frame -2]
            
            ## Go uplevel until out of this namespace
            #::set i 1
            #set currentNS [uplevel namespace current]
            #while {[string match "*odfi::closures::*" $currentNS]} {
            #    incr i
            #    set currentNS [uplevel $i namespace current]
            #}
            
            ## i is the level into we should look for an already running command
            ::set ft [info frame -$execLevel]
            #::puts "Caller level ns [uplevel $execLevel namespace current]"
            #::puts "---> Calleer frame info $ft -- [lindex [lindex $ft 5] 0]" 
            if {[lindex $ft 1]=="eval" && [string match "*odfi::closures*" [lindex [lindex $ft 5] 0]]} {
              ## Don't remove!
              #puts "Don't remove!"
              
            } else {
                if {$execLevel>0 && $targetLevel!=0 && $execNamespace!=[namespace current] && $execNamespace!="::"} {
                    uplevel $execLevel namespace forget ::odfi::closures::incr ::odfi::closures::set ::odfi::closures::lappend
                }
            }
            unset ft            
            
            #
            
            
        }
        #catch {uplevel $execLevel [eval $newClosure]} res results
        
        return
    }


    ## \brief Calls doClosure, and join result using a character. " " per default
    proc doClosureToString {closure {execLevel 0} {resolveLevel 0}} {

        ::set result [odfi::closures::doClosure $closure [expr $execLevel+1] [expr $resolveLevel+1]]

        ## Take First result of list, if only one
        if {[llength $result]==0} {
            ::set result [lindex $result 0]
        }

        #return [join $result " "]

        return [regsub -all "(\}|\{)" $result ""]

    }

    ## \brief Calls doClosure, and join result using a character. " " per default
    proc doFile {closureFile {execLevel 0} {resolveLevel 0}} {

        if {[file exists $closureFile]} {

            ## Read
            ::set closure [odfi::common::readFileContent $closureFile]
            return [odfi::closures::doClosure $closure [expr $execLevel+1] [expr $resolveLevel+1]]
        } else {
            return ""
        }

    }

    ######################################
    ## Iterator Variables 
    #######################################

    ## List: {iteratorName value} {iteratorName value} ...
    variable protectedStack {}

    proc protect name {
        variable protectedStack

        

        ## If no value available...don't do anything
        #if {[catch [list uplevel ::set $name] res]}  
        if {[catch [list uplevel odfi::closures::value $name 2] res]} {    

            #puts "Protecting: $name with no value"

        } else {

           
            #::set actualValue [uplevel ::set $name]
            ::set actualValue $res
            
           # puts "Protecting: $name with $actualValue"

            ## Save value 
            ::set protectedStack [concat [list [list $name $actualValue]] $protectedStack]
            #::lappend protectedStack [list $name $actualValue]
            
            #::puts "- Stacking variable $name with $actualValue ($protectedStack)"
                        

           # puts "Stack is now: $protectedStack"
        }
        

    }

    proc restore name {
       variable protectedStack

           

       #puts "Restoring: $name "

       ## Search for a value in iterators
       ::set entryIndex [lsearch -index 0 -exact $protectedStack $name]
       if {$entryIndex!=-1} {

            #::puts "- DeStacking variable $name at entryIndex $entryIndex"
           
            #::set entryIndex [expr [llength $protectedStack]-1-$entryIndex]

            ::set entry [lindex $protectedStack $entryIndex]
           
            #::puts "----- Entry: $entry"

            ## Remove from iterators list 
            ::set protectedStack [::lreplace $protectedStack $entryIndex $entryIndex]

            #::puts "- DeStacking variable $name from val $entry -> $protectedStack "

            ## Restore Value 
            uplevel [list ::set $name [lindex $entry 1]]
       }
        

    }
    

    #####################################
    ## Lamda Support
    #####################################
    proc applyLambda {lambda args} {

        #puts "Run $lambda with args $args"

        ## Find Input Arguments
        ###############
        ::set lambda [string trim [regsub {"]} $lambda {" ]}]]
        #set splittedLambda [split [string trim $lambda]]
        #puts "Lambda splited: $splittedLambda \n"
        ::set lambdaArgs {}
        try {
            if {[lindex $lambda 1]=="=>" || [lindex $lambda 1]=="->"} {

                ::set _def [lrange $lambda 0 1]
                #puts "Found def: $_def"

                ## Get Arguments 
                ::set lambdaArgs [lindex $lambda 0]

                ## Extract implementation
                #puts "Extract lambda from: [string length $_def] to end"
                ::set lambda "[string range [string trim $lambda] [string length $_def] end]"

                #puts "Now lambda is $lambda"
            }
        } on error {res resOptions} {
            ::puts "An error occured while detecting lambda format ($res): $lambda"
            error $res
        }

        ##
        #puts "Lamda Arguments ([llength $lambdaArgs]): $lambdaArgs"

        ## Check Provided Args match the required lambda args 
        ###########
        if {[llength $lambdaArgs]>0 && [llength $args]!=[llength $lambdaArgs]} {
            error "Cannot call lambda function with [llength $lambdaArgs] input arguments ($lambdaArgs), [llength $args] arguments provided to applyLambda call. Please respect applyLamba lambda arg0? ... argn? format"
        }

        ## Protect Variable names of input lambda 
        ###############
        foreach larg $lambdaArgs {
            #puts "Protecting: $larg"
            uplevel odfi::closures::protect $larg
        }

        ## Set input args values (fancy varname here to ensure no conflict will happpen) 
        ##  - Go through args and match to required input arguments
        ##  - If an argument is provided as a {varname value} pair, and the lambda does not enforce the input parameters, set to the applyLambda call set varname
        #########
        ::set generatedLambdaArgs {}
        for {::set _i 0} {$_i < [llength $args ]} {::incr _i} {

            ## Get Arg name and value 
            ::set arg      [lindex $args $_i]
            #puts "INPUT ARGUMENT $arg ([llength $arg]) // [lindex $arg 0] // $args"
            if {[llength $arg]==1} {
                ::set argValue [lindex $arg 0]
                ::set argName  "arg$_i"
            } else {
                ::set argValue [lindex $arg 1]
                ::set argName  [lindex $arg 0]
            }
            #::set argValue [expr [llength $arg]==1 ? [lindex $arg 0] : [lindex $arg 1]]
            #::set argName  [expr [llength $arg]==1 ?  ""             : [lindex $arg 0]]

            ## Match lambda input 
            if {[llength $lambdaArgs]>0} {
                
                #::puts "Varset: $argValue -> [llength $argValue]"
                if {[llength $argValue]>1} {
                    uplevel ::set [lindex $lambdaArgs $_i] [list $argValue]
                } elseif {[llength $argValue] ==0 && $argValue==""} {
                    #::puts "Setting [lindex $lambdaArgs $_i] to $argValue"
                    uplevel [list ::set [lindex $lambdaArgs $_i] {}]
                } else {
                    #::puts "Setting [lindex $lambdaArgs $_i] to $argValue"
                    uplevel ::set [lindex $lambdaArgs $_i] $argValue
                }
                
            } else {

                ## Check there is a var name, otherwise set default name argx
               # set targetName [expr $argName=="" ? "arg$_i" : $argName]

                ## Set Value 
                #puts "SETTING AUTOMATIC INPUT ARGUMENT: $argName $argValue"
                uplevel odfi::closures::protect $argName
                ::lappend generatedLambdaArgs $argName
                
                if {[llength $argValue]>1} {
                    uplevel ::set $argName [list $argValue]
                } elseif {[llength $argValue] ==0 && $argValue==""} {
                    #::puts "Setting $argName to $argValue 8force empty"
                    #upvar $argName $var
                    #::set $var {}
                    uplevel [list ::set $argName {}]
                } else {
                    #::puts "Setting $argName to $argValue"
                    uplevel ::set $argName $argValue
                }
                
                #uplevel ::set  $argName $argValue
            }

        }
        ::set lambdaArgs [::concat $lambdaArgs $generatedLambdaArgs]

        ## Run 
        #################
        try {
            run $lambda -level 1
        } on return {res resOptions} {
                    
            puts "Caught return in applyLambda: $res"
         
        } on break {res resOptions} {
    
            #::puts "(AL) Caught break"
            #uplevel $execLevel return -code break 0
            return -code break 0
    
        } finally {
            #### Make sure variables are restored even in error case 
            foreach larg $lambdaArgs {
                uplevel odfi::closures::restore $larg
            }
        }
    }


    #####################################
    ## New Control Structures
    #####################################

    ## Executes the closure count times, with $i variable updated
    proc ::repeat {__count closure args} {
        
        ::set __count [expr $__count]
#    uplevel [list odfi::closures::::applyLambda { \
#        for {::set i 0} {$i<$count} {::incr i} {  \
#            eval $closure  \
#        }     \
#    } [list i 0] [list count __count] [list closure $closure] ]     
#
#       
#        return
        
        ::odfi::closures::protect i
        for {::set i 0} {$i<$__count} {::incr i} {
            try {        
                uplevel [list odfi::closures::::applyLambda [concat $closure $args] [list i $i]]
            } on break {res resOptions} {
                #puts "Caught break"
                break            
            }
        }
        ::odfi::closures::restore i        


    }
    
    
    proc ::repeatf {__count closure args} {
        
    ::set __count [expr $__count]
            
        uplevel ::odfi::closures::protect i
        try {
            for {::set i 0} {$i<$__count} {::incr i} {
                try {        
                    uplevel set i $i
                    uplevel $closure
                } on break {res resOptions} {
                    #puts "Caught break"
                    break            
                }
            }
        } finally {
            uplevel ::odfi::closures::restore i            
        }
               
    
    }
     

   

}
