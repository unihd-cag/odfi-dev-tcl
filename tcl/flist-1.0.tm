package provide odfi::flist 1.0.0
package require odfi::closures 3.0.0
package require nx



namespace eval odfi::functional::pattern {


    nx::Class create Option {

        :property content:required
        :property {none:boolean false}

        ## Matches 
        ##############
        
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
               
                uplevel $level [list odfi::closures::applyLambda $closure [list $varName "${:content}"]]
            }
        }

        :protected method none {closure {-level 2}} {
            if {${:none}} {
                uplevel $level [list odfi::closures::applyLambda $closure]
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
                if {[odfi::common::isClass $arg [namespace current]::MutableList]} {
                    set :content [concat ${:content} [$arg content get]]
                } else {
                    lappend :content $arg
                }
                
            }
            
            #puts "Appending $element"
            
            
        }
        
        :public method remove item {
            :-= $item
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
           # puts "in foreach of ${:content}"
            ::foreach it ${:content} {
                #puts "---> SForeach"
                uplevel $level [list odfi::closures::applyLambda $closure [list it "$it"]]
            }
        }

        :public method foreachOpt {closure {-level 1}} {

            odfi::closures::withITCLLambda $closure $level {
                ::foreach it ${:content} {
                    $lambda apply [list it $it]
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

        :public method foreachOpt2 {closure {-level 1}} {

            set lambdaObj [odfi::closures::Lambda::build $closure]
            $lambdaObj prepare

           # puts "in foreach of ${:content}"
            ::foreach it ${:content} {
                #puts "---> SForeach"
                #uplevel $level [list odfi::closures::applyLambda $closure [list it "$it"]]

                $lambdaObj apply [list it $it]
            }
        }

        ## Pop the first and run closure on it, until empty
        :public method popAll {closure} {
            while {[:size]>0} {
                uplevel [list odfi::closures::applyLambda $closure [list it [:pop]]]
            }
        }

        ## Pop the first and run closure on it, until empty
        :public method popAllOpt {closure} {
            
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
            ::foreach it ${:content} {

                ## Run
                set res [uplevel $level [list odfi::closures::applyLambda $closure [list it "$it"]]]
                $resList += $res
            }

            ## Return 
            return $resList
        }

        ## @return an Flist with content filtered for duplicates using lsort -unique
        :public method compact args {

            set resList [[namespace current]::MutableList new ]

            foreach res [lsort -unique [:content]] {
                $resList += $res
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
            }


            return $front[join ${:content} $main]$back

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

            ## Map
            ::foreach it ${:content} {

                ## Run
                set res [uplevel $level [list odfi::closures::applyLambda $closure [list it "$it"]]]

                #puts "Filter res: $res"
                if {$res==true || $res==1} {
                    $resList += $it
                }
               
            }

            ## Return 
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

        
            ## Loop
            ::foreach it ${:content} {

               ## Run
               set res [uplevel $level [list odfi::closures::applyLambda $searchClosure [list it "$it"]]]
               #puts "Result -> $res"
               
               ## Return Matched
                if {$res} {
                    return [odfi::functional::pattern::Option some $it]
                }

            }

            ## Return empty
            return [odfi::functional::pattern::Option::none]


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
            foreach elt $lst {
                $mlist += $elt
            }

            return $mlist

        }


    }
    ## EOF Mutable list 


}



namespace eval odfi::fmap {



}
