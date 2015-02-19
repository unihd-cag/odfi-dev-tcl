## Flex tree is a common tree interface for various ODFI TCL tools
package provide odfi::flextree 1.0.0
package require odfi::flist 1.0.0



namespace eval odfi::flextree {

    ## A Mixin trait to make a class a FlexTree Node
    nx::Class create FlexNode {

        ## Reference to the parents
        :property -accessor public parents

        ## Children
        :property  children

        ## Current Shading 
        :variable currentShading false

        :method init {} {

            ## Init parent and children
            set :parents [odfi::flist::MutableList new]
            set :children [odfi::flist::MutableList new]

            next
        }

        ## Closure Apply 
        #####################

        ## \brief Executes the provided closure into this object
        :public method apply closure {
            ::odfi::closures::run $closure
        }

        ## Children and shading 
        ################

        ## @return The Children FList with full content or the shade sub-content if a shade criterion is defined at the moment
        :public method children args {
            if {${:currentShading}==false} {
                return ${:children}
            } else {
                set res [odfi::flist::MutableList new]
                ${:children} foreach {
                    #puts "is $it of type $select"
                    if {[odfi::common::isClass $it ${:currentShading}]} {
                        $res += $it
                    }
                }
                return $res
            }
        }

        ## Parent Interface 
        ############################
        :public method addParent p {
            ${:parents} += $p
            next
        }

        ## @return The depth of this node from provided parent, using direct line, meaning, only the primary parents
        :public method getPrimaryDepthFrom parent {
            switch -exact -- $parent {
                "" {
                    return 0  
                }
                default {
                    set current $parent
                    set depth 1
                    while {[llength [$current parents]]>0} {
                        ::incr depth
                        set current [lindex [$current parents] 0]
                    }
                    return $depth
                }
            }
        }

        ## Children Interface 
        ################################
        :public method eachChild {closure} {
            [:children] foreach {
                odfi::closures::applyLambda $closure [list it $it]
            }
            #${:children} foreach $closure -level 1
        }

        

        :public method child index {
            return [[:children] at $index]
        }


        :public method childCount args {
            return [[:children] size]
        }

        ## Add the node as child of this, and adds itself to the possible parents
        :public method addChild node {

            $node addParent [current object]
            ${:children} += $node

            next
        }

        ## Tree Search Interface 
        #####################################

        ## Tree Walking 
        ####################

        ## Runs closure on this subtree providing node/parent variable pairs
        ## Closure parameters: $parent  and $node 
        :public method walk closure {

            ## Prepare list : Pairs of Parent / node
            ##################
            set componentsFifo [list $this]

            ## Go on FIFO 
            ##################
            while {[llength $componentsFifo]>0} {

                set item [lindex $componentsFifo 0]
                set componentsFifo [lreplace $componentsFifo 0 0]


                odfi::closures::doClosure $closure 1

                ## Group -> add all subgroups and registers as next possible Continue 
                ##############
                if {[$item isa [namespace current]]} {
                   
                   #::puts "Gound gorupd"
                   set componentsFifo [concat $componentsFifo [$item components]]
                   
                } elseif {[$item isa [namespace parent]::Register]} {
                    set componentsFifo [concat $componentsFifo [$item fields]]
                }
            }
        }


        :public method walkWith closure {

           # puts "-- Walking tree of $this"

            ## Prepare list : Pairs of Parent / node
            ##################
            set componentsFifo [$this components]

            ## Go on FIFO 
            ##################
            while {[llength $componentsFifo]>0} {

                set it [lindex $componentsFifo 0]
                set componentsFifo [lreplace $componentsFifo 0 0]

                set res [odfi::closures::doClosure $closure 1]


                ## If Decision is true and we have a group -> Go down the tree 
                #################
                if {$res && [$it isa [namespace current]]} {
                    set componentsFifo [concat $componentsFifo [$it components]]
                }

            }
        }

        :public method walkDepthFirst closure {

           # puts "-- Walking tree of $this"

            ## Prepare list : Pairs of Parent / node
            ##################
            set componentsFifo [$this components]

            ## Go on FIFO 
            ##################
            while {[llength $componentsFifo]>0} {

                set it [lindex $componentsFifo 0]
                set componentsFifo [lreplace $componentsFifo 0 0]


                #puts "--> Element $it"

                set res [odfi::closures::doClosure $closure 1]

                ##puts "---> Decision: $res"

                ## If Decision is true and we have a group -> Go down the tree 
                #################
                if {([string is boolean $res] && $res) && [$it isa [namespace current]]} {
                    set componentsFifo [concat [$it components] $componentsFifo]
                }

            }
        }

        ## Shading
        ####################################



        ## Create a ShadeView using the select criterion
        :public method shadeView {select} {
            set res {}
            ${:children} foreach {
                puts "is $it of type $select"
                if {[odfi::common::isClass $it $select]} {
                    lappend res $it
                }
            }
            return $res
        }

        ## Chain a shade view and a method call to a shadable method
        :public method shade {select method args} {
            
            #odfi::log::fine "Doing shade of type $select for $method, with arg: $args, argsize: [llength $args]"

            ## Set shading 
            set :currentShading $select 

            ## Propagate and make sure shading is resetted 
            try {
                :$method [lindex $args  0]
            } finally {
                set :currentShading false
            }
        }   

    }

}
