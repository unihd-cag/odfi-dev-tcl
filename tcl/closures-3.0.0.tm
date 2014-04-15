package provide odfi::closures 3.0.0
package require odfi::common


## \brief Closures utilities namespace
namespace eval odfi::closures {


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

    #######################
    ## Special Functions for variables / overloaded in closure context 
    ####################
    
    proc incr var {
        #::puts "Inside special inc for $var"

        ## Resolve variable, to find out if we must link before calling top incr
        ::set levels [resolve $var 1]

        ## Upvar if the first found level is > 1
        if {[lindex $levels 0]>1} {
            uplevel upvar [expr [lindex $levels 0]-1] "$var" "$var"
        } 

        ## Then just call the top version 
        uplevel ::incr $var

    }
    namespace export incr

    proc set {var value} {

        #puts "Inside set $var [uplevel info frame] [uplevel namespace current]"
        if {[uplevel info frame]==0} {
            ::set $var $value
        }

        ## Resolve variable, to find out if we must link before calling top incr
        ::set levels [resolve $var 1]

        #::puts "Set variable $var, links to $levels"

        ## Upvar if the first found level is > 1
        if {[lindex $levels 0]>1} {
            uplevel upvar [expr [lindex $levels 0]-1] "$var" "$var"
        } 

        ## Then just call the top version 
        uplevel ::set $var $value

    }
    namespace export set


    ## Resolves the provided variable and returns its value 
    proc value var {

        ::set availableLevels [resolve $var 1]

        #puts "levels for : $var : $availableLevels"

        ## If no found level -> Just call ::set in execution level 
        #############
        if {[llength $availableLevels]==0} {
            return [uplevel ::set $var]
        } elseif {[llength $availableLevels]>1} {

            ## Available in multiple levels 
            ###########
            if {[lindex $availableLevels 0]==1} {

                ## It is available in calling context -> just call ::set
                return [uplevel ::set $var]
            }
            #if {[lindex $availableLevels]>0}
            uplevel upvar [expr [lindex $availableLevels 1]-1] "$var" "$var"
            return [uplevel [lindex $availableLevels 0] ::set $var]

        } else {

            ## Available in 1 level, then just call ::set in that level 
            if {[lindex $availableLevels 0]>1} {
                uplevel upvar [expr [lindex $availableLevels 0]-1] "$var" "$var"
            }
            return [uplevel [lindex $availableLevels 0] ::set $var]

        }


        #puts "Resolving variable $var"
        #return [uplevel ::set $var]
        error "Variable $var not found"

    }

    ## Returns the Levels at which the variable name can be found
    proc resolve {var {initResolveLevel 0}} {

        ::set var [lindex [string trimleft [lindex $var 0] $] 0]

        # Try to resolve by searching levels up 
        ################
        ::set availableLevels {}
        ::set searchResolveLevel [expr $initResolveLevel+1]
        while {[catch "uplevel $searchResolveLevel info level"]>=0} {

            #::puts "**** Search $var at uplevel $searchResolveLevel [uplevel $searchResolveLevel namespace current]"

            ## Test
            if {![catch [list uplevel $searchResolveLevel ::set $var] res]} {

                ## Found 
                ##########################
                lappend availableLevels [expr $searchResolveLevel-$initResolveLevel]

            } 

            ::incr searchResolveLevel

            ## Breaking because can'T search anywhere else
            if {[expr [info level]-$searchResolveLevel]<0} {
                break
            }

        }
            
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

    ## Runs a closure
    proc run {closure {execLevel 0}} {

        #puts "Closure level: [info level]"

        #::set execLevel [expr $execLevel+1]

        ::set targetLevel [uplevel $execLevel info level]
        ::set execNamespace [uplevel $execLevel namespace current]

        ## Find variables using regexp
        ::set newClosure [regsub -all {(?:\$([a-zA-Z0-9:_]+))|(?:\$\{([a-zA-Z0-9:_]+)\})} $closure "\[odfi::closures::value {\\1}\]"]

        #puts "New Closure: $newClosure"
        try {
            
            ## Import incr 
            if {$execLevel>0 && $targetLevel!=0 && $execNamespace!=[namespace current] && $execNamespace!="::"} {
                uplevel $execLevel namespace import -force ::odfi::closures::incr ::odfi::closures::set
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

        } finally {

            ##  Remove incr
            if {$execLevel>0 && $targetLevel!=0 && $execNamespace!=[namespace current] && $execNamespace!="::"} {
                uplevel $execLevel namespace forget ::odfi::closures::incr ::odfi::closures::set
            }
        }
        #catch {uplevel $execLevel [eval $newClosure]} res results

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

    ## List: {iteratorName {value value}} ...
    variable iterators {}

    proc stackIterator name {
        variable iterators

        ## If no value available...don't do anything
        if {[catch [list uplevel ::set $name]]} {

        } else {

            #::puts "- Stacking variable $name "
            ::set actualValue [uplevel ::set $name]

            ## Save value 
            lappend iterators [list $name $actualValue]

        }
        

    }

    proc destackIterator name {
       variable iterators

       ## Search for a valus in iterators
       set entryIndex [lsearch -index 0 -exact -start end $iterators $name]
       if {$entryIndex!=-1} {

            ::set entry [lindex $iterators $entryIndex]

            ## Remove from iterators list 
            ::set iterators [lreplace $iterators $entryIndex $entryIndex]

            #::puts "- DeStacking variable $name from $entry "

            ## Restore Value 
            uplevel set $name [lindex $entry 1]
       }
        

    }
    


    #####################################
    ## New Control Structures
    #####################################

    ## Executes the closure count times, with $i variable updated
    proc ::repeat {__count closure} {

       
        uplevel "
        odfi::closures::stackIterator i
        for {::set i 0} {$\i<$__count} {::incr i} {

            #uplevel \"::set i \$i\"
            odfi::closures::run {$closure} 1

        }
        odfi::closures::destackIterator i
        "
        return 


    }

}
