package provide odfi::flist 1.0.0
package require odfi::closures 3.0.0
package require nx



namespace eval odfi::functional::pattern {


    nx::Class create Option {

        :property content:required
        :property {none:boolean false}

        ## Matches 
        ##############
        :public method isNone args {
            return ${:none}
        }
        :public method isDefined args {
            return [expr ! ${:none}]
        }

        :public method getContent args {
            return ${:content}
        }

        :public method match closure {

            if {!${:none}} {
                
                ## Some 
                set someIndex [lsearch -exact $closure ":some"]
                if {$someIndex!=-1} {
                    :some [lindex $closure [expr $someIndex+1]] [lindex $closure [expr $someIndex+2]]
                }

            } else {
                
                ## None 
                set noneIndex [lsearch -exact $closure ":none"]
                if {$noneIndex!=-1} {
                    :none [lindex $closure [expr $noneIndex+1]]
                }

            }

            #try {
            #    return [odfi::closures::applyLambda $closure]
            #}  on return {res resOptions} {
            #        puts "Caught return in match: $res"
            #}
        }

        :protected method some {varName closure {-level 2}} {
            if {!${:none}} {   
               odfi::closures::withITCLLambda $closure $level {
                    $lambda apply [list $varName "${:content}"]
               }
               # uplevel $level [list odfi::closures::applyLambda $closure [list $varName "${:content}"]]
            }
        }

        :protected method none {closure {-level 2}} {
            if {${:none}} {
                odfi::closures::withITCLLambda $closure $level {
                    $lambda apply
                }
                #uplevel $level [list odfi::closures::applyLambda $closure]
            }
        }

        ## Factories
        ################
        :public object method none args {
            return [Option new -content "" -none true ]
        }

        :public object method some value {
            return [Option new -content $value -none false ]
        }

    }


}

namespace eval odfi::flist {

    ################################################################################
    ## Classes
    ################################################################################
    odfi::common::resetNamespaceClasses [namespace current]


    #####################
    ## Functional List 
    #######################
    nx::Class create MutableList {

        ## Content 
        :property -accessor public {content {}}

        ## Operators 
        #######################


        :public method += args {

            foreach arg $args {
                #if {[odfi::common::isClass $arg [namespace current]::MutableList]} {
                #    set :content [concat ${:content} [$arg content get]]
                #} else {
                    lappend :content $arg
                #}
                
            }
            return [current object]
            
            #puts "Appending $element"
            
            
        }

        ## Add Elements to the list. If one of them is another list, then just concact
        :public method import args {
            foreach arg $args {
                if {[odfi::common::isClass $arg odfi::flist::MutableList]} {
                    $arg foreach {
                        :+= $it
                    }
                } else {
                    :+= $arg
                }
            }
        }
        
        :public method remove item {
            :-= $item
        }

        ## Drops #count elements from the left of the list
        :public method drop count {
            ::repeat $count {
                :-= [:at 0]
            }
        
        }

        :public method -= item {
                
            ##get index
            set index [:indexOf $item]
            if {$index==-1} {
                odfi::log::error "Cannot remove item $item from list [current object] if it is not contained in it "
            } else {
                set :content [lreplace ${:content} $index $index]
            }
           
        }
        
        :public method - item {
        
            set n [[namespace current]::MutableList new]
            
            :foreach {
             
                if {$it!=$item} {
                    $n += $it
                }
            }
            
            return $n
            
         
            
        }
        

        :public method addFirst args {
            set :content [concat $args ${:content}]
        }
        
        :public method removeFirst args {
            
            if {[:size]>0} {
                set first [lindex ${:content} 0]
                set :content [lrange ${:content} 1 end]
                return $first
            } else {
                error "Cannot remove first of empty list"
            }
                
        }
        
        :public method clear args {
            set :content {}
        }
        
        ## Set value for specific index 
        :public method setAt {i value} {
            if {$i>=[:size]} {
                error "Index $i out of boundaries for list of size [:size]"
            }

            set :content [lreplace ${:content} $i $i $value]
        }

        ## Append value to existing value at index 
        :public method appendAt {i value} {

            ## Get actual value 
            set actual [:at $i]

            ## Append 
            lappend actual $value 

            ## Set 
            :setAt $i $actual
        }

        ## Stack Like operators
        ##########################
        
        :public method push args {
            :addFirst $args
        }
        :public method peek args {
            return [lindex ${:content} 0] 
        }
        :public method pop args {
            return [:removeFirst]
        }
        
        

        ## Iterator
        ###########################

        :public method foreach {closure {-level 1}} {

            odfi::closures::withITCLLambda $closure $level {
                set i 0
                ::foreach it ${:content} {
                    $lambda apply [list it $it] [list i $i]
                    incr i
                }
            }

            return 
            #set itclLambda [odfi::closures::buildITCLLambda $closure]
            #$itclLambda configure -definition $closure
            #$itclLambda configure -level $level
            #$itclLambda prepare

           # puts "in foreach of ${:content}"
            ::foreach it ${:content} {
                #puts "---> SForeach"
                #uplevel $level [list odfi::closures::applyLambda $closure [list it "$it"]]

                $itclLambda apply [list it $it]
            }

            unset itclLambda
        }

        :public method foreachWithIndex {closure {-level 1}} {

            odfi::closures::withITCLLambda $closure $level {
                set i 0
                ::foreach it ${:content} {
                    $lambda apply [list it $it] [list i $i]
                    incr i
                }
            }

        }


        :public method foreachFrom {start closure {-level 1}} {

            odfi::closures::withITCLLambda $closure $level {
                #puts "FOreach from $start"
                for {::set __i $start} {$__i<[:size]} {::incr __i} {
                     $lambda apply [list it [lindex ${:content} $__i]] [list i $__i]
                }
             
            }

        }            

        ## Pop the first and run closure on it, until empty
        :public method popAllOld {closure} {
            while {[:size]>0} {
                uplevel [list odfi::closures::applyLambda $closure [list it [:pop]]]
            }
        }

        ## Pop the first and run closure on it, until empty
        :public method popAll {closure} {
            
            odfi::closures::withITCLLambda $closure 1 {
                while {[:size]>0} {
                     $lambda apply [list it [:pop]]
                }

            }
            return 

            set itclLambda [::new odfi::closures::LambdaITCL #auto]
            $itclLambda configure -definition $closure
            $itclLambda prepare

            try {
                while {[:size]>0} {
                    #uplevel [list odfi::closures::applyLambda $closure [list it [:pop]]]
                    uplevel [list $itclLambda apply [list it [:pop]]]
                }
            } finally {
                odfi::common::deleteObject $itclLambda
            }
        }


        ## Accessor
        ####################

        :public method size args {
            return [llength ${:content}]
        }

        :public method first args {
            return [lindex ${:content} 0]
        }

        :public method last args {
            return [lindex ${:content} end]
        }

        :public method at i {
            return [lindex ${:content} $i]
        }

        :public method sublist {start end {-empty:optional}} {

            ## Return list 
            #::puts "Sublist from : $start $end -> [lrange ${:content} $start $end]"
            set r [MutableList new]
            foreach elt [lrange ${:content} $start $end] {
                $r += $elt
            }
            
            
            return $r         
            
            ## 
            
            if {[catch {set empty}]} {
                set empty false 
            }

            ## Check boundaries, and return an error or empty list 
            if {$start >= [:size] || ($end < $start)} {
                if {$empty} {
                    return [MutableList new]
                } else {
                    error "boundaries $start - $end are not correct for size [:size]"
                }
            }

            
        }

        :public method reverse args {
            return [MutableList new -content [lreverse ${:content}]]
        }
        
        ## Returns a TCL List with format: { VALUE MUTABLELIST VALUE MUTABLELIST}
        ## Each list contains an element whose closure returned the key value        
        :public method groupByAsList closure {

            set resList {}
            odfi::closures::withITCLLambda $closure 0 {

                ::foreach it ${:content} {

                    set key [$lambda apply [list it $it]]

                    ## Search for key 
                    ## Create list, or get existing and add 
                    set keyIndex [lsearch -exact $resList $key]
                    if {$keyIndex==-1} {
                        set list  [MutableList new]
                        lappend resList $key $list
                    } else {
                        set list [lindex $resList [expr $keyIndex+1]]
                    }
                    $list += $it

                }

            }

            return $resList

        }

        ## Positioning
        #############################
        
        :public method setIndexOf {child position} {
            
            ## Get position
            set actualIndex [:indexOf $child]
            
            ## Insert
            set :content [linsert ${:content} $position $child]
            
            ## Remove old position (which si now +1)
            set :content [lreplace ${:content} [expr $actualIndex+1] [expr $actualIndex+1]]
            
            return             
            
            ## Check boundaries
            if {$position < 0 || $position >= [:size]} {
                error "Cannot set Index Of $child to $position, off-boundaries"
            } else {
                ## Get position
                set actualIndex [:indexOf $child]
                
                ## Insert
                set :content [linsert ${:content} $position $child]
                
                ## Remove old position (which si now +1)
                set :content [lreplace ${:content} [expr $actualIndex+1] [expr $actualIndex+1]]
            }
        }
        

        ## Transform 
        ##################

        :public method map {closure {-level 1}} {

            ## Prepare result list 
            set resList [[namespace current]::MutableList new ]

            ## Map
            odfi::closures::withITCLLambda $closure $level {


                ::foreach it ${:content} {

                    set res [$lambda apply [list it "$it"]]
                    $resList += $res
                }
                    
            
            }

            return $resList
            ::foreach it ${:content} {

                ## Run
                set res [uplevel $level [list odfi::closures::applyLambda $closure [list it "$it"]]]
                $resList += $res
            }

            ## Return 
            return $resList
        }
        
        :public method flatten args {
        
            set resList [[namespace current]::MutableList new ]
            :foreach {
                if {[$it isClass [namespace current]::MutableList]} {
                    $it foreach {
                        $resList += $it
                    }
                } else {
                    $resList += $it
                }
            }
            
            return $resList
        }
        


        ## Sorting 
        ####################


        ## @return an Flist with content filtered for duplicates using lsort -unique
        :public method compact args {

            set resList [[namespace current]::MutableList new ]

            foreach res [lsort -unique ${:content}] {
                $resList += $res
            }

            return $resList

        }

        ## map elements and sort based on map result 
        :public method mapSort closure {

            ## Map to { {elt mappedValue} }
            set eltAndMapped {}
            set mapped [[:map $closure] asTCLList]
            set __i 0
            foreach mappedElt $mapped {
                lappend eltAndMapped [list [lindex ${:content} ${__i}] $mappedElt]
                incr __i
            }

            ## Sort 
            #puts "unsorted: $eltAndMapped"
            set eltAndMapped [lsort -index 1 -nocase $eltAndMapped]
            #puts "sorted: $eltAndMapped"

            ## Set Result 
            set resList [[namespace current]::MutableList new ]
           
            foreach res $eltAndMapped {
                $resList += [lindex $res 0]
            }

            return $resList

        }


        :public method asTCLList args {
            return ${:content}
        }
        :public method toTCLList args {
            return ${:content}
        }        

        :public method mkString sep {

            ## Separators from args 
            if {[llength $sep]>2} {
                set front [lindex $sep 0]
                set main [lindex $sep 1]
                set back [lindex $sep 2]
            } elseif {[llength $sep]==2} {
                set front ""
                set main [lindex $sep 0]
                set back [lindex $sep 1]
            } else {
                set front ""
                set main [lindex $sep 0]
                set back ""
            }
            
            ## If nothing in the list, don't add front and back 
            if {[:size] == 0} {
                set front "" 
                set back ""
                return ""
            }

            if {[:size] == 1} {
                return $front[lindex ${:content} 0]$back
            } else {
                return $front[lindex ${:content} 0]$main[join [lrange ${:content} 1 end] $main]$back
            }

            #puts "MKLIST with $front , $main , $back"
            #return $front[lindex ${:content} 0 0][join [lrange ${:content} 1 end] $main]$back

        }

        ## Chain Transform 
        ###########################

        ## args is a list of (method arguments) to be dispatched in a chain
        :public method > args {

            set res [current object]
            foreach {method margs} $args {
                
                #::puts "Dispatching $method with $margs on $res"
                
                set res [$res $method $margs]

                
                #::puts "--> $res"
            }

            return $res
        }

        ## Filtering
        ####################

        :public method filter {closure {-level 1}} {

            ## Prepare result list 
            set resList [[namespace current]::MutableList new ]

            ## Filter on All 
            ## Map
            odfi::closures::withITCLLambda $closure $level {


                ::foreach it ${:content} {

                    set res [$lambda apply [list it "$it"]]
                    if {$res==true || $res==1} {
                        $resList += $it
                    }
            
                }
                    
            
            }
            return $resList

            

        }

        ## Just like #filter , but removes the matching elements from list
        :public method filterRemove {closure {-level 1}} {

            ## Prepare result list 
            set resList [[namespace current]::MutableList new ]

            ## Filter on All 
            ## Map
            odfi::closures::withITCLLambda $closure $level {


                ::foreach it ${:content} {

                    set res [$lambda apply [list it "$it"]]
                    if {$res==true || $res==1} {
                        $resList += $it

                    }
            
                }
                    
            
            }

            ## Remove 
            $resList foreach {
                :remove $it
            }
            return $resList

            

        }

        :public method filterNot {closure {-level 1}} {

            ## Prepare result list 
            set resList [[namespace current]::MutableList new ]

            ## Filter on All 
            ## Map
            odfi::closures::withITCLLambda $closure $level {


                ::foreach it ${:content} {

                    set res [$lambda apply [list it "$it"]]
                    if {$res==false || $res==0} {
                        $resList += $it
                    }
            
                }
                    
            
            }
            return $resList

            

        }

        ## Search 
        ###############

        :public method contains obj {
            if {[:indexOf $obj]!=-1} {
                return true   
            } else {
                return false
            }
        }
        
        :public method indexOf obj {
            lsearch -exact ${:content} $obj
        }
        
        ## \brief Returns  the first match of the closure on the list
        ## @return The resulting object, or a None value
        :public method findOption {searchClosure {-level 1}} {

            #set timeCall [clock milliseconds]

            ## Loop
            set returnRes [odfi::functional::pattern::Option::none]
            odfi::closures::withITCLLambda $searchClosure $level {


                ::foreach it ${:content} {

                    set res [$lambda apply [list it "$it"]]
                    if {$res} {
                        #puts "$timeCall -> Returning Found"
                        set returnRes [odfi::functional::pattern::Option some $it]
                        break
                    }
            
                }
                    
            
            }

            ## Return empty
            #puts "$timeCall -> Returning $returnRes"
            return  $returnRes

            


        }

        :public method find {searchClosure -errorMessage} {

            #set res "d"
            set returnRes [[:findOption $searchClosure -level 2 ] match {
                :some val {
                    
                    #puts "Will return $val + $res"
                    #set res "$val"
                    #puts "Will return $val + $res"
                    #return "$val // search"
                    return $val
                }

                :none {
                    #puts "Error message?  // [info exists errorMessage]"
                    if {[info exists errorMessage]} {
                        error "$errorMessage"
                    } else {
                        error "Could not find List element matching closure $searchClosure"
                    }
                    
                }
            }]

            #puts "Search result: $res"
            #puts "Search result return: $returnRes"
            return $returnRes

            ## Loop
            #::foreach it ${:content} {

            #   set res [uplevel [list odfi::closures::applyLambda $searchClosure [list it "$it"]]]
             #  puts "Result -> $res"
               
            #}

            #return ""

            

        }

        ## Factories 
        #####################

        :public object method fromList lst {

            set mlist [MutableList new]
           # puts "Creating new list $mlist ([$mlist size]) with input of size [llength $lst]"
            #set ti 0 
            foreach elt $lst {
                $mlist += $elt
               # incr ti
            }
           # puts "Done, now $mlist [$mlist size] big, counter $ti"

            return $mlist

        }


    }
    ## EOF Mutable list 


}



namespace eval odfi::fmap {



}
