## Flex tree is a common tree interface for various ODFI TCL tools
package provide odfi::flextree 1.0.0
package require odfi::flist 1.0.0
package require odfi::log 1.0.0


namespace eval odfi::flextree {

    proc shadeMapFor {select closure} {
     uplevel 1 "
        
        :shadeMap {select closure} {
            if {[string match select ${select}*]} {
            
                
            }
        }
        
        "   
    }
    
    ## A Mixin trait to make a class a FlexTree Node
    nx::Class create FlexNode {

        ## Reference to the parents
        :property -accessor public parents

        ## Children
        :property  children

        ## Current Shading 
        :variable -accessor public currentShading ""

        :method init {} {
            
            #::puts "Flexnode init"
            ## Init parent and children
            set :parents [odfi::flist::MutableList new]
            set :children [odfi::flist::MutableList new]

            next
        }

        ## Closure Apply 
        #####################

        ## \brief Executes the provided closure into this object
        :public method apply closure {
            ::odfi::closures::run %closure
        }

        ## Children and shading 
        ################

        ## @return The Children FList with full content or the shade sub-content if a shade criterion is defined at the moment
        :public method children args {
            if {${:currentShading}==""} {
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
        
        :public method isRoot args {
            if {[${:parents} size]==0} {
                return true
            } else {
                return false
            }
        }
        
        :public method addParent p {
            
            if {![${:parents} contains $p]} {
                ${:parents} += $p
            }
            
            next
        }

        ## Return the primary parent, or an empty string if none
        :public method parent args {
            
            if {[${:parents} size]>0} {
                return [${:parents} at 0]
            } else {
                return ""
            }
            
        }
        
        :public method parents args {
            return ${:parents}
        }
        
        ## Detach removes this node from any parent
        :public method detach args {
            
            ${:parents} foreach {
                $it remove [current object]
            }
            
            ${:parents} clear
        }

        ## @return The depth of this node from provided parent, using direct line, meaning, only the primary parents
        :public method getTreeDepth {{baseParent false}} {
            switch -exact -- [${:parents} size] {
                0 {
                    return 0  
                }
                default {
                    
                    ## Get depth starting from parent order if possible, otherwise fallback from primary
                    if {$baseParent==false} {
                        set baseParent [${:parents} at 0]
                    }
                    #set parent [${:parents} at $parentOrder]
                    
                    set current $baseParent
                    set depth 1
                    while {[[$current parents get] size]>0} {
                        ::incr depth
                        set current [[$current parents get]  at 0]
                    }
                    return $depth
                }
            }
        }

        :public method getPrimaryTreeDepth args {
            return [:getTreeDepth false]
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

        :public method isLeaf args {
            if {[:childCount]>0} {
                return false
            } else {
                return true
            }
        }
        
        ## Add the node as child of this, and adds itself to the possible parents
        :public method addChild node {

            ## Check node is a flexnode
            if {![odfi::common::isClass $node [namespace current]::FlexNode]} {
                error "Cannot add node $node to [[curren$at object] info class] if it is not a FlexNode"
            }
            
            $node addParent [current object]
            ${:children} += $node

            next
        }
        
        ## Add the node as child of this, and adds itself to the possible parents
        :public method add node {

            ## Check node is a flexnode
            if {![odfi::common::isClass $node [namespace current]::FlexNode]} {
                error "Cannot add node $node to [[current object] info class] if it is not a FlexNode"
            }
            
            
            $node addParent [current object]
            ${:children} += $node

            next
        }
        
        ## Remove
        :public method remove child {
            ${:children} -= $child
        }
        
        ## Change child position
        :public method setChildAt {child position} {
        
            ${:children} setIndexOf $child $position            
            return
            set index [${:children} indexOf $child]
            if {$index==-1} {
                error "Cannot call setChildAt for a non-owned child"   
            } else {
                ${:children} setIndexOf $child $position
            }
        }
        
        :public method indexOf child {
            return [${:children} indexOf $child]
        }
        
        ## Returns a sublist of children from start index to end index
        :public method select {start end} {
            return [${:children} sublist $start $end]
        }
        
        #  Self positioning
        #######################
        
        ## Sets its position in parent to first node
        :public method moveToFirstNode args {
            
            if {![:isRoot]} {
                [:parent] setChildAt [current object] 0
            }
        }
        
        ## Sets its position in parent to  node n
        :public method moveToChildPosition n {
            
            if {![:isRoot]} {
                [:parent] setChildAt [current object] $n
            }
        }        

        ## Changes the parent of this node to one level up
        ## (Remove from this parent, and add to parent's parent
        :public method pushUp args {
            
            set parent [:parent]
            if {![$parent isRoot]} {
                :detach
                [$parent parent] add [current object]
            } else {
                error "Cannot push node up, because its parent has no parent"
            }
        
        }

        ## Tree Search Interface 
        #####################################

        :public method totalChildrenCount args {
        
            set count 0
            :walkDepthFirstPreorder {
                incr count
            }            
            
            return $count
        
        }

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

        :public method walkDepthFirstPreorder closure {

            ## Prepare list : Pairs of Parent / node
            ##################
            set componentsFifo [odfi::flist::MutableList new]
            #$componentsFifo += [:children]
            $componentsFifo push [list "false" [current object]]

            #puts "CFifo Size: [$componentsFifo size]"

            ## Go on FIFO 
            ##################
            $componentsFifo popAll {
                
                parentAndNode => 

                    #puts "PANODE $parentAndNode"
                    set node [lindex $parentAndNode 1]
                    set parent [lindex $parentAndNode 0]
                
                    #odfi::log::info "On node2 [$node info class]"
                    
                    ## Evaluation With heuristic
                    #############
                    $node inShade {

                        ## Shade match 
                        if {[:shadeMatch]} {
                            odfi::closures::applyLambda %closure
                        }

                        ## Keep Going
                        #################
               
                        ## Add children of current to front 
                        ${:children} foreach {
                            $componentsFifo addFirst [list $node $it] 
                        }
                    }

                    

                    
                    
              
                   
                    

                    #puts "CFifo Size: [$componentsFifo size]"

                    

            }

        }
        
        ## Reducing
        ##########################
        
        ## Reduce goes starts with leaves
        ## - produces a result for each
        ## - Go to upper level, calling the reduce function, with the subtree results
        ## Closure format: (node, results)
        :public method reduce {{reduceClosure {}}} {
            
            
            ##set reduceClosure false
           # if {[llength $args]>0} {
            #    set reduceClosure [join $args]
           # }
            
            ## Prepare list : Pairs of Parent / node
            ##################
            set componentsFifo [odfi::flist::MutableList new]
            #$componentsFifo += [:children]
            $componentsFifo push [current object]

            #puts "CFifo Size: [$componentsFifo size]"
            
            set parentStack [odfi::flist::MutableList new]
            set leafResults {}
            set nodeResults {}
  
            ## Go on FIFO 
            ##################
            $componentsFifo popAll {
                            
                node => 
                    
                    $node inShade {
                        
                      
                       # ::puts "-> On Object: [[current object] info class] with top stack being [$parentStack peek]"
                        
                        ## If on top of stack, then operate reduce if in shade
                        ## Otherwise, go deeper in the tree
                        if {[$parentStack peek]==[current object]} {
                            
                            if {[:shadeMatch]} {
                                #::puts "---> Produce Result on parent [[current object] info class] which is now leaf "
                               # ::puts "------> LR: [llength $leafResults] , NR: [llength $nodeResults]"
                                
                                ## If no leaf results-> use node results and clear them, save as leaf results
                                ## if leaf results -> reduce and save to node results, clear leaf results
                                if {[llength $leafResults]==0} {
                                    
                                    ## If closure provided, use it, otherwise try the reduce Produce
                                    if {[llength $reduceClosure] >0} {
                                        set reduceRes [odfi::closures::applyLambda $reduceClosure [list it [current object]] [list args $nodeResults]]                                   
                                    } else {
                                        set reduceRes [[current object] reduceProduce $nodeResults]   
                                    }
                                    
                                    set leafResults [concat $leafResults $reduceRes]                                    
                                    
#                                    if {[llength $reduceRes]>1} {
#                                        lappend leafResults $reduceRes
#                                    } else {
#                                        lappend leafResults $reduceRes                               
#                                    }                                       
                                    
                                     #lappend leafResults $reduceRes
                                     set     nodeResults {}
                                    
                                } else {
                                    
                                    ## If closure provided, use it, otherwise try the reduce Produce
                                    if {[llength $reduceClosure] >0} {
                                        set reduceRes [odfi::closures::applyLambda $reduceClosure [list it [current object]] [list args $leafResults]]                                   
                                    } else {
                                        set reduceRes [[current object] reduceProduce $leafResults]   
                                    }
                                    
                                    set nodeResults [concat $nodeResults $reduceRes]
                                    
#                                    if {[llength $reduceRes]>1} {
#                                        lappend nodeResults $reduceRes
#                                    } else {
#                                        lappend nodeResults $reduceRes                               
#                                    }                                    
                                    
                                    #lappend nodeResults $reduceRes
                                    set     leafResults {}
                                    #::set     nodeResults {}
                                   # ::puts "------> 2 LR: [llength $leafResults] , NR: [llength $nodeResults]"
                                }
                                #::puts "------> LR: [llength $leafResults] , NR: [llength $nodeResults]"
                                
                                
                            }
                            
                            ## Remove from top to make sure we don't enter infinite loop
                            $parentStack pop
                            
                        } else {
                            
                            ## Either Behave as parent, or as leave
                            #############
                            
                            ## Determine leaf
                            
                            
                            if {[$node isLeaf] && [:shadeMatch]} {
                                
                                ## Produce result, and add as as result list
                                #::puts "---> Produce Result on leaf [[current object] info class]"
                                
                                ## If closure provided, use it, otherwise try the reduce Produce
                                if { [llength $reduceClosure] >0} {
                                    
                                   #eval $reduceClosure
                                    #lappend leafResults  "()"
                                   # ::puts "**************** LEAF REs"
                                    set reduceRes [odfi::closures::applyLambda $reduceClosure [list it [current object]] [list args ""]] 
                                                                    
                                   # ::puts "**************** EOF LEAF REs"
                                    #::puts "--------> $reduceRes (size: [llength $reduceRes]) "
                                    
                                    #::puts "------> LR: [llength $leafResults] , NR: [llength $nodeResults]"
                                    
                                } else {
                                    set reduceRes [[current object] reduceProduce]  
                                    #::puts "--------> $reduceRes (size: [llength $reduceRes]) "
                                    #lappend leafResults $reduceRes
                                }
                                
                                if {[llength $reduceRes]>1} {
                                    lappend leafResults  [list $reduceRes]
                                } else {
                                    lappend leafResults  [list $reduceRes]                                   
                                }                                  
                                
                                #set reduceRes [[current object] reduceProduce]   
                                #lappend leafResults $reduceRes
                                
                                
                            } elseif {![$node isLeaf]} {
                                
                                ## Bounce back to top, and add children to be done before
                                ::puts "---> Not leaf, Push on top [[current object] info class]"
                                $componentsFifo addFirst [current object]
                                foreach it [lreverse [${:children} asTCLList]] {
                                    $componentsFifo addFirst $it 
                                }
                                #ä${:children} foreach {
                                    
                                #}
                                
                                ## Add our selves to the stack
                                $parentStack push [current object]
                                
                            }
                            
                            
                            
                        }
                         
                        
                    }       

            }
            
            if {[llength $leafResults]} {
                return [join $leafResults]
            } else {
                return [join $nodeResults]
            }
            
            
#            set parentStack [odfi::flist::MutableList new]
#            set ::leafResults {}
#            set ::nodeResults {}
#  
#            ## Go on FIFO 
#            ##################
#            $componentsFifo popAll {
#                            
#                node => 
#                    
#                    $node inShade {
#                        
#                      
#                        ::puts "-> On Object: [[current object] info class] with top stack being [$parentStack peek]"
#                        
#                        ## If on top of stack, then operate reduce if in shade
#                        ## Otherwise, go deeper in the tree
#                        if {[$parentStack peek]==[current object]} {
#                            
#                            if {[:shadeMatch]} {
#                                ::puts "---> Produce Result on parent [[current object] info class] which is now leaf "
#                                ::puts "------> LR: [llength $::leafResults] , NR: [llength $::nodeResults]"
#                                
#                                ## If no leaf results-> use node results and clear them, save as leaf results
#                                ## if leaf results -> reduce and save to node results, clear leaf results
#                                if {[llength $::leafResults]==0} {
#                                    
#                                     ::lappend ::leafResults [[current object] reduceProduce [join $::nodeResults]]
#                                     ::set ::nodeResults {}
#                                    
#                                } else {
#                                    ::lappend ::nodeResults [[current object] reduceProduce [join $::leafResults]]
#                                    ::set ::leafResults {}
#                                    ::puts "------> 2 LR: [llength $::leafResults] , NR: [llength $::nodeResults]"
#                                }
#                                ::puts "------> LR: [llength $::leafResults] , NR: [llength $::nodeResults]"
#                                
#                                
#                            }
#                            
#                            ## Remove from top to make sure we don't enter infinite loop
#                            $parentStack pop
#                            
#                        } else {
#                            
#                            ## Either Behave as parent, or as leave
#                            #############
#                            
#                            ## Determine leaf
#                            
#                            
#                            if {[$node isLeaf] && [:shadeMatch]} {
#                                
#                                ## Produce result, and add as as result list
#                                ::puts "---> Produce Result on leaf [[current object] info class]"
#                                ::lappend ::leafResults [[current object] reduceProduce]
#                                
#                            } elseif {![$node isLeaf]} {
#                                
#                                ## Bounce back to top, and add children to be done before
#                                ::puts "---> Not leaf, Push on top [[current object] info class]"
#                                $componentsFifo addFirst [current object]
#                                foreach it [lreverse [${:children} asTCLList]] {
#                                    $componentsFifo addFirst $it 
#                                }
#                                #ä${:children} foreach {
#                                    
#                                #}
#                                
#                                ## Add our selves to the stack
#                                $parentStack push [current object]
#                                
#                            }
#                            
#                            
#                            
#                        }
#                         
#                        
#                    }       
#
#            }
#            
#            if {[llength $::leafResults]} {
#                return [join $::leafResults]
#            } else {
#                return [join $::nodeResults]
#            }
            #return [join $::leafResults]
            
        }

        
        ## Mapping
        #################################
        
        :public method childrenDifference closure {

            ## Current 
            set currentSize [[:children] size]

            uplevel [list odfi::closures::run $closure]

            ## After 
            set afterSize [[:children] size]
            #odfi::log::info "Before: $currentSize , After: $afterSize"

            ## Return difference 
            return [[:children] sublist $currentSize end -empty true] 

        }

        ## Performs Tree Mapping - Based on generic tree walk
        ## Mapper can be
        ##  - A Closure, in which case, the closure is used to produced the mapping tree
        ##  - A Type name, in which case, the internal node map function is used to produced trees
        :public method map mapType {
                  
            set parentStack [odfi::flist::MutableList new]
            
            set componentsFifo [odfi::flist::MutableList new]
            $componentsFifo push [current object]
            $componentsFifo popAll {
             node => 
                
                ## If node is equal to parent, destack parent!
                if {[$parentStack contains $node]} {
                    
                } elseif {[$parentStack peek]==$node} {
                   
                    if {[$parentStack size]>1} {
                        $parentStack pop
                    }
                    
                    
                    
                } elseif {[odfi::common::isClass $node [namespace current]::FlexNode]} {
                    
                    odfi::log::info "(MAP) On node [$node info class]"
                    
                    
                    
                    
                    ## Call Mapping
                    ## If node is already the target mapping type, don't map
                    set mr false
                    if {[odfi::common::isClass $node $mapType]} {
                        set mr $node
                    } else {
                        set mr [$node mapNode $mapType]
                    }
                    
    
                    ## Stack the result to current parent if there is a result
                    if {[odfi::common::isClass $mr $mapType]} {
                        
                        if {[$parentStack size]>0} {
                            [$parentStack peek] addChild $mr
                        }
                        
                        
                        if {[[[$node children] - $mr] size]>0} {
                            
                            $parentStack push $mr
                        }
                    } 
                    
                    
                    ## Continue with the normal children
                    ## After the children are done, add a closure to destack the parent
                    if {[[[$node children] - $mr] size]>0} {
                        
                        #$componentsFifo += [list $parentStack push $mr]
                        $componentsFifo += [$node children]
                        #$componentsFifo += {
                        #    $parentStack pop
                        #}
                    }
                    
                } else {
                    odfi::closures::run $node
                }
                   
            }
            
            return [$parentStack peek]
            
            
#            :genericWalk {
#                
#                odfi::log::info "(MAP) On node [$node info class]"
#
#                if {$isClosure} {
#
#                } else {
#
#                    
#                    ## Call Mapping and monitor adds
#                    set mr false
#                    set mr [$node mapNode $mapper]
#                    
#                    odfi::log::info "(MAP)    res $mr"
#                    
#                    ## If any children, add result or node to parents stack
#                    ## If no children destack parent if we are the last of the current childre
#                    if {[node childCount]>0} {
#                        $parentStack push [expr $mr == false ? $node : $mr]
#                    } else {
#                        
#                        if {[$parentStack size]>0 && [$parentStack at end] == $node]} {
#                            $parentStack pop
#                        }
#                        
#                    }
#                    
#                    ## If a mapping result was returned, add
#                    
#                    #set diff [$node childrenDifference {
#                    #    $node mapNode $mapper
#                    #}]
#
#                    ## If nothing more , stop
#                    #odfi::log::info "Mapping result: [$diff size]"
#                    #return [expr [$diff size] > 0 ? true : false]
#                    
#                    return true
#                    
#                }
#
#                return true
#            }
        }

        ## This method is called by other shade methods, to generate a version of this node matching the provided criterion
        ##  - The Method should create some new nodes, and can add them to the tree
        ##  - Subsequent optimisations shall be performed by the API
        :public method mapNode select {
            
            next
            
        }
        
        

        ## Generic Walk
        ## - Walk the tree
        ## - Run provided closure on each node
        :public method genericWalk closure {
            
            ## Prepare list : Pairs of Parent / node
            ##################
            set componentsFifo [odfi::flist::MutableList new]
            #$componentsFifo += [:children]
            $componentsFifo push [current object]

            #puts "CFifo Size: [$componentsFifo size]"

            ## Go on FIFO 
            ##################
            $componentsFifo popAll {
                
                node => 

                    #odfi::log::info "On node2 [$node info class]"
                    
                    ## evaluate 
                    set hres [odfi::closures::applyLambda $closure]

                    ## Don't add children if heuristic result is false 
                    #odfi::log::info "Heuristic result: $hres"
                    if {$hres} {
                        
                        $componentsFifo += [$node children]
                    }
                    

                    #puts "CFifo Size: [$componentsFifo size]"

                    

            }
           
           

                ## If Decision is true and we have a group -> Go down the tree 
                #################
                #if {$res && [$it isa [namespace current]]} {
                #    set componentsFifo [concat $componentsFifo [$it components]]
                #}

        
            
        }
        
        
        ## Shading
        ####################################
        
        ## Create a ShadeView using the select criterion
        :public method shadeView {select} {
            set res {}
             
            ## Select the matching Children
            ############
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
                set :currentShading ""
            }
        }   

        ## Checks whether the current node matches the shade 
        :public method shadeMatch args {
            if {${:currentShading}==""} {
                return true 
            } else {
                #::puts "Shade Match testing [[current object] info class] against ${:currentShading}"
                return [odfi::common::isClass [current object] ${:currentShading}]
            }
        }

        ## Runs closure on current node, previously copying parent shading 
        :public method inShade closure {

            ## Check tehre is a parent 
            if {[${:parents} size]>0} {
               ## Copy shading 
                set :currentShading [[:parent] currentShading get]
            }


            ## Run
            #odfi::closures::run $closure
            :apply %closure
        }

    }

}


namespace eval odfi::flextree::utils {
    
    nx::Class create StdoutPrinter {
        
        
        :public method printAll args {
            
            [current object] walkDepthFirstPreorder {
            
                set tab "----[lrepeat [$node getTreeDepth $parent] ----]"
            
                ::puts "$tab[$node info class]"
            
            }
        }
        
    }
        
    
}
