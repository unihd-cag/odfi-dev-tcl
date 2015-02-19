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

        :protected method none {closure {-level 1}} {
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
        :variable -accessor public content {}

        ## Operators 
        #######################

        :public method += args {
            #puts "Appending $element"
            foreach arg $args {lappend :content $arg}
            
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

            ## Loop
            ::foreach it ${:content} {

                ## Fix empty it case
                if {$it==""} {
                    set it "\"\""
                }
                set it $it

                ## Run Search Closure 
                #puts "---> Search closure"
                set res [odfi::closures::applyLambda $searchClosure [list it "$it"]]
                #puts "-----> Return $res"
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
                    puts "Error message?  // [info exists errorMessage]"
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
