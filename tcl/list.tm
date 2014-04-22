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

package provide odfi::list 1.0.0

package require odfi::common

namespace eval odfi::list {

    ## transforms given #lst list using provided #script, with $elt beeing the current element
    ## The #script output will be used to create a new list
    ## @return The new list transformed by #scriptClosure
    proc transform {lst scriptClosure} {

        set newlst {}
        foreach elt $lst {

            set it $elt
            #puts "-> transforming: $elt ([llength $lst])"

            set res [odfi::closures::doClosure $scriptClosure]

            #puts "TRANSFORM: Result is: $res"

            lappend newlst $res
        }

       # puts "New List: $newlst"
        return $newlst

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
            uplevel 1 "set key $key"
            uplevel 1 "set value $value"
            uplevel 1 $script
        }

    }

    ## \brief Search for the element key in the array list, and return the index+1 element
    # @return an error if element was not found
    proc arrayGet {arrayList key} {

        ## Find key
        set keyIndex [lsearch -exact $arrayList $key]
        if {$keyIndex==-1} {
            error "Could not find key $key in array list"
        }

        ## Return result
        return [lindex $arrayList [expr $keyIndex+1]]

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
                set local               false
                set callerExec          false
                set callerExecUp        false
                set searchResolveLevel  $resolveLevel

                ### 1: Closure level -> Do nothing
                set exp "set $var .+\$"
                set localSearchResults [regexp -all -inline -line $exp $closureString]
                if {[llength $localSearchResults]>0} {

                    ## This is only true, if in none of the set expressions, the variable is used right
                    ## Ex: set var "${var}_var" should lead to an upvar
                    set validLocal true
                    foreach localResult $localSearchResults {

                        #puts "Checking local variable $var validity against set expression: $localResult"

                        if {[regexp "set $var .*\\\$$var.*" $localResult]>0} {

                            #puts "Variable should be upvared"
                            set validLocal false
                            break
                        }

                    }


                    #puts "-- Variable $var is defined in local"
                    if {$validLocal==true} {
                        set local true
                        continue
                    } else {
                        set local false
                    }


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

                    while {[catch "uplevel $searchResolveLevel info level"]==0} {

                        #puts "**** Search $var at uplevel $searchResolveLevel [uplevel $searchResolveLevel namespace current]"

                        ## Test
                        if {[catch [list uplevel $searchResolveLevel set $var] res]} {
                            ## not found
                        } else {
                            ## Found
                            #puts "********* Found $var at $searchResolveLevel"
                            set callerExecUp true
                            set requiredUpvars [concat upvar [expr $searchResolveLevel-$execLevel] $var $var ";" $requiredUpvars]
                            break
                        }

                        incr searchResolveLevel

                        ## Breaking because can'T search anywhere else
                        if {[expr [info level]-$searchResolveLevel]<0} {
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



    ## \brief Evaluates a closure and make magic for variables to be resolved
    proc doClosure {closure {execLevel 0} {resolveLevel 0}} {

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
                set local               false
                set callerExec          false
                set callerExecUp        false
                set searchResolveLevel  $resolveLevel

                ### 1: Closure level -> Do nothing
                set exp "set $var .+\$"
                set localSearchResults [regexp -all -inline -line $exp $closureString]
                if {[llength $localSearchResults]>0} {

                    ## This is only true, if in none of the set expressions, the variable is used right
                    ## Ex: set var "${var}_var" should lead to an upvar
                    set validLocal true
                    foreach localResult $localSearchResults {

                        #puts "Checking local variable $var validity against set expression: $localResult"

                        if {[regexp "set $var .*\\\$$var.*" $localResult]>0} {

                            #puts "Variable should be upvared"
                            set validLocal false
                            break
                        }

                    }


                    #puts "-- Variable $var is defined in local"
                    if {$validLocal==true} {
                        set local true
                        continue
                    } else {
                        set local false
                    }


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

                    while {[catch "uplevel $searchResolveLevel info level"]==0} {

                        #puts "**** Search $var at uplevel $searchResolveLevel [uplevel $searchResolveLevel namespace current]"

                        ## Test
                        if {[catch [list uplevel $searchResolveLevel set $var] res]} {
                            ## not found
                        } else {
                            ## Found
                            #puts "********* Found $var at $searchResolveLevel"
                            set callerExecUp true
                            set requiredUpvars [concat upvar [expr $searchResolveLevel-$execLevel] $var $var ";" $requiredUpvars]
                            break
                        }

                        incr searchResolveLevel

                        ## Breaking because can'T search anywhere else
                        if {[expr [info level]-$searchResolveLevel]<0} {
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
