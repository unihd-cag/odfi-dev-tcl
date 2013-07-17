package provide odfi::list 2.0.0
package require odfi::closures 2.0.0



namespace eval odfi::list {


    ## \brief provided operations is a list with pairs:
    #   operation closure
    # Each operation is executed on target list, based on provided closure
    # Supported Operations:
    #  - filter
    #  - transform
    #
    # @return the resulting targetList
    proc do {targetList operations} {

        foreach {op closure} $operations {

            switch -exact -- $op {
                first-match {
                    set targetList [odfi::list::firstMatch $targetList $closure -level 1]
                }
                filter {
                    set targetList [odfi::list::filter $targetList $closure -level 1]
                }
                transform {
                    #puts "Start transform on list with [llength $targetList] elements"
                    set targetList [odfi::list::transform $targetList $closure -level 1]
                }
                transform-concat {
                    #puts "Start transform on list with [llength $targetList] elements"
                    set targetList [odfi::list::transform $targetList $closure] -level 1 -concat
                }
                each {
                    odfi::list::transform $targetList $closure -level 1
                }
                default {error "Unsupported list do operation $op"}
            }

        }

        return $targetList

    }

    ## transforms given #lst list using provided #script, with $it beeing the current element
    # The #script output will be used to create a new list
    # @return The new list transformed by #scriptClosure
    proc transform {lst scriptClosure args} {

        ## Option: -concat
        ####################
        set concat false
        if {[lsearch -exact $args -concat]} {
            set concat true
        }

        ## -level option
        ###########
        set execlevel 1
        if {[lsearch -exact $args -level]} {
            set execlevel [lindex $args [expr [lsearch -exact $args -level]+1]]
        }

        ## Exec level +1 to cover the current execution level
        set execlevel [expr $execlevel+1]

        ####

        set newlst {}
        foreach it $lst {

            ## Fix empty it case
            if {$it==""} {
                set it "\"\""
            }

            uplevel $execlevel set it "{$it}"
            set res [odfi::closures::doClosure $scriptClosure $execlevel]

            #puts "TRANSFORM: Result is: $res"
            if {$concat==true} {
                set newlst [concat $newlst $res]
            } else {
                lappend newlst $res
            }

        }
        return $newlst


    }

    ## Filters given #lst list using provided #script, with $it beeing the current element
    #  If the closure returns true, the element is kept as part of the new list, if not, then it is removed
    # @return The new list transformed by #scriptClosure
    proc filter {lst scriptClosure args} {

        ## -level option
        ###########
        set execlevel 1
        if {[lsearch -exact $args -level]>-1} {
            set execlevel [lindex $args [expr [lsearch -exact $args -level]+1]]
        }

        ## Exec level +1 to cover the current execution level
        set execlevel [expr $execlevel+1]

        ####

        set newlst {}
        foreach it $lst {

            ## Fix empty it case
            if {$it==""} {
                set it "\"\""
            }

            uplevel $execlevel set it $it
            set res [odfi::closures::doClosure $scriptClosure $execlevel]

            #puts "FILTER: Result is: $res"

            if {$res} {
                #puts "FILTER ACCEPTED: Result is: $res"
                lappend newlst $it
            } else {
                #puts "FILTER REJECTED: Result is: $res"
            }

        }
        return $newlst


    }

    ## \brief Evaluates script for each element of lst, providing $it variable as pointer to element, and $i as index
    # Script is called in one uplevel + the caller whish
    proc each {lst script args} {

        ## -level option
        ###########
        set execlevel 1
        if {[lsearch -exact $args -level]} {
            set execlevel [lindex $args [expr [lsearch -exact $args -level]+1]]
        }

        ## Exec level +1 to cover the current execution level
        set execlevel [expr $execlevel+1]

        ####

        foreach it $lst {

            uplevel $execlevel set it $it
            odfi::closures::doClosure $script $execlevel
        }



    }

    ## \brief Returns only the first match of the closure on the list
    proc firstMatch {lst closure args} {

        ## -level option
        ###########
        set execlevel 1
        if {[lsearch -exact $args -level]>-1} {
            set execlevel [lindex $args [expr [lsearch -exact $args -level]+1]]
        }

        ## Exec level +1 to cover the current execution level
        set execlevel [expr $execlevel+1]

        ####

        foreach it $lst {

            ## Fix empty it case
            if {$it==""} {
                set it "\"\""
            }

            uplevel $execlevel set it $it
            set res [odfi::closures::doClosure $closure $execlevel]

            if {$res} {
                return $it
            }
        }

        return {}

    }

    ## \brief Evaluates script for each key/pair arrayVar, providing $key variable as pointer to key, and $value as value
    # Script is called in one uplevel
    proc arrayEach {arrayList script} {

        foreach {key value} $arrayList {
            uplevel 1 "set key $key"


              #  puts "$key -> '$value' [llength $value]"


            if {[llength $value]>1} {
                uplevel 1 "set value {$value}"
            } else {
               uplevel 1 "set value $value"
            }

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

    ## \brief Returns 1 if the arrayList contains the key, 0 otherwise
    proc arrayContains {arrayList key} {

        ## Find key
        set keyIndex [lsearch -exact $arrayList $key]
        if {$keyIndex==-1} {
            return false
        } else {
            return true
        }

    }

    ## \brief Replace the value for key in list, or set it if not found
    ## @return The modified list
    proc arrayReplace {arrayList key value} {

        ## Find key
        set keyIndex [lsearch -exact $arrayList $key]
        if {$keyIndex==-1} {
            lappend arrayList $key $value
        } else {
            set valueIndex [expr $keyIndex+1]
            set arrayList [lreplace $arrayList $valueIndex $valueIndex $value]
        }

        return $arrayList

    }

    ## \brief Concat the value for key in list, or set it if not found
    ## @return The modified list
    proc arrayConcat {arrayList key value} {

        ## Find key
        set keyIndex [lsearch -exact $arrayList $key]
        if {$keyIndex==-1} {
            lappend arrayList $key $value
        } else {
            set valueIndex [expr $keyIndex+1]
            set arrayList [lreplace $arrayList $valueIndex $valueIndex [concat [arrayGet $arrayList $key] $value]]
        }

        return $arrayList

    }

    ## \brief Returns all the list range that is included between the indexes of give start and end keys
    proc arrayBetweenKeys {arrayList start_key end_key} {

        ## Find key
        set keyIndex [lsearch -exact $arrayList $start_key]
        if {$keyIndex==-1} {
            error "Could not find start key $key in array list"
        }

        ## Return result
        set res {}
        for {set i [expr $keyIndex+1]} {$i<[llength $arrayList]} {incr i} {
            set elt [lindex $arrayList $i]
            if {$elt==$end_key} {
                break
            } else {
                lappend res $elt
            }
        }
        return $res

    }

    proc arrayFromKey {arrayList start_key elementsCount} {

        ## Find key
        set keyIndex [lsearch -exact $arrayList $start_key]
        if {$keyIndex==-1} {
            error "Could not find start key $key in array list"
        }

        ## Return result
        return [lrange $arrayList [expr $keyIndex+1] [expr $keyIndex+1-1+$elementsCount]]

    }

    ## \brief takes from statrt_key, and stops at first element that does not start with ''
    proc arrayFromKeyToNext {arrayList start_key} {

        ## Find key
        set keyIndex [lsearch -exact $arrayList $start_key]
        if {$keyIndex==-1} {
            error "Could not find start key $key in array list"
        }

        ## Return result
        set res {}
        for {set i [expr $keyIndex+1]} {$i<[llength $arrayList]} {incr i} {

            set elt [lindex $arrayList $i]
            set firstChar [string index $elt 0]

            puts "Is $firstChar of $elt upper: [string is upper $firstChar] ?"

            if {$firstChar!=" " && [string is upper $firstChar]} {
                break
            } else {
                lappend res $elt
            }
        }
        return $res

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
            set val [odfi::closures::doClosure $closure]
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

namespace eval odfi::regexp {


    ## Matched expression as much as possible in string, and executes closure for every match
    ## Closure gets variables:
    ##   - matchContent for the matched content
    ##   - groupX for every submatch group
    proc pregexp {expression string matchClosure} {

        ## Prepare
        ################

        ## start in string
        set startIndex 0

        ## Stop/Continue match loop
        set continue 1

        ## Total length of string
        set stringLength [string length $string]

        ## Match Loop
        ###############
        while {$continue==1} {

            ## Match
            set matchRes [regexp -inline -indices -start $startIndex $expression $string]
            if {[llength $matchRes]>0} {

                #puts "Progressive regexp res: $matchRes"

                ## Result not empty -> Gather variables
                ##############
                set matchIndices [lindex $matchRes 0]
                uplevel "set matchContent [string range $string [lindex $matchIndices 0] [lindex $matchIndices 1]]"

                ## update advancement and next start
                set startIndex  [expr [lindex $matchIndices 1]+1]
                uplevel "set progress    [expr $startIndex*100/$stringLength]"

                ## groups
                set groupIndex 0
                foreach groupIndices [lrange $matchRes 1 end] {
                    uplevel "set group$groupIndex [string range $string [lindex $groupIndices 0] [lindex $groupIndices 1]]"
                    incr groupIndex
                }

                ## Call closure
                odfi::closures::doClosure $matchClosure 1

            } else {

                ## Stop
                set continue 0
            }

        }

    }

}


namespace eval odfi::search {


    ## \brief Extracts contents between marker 1 and marker 2, and apply closure for each
    proc markerSplit {string marker1 marker2 closure} {

        ## Begin
        set start 0

        ## Stop marker
        set continue 1

        ## Total length of string
        set stringLength [string length $string]

        while {$continue == 1} {

            ## Find positions
            set m1Position [lsearch -exact -start $start $string $marker1]
            set m2Position [lsearch -exact -start $start $string $marker2]

            ## Apply if found
            if {$m1Position>=0 && $m2Position>0} {

                ## Extract
                uplevel set matchContent "{[lrange $string [expr $m1Position+1] [expr $m2Position-1]]}"

                ## update advancement and next start
                set start  [expr $m2Position+1]
                uplevel "set progress    [expr $start*100/$stringLength]"



                ## Call closure
                odfi::closures::doClosure $closure 1


            } else {

                set continue 0
            }

        }

    }


}
