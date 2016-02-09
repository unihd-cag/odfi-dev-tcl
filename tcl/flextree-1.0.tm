## Flex tree is a common tree interface for various ODFI TCL tools
package provide odfi::flextree 1.0.0
package require odfi::flist 1.0.0
package require odfi::log 1.0.0
package require odfi::epoints 1.0.0

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
    nx::Class create FlexNode -superclasses {odfi::epoints::EventPointsSupport} {

        ## Reference to the parents
        :property -accessor public parents

        ## Children
        :property  children

        ## Current Shading 
        :variable -accessor public currentShading ""

        :method init args {
            next

            #::puts "Flexnode init"
            ## Init parent and children
            set :parents [odfi::flist::MutableList new]
            set :children [odfi::flist::MutableList new]

            ## Register Event Points 
            :registerEventPoint childAdded child
            :registerEventPoint parentAdded parent

            
        }

        ## Mem copy: Reinit the class
        #################
        :public method copy args {
            set cp [next]
            #puts "Got copy $cp"
            $cp apply {
                :init
            }
            #set :parents [odfi::flist::MutableList new]
            #set :children [odfi::flist::MutableList new]

            return $cp
        }

        ## Closure Apply 
        #####################

        ## \brief Executes the provided closure into this object
        :public method apply closure {


            #odfi::closures::withITCLLambda $closure 2 {
            #    $lambda apply
            #}

            #return
            #::odfi::closures::run %closure
            #return 

            #puts "Will be running $closure on [:info class] -> [:info lookup methods]"
            set l [odfi::closures::buildITCLLambda $closure]
            try {
                $l apply
            } finally {
                odfi::closures::redeemITCLLambda $l
            }
            #::odfi::closures::run %closure
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
                :callParentAdded $p
                next
                return true 
            }
            return false
            
            


        }

        ## Return the primary parent, or an empty string if none
        :public method parent { {index 0}} {
            
            set parents [:parents]
            return [$parents at $index]

            ## Old
            if {[$parents size]>0} {

                set p [$parents at 0]

                if {$method !=""} {
                    #puts "Running $method"
                    return [$p $method $args]
                }

                return [$parents at 0]
            } else {
                return ""
            }
            
        }
        
        ## Supporting Shading
        :public method parents args {

            if {${:currentShading}==""} {
                return ${:parents}
            } else {

                ## Create result list 
                set res [${:parents} filter ${:currentShading}]
                return $res


            

                ## Check shading before adding to list 
                #if {${:currentShading}=="" || [odfi::closures::applyLambda ${:currentShading} [list it $parent]]} {
                #    $res addFirst $parent 
                #}

            

            }
        
        }

        :public method getParentsRaw args {
            return ${:parents}
        }

        #:public 
        
        ## Go up the main parent line until no more
        :public method getRoot args {
            
            set current [current object]
            while {true} {
                if {[$current isRoot]} {
                    return $current
                } else {
                    set current [$current parent]
                }
            }
        }
        
        ## Detach removes this node from any parent
        :public method detach args {
            
            ${:parents} foreach {
                $it remove [current object]
            }
            
            ${:parents} clear
        }

        ## Detach removes this node from specific parent 
        :public method detachFrom parent {
            
     
            $parent remove [current object]
            ${:parents} -= $parent
            
            ##${:parents} clear
        }

        ## Clear Parents 
        ## @noshade
        :public method clearParents args {
            
            ${:parents} clear
        }

        ## Set First parent of child 
        :public method setFirstParent parent {

            if {$parent==[current object]} {
                return 
            }
            
            $parent addChild [current object]

            ${:parents} remove $parent 
            ${:parents} push $parent
        }

        ## Tree Depth 
        ######################


        ## @return The depth of this node from provided parent, using direct line, meaning, only the primary parents
        :public method getTreeDepth {{baseParent false}} {
            switch -exact -- [${:parents} size] {
                0 {
                    return 0  
                }
                default {
                    
                    #puts "inside tree depth with shade ${:currentShading}"
                    ## Get depth starting from parent order if possible, otherwise fallback from primary
                    if {$baseParent==false} {
                        set baseParent [${:parents} at 0]
                    }
                    #set parent [${:parents} at $parentOrder]
                    
                    set current $baseParent
                    set depth 1
                    while {[[$current getParentsRaw] size]>0} {
                        ::incr depth
                        set current [[$current getParentsRaw]  at 0]
                    } 
                    return $depth
                }
            }
        }

        :public method getPrimaryTreeDepth args {
            return [:getTreeDepth false]
        }

        :public method getPrimaryDepth args {
            return [:getTreeDepth false]
        }

        ## Returns the parents from the primary line, using shading 
        ## @shaded
        :public method getPrimaryParents args {

            ## Create result list 
            set res [odfi::flist::MutableList new]

            ## Go up 
            set current [current object]
            while {![$current isRoot]} {

                ## Take parent 
                set parent [[$current getParentsRaw] at 0]

                ## Check shading before adding to list 
                if {[$parent shadeMatch ${:currentShading}]} {
                    $res addFirst $parent 
                }

                ## Next current is parent 
                set current $parent


            }
            

            return $res  

        }

        ## Find Parent that matches a closure from the primary line
        ## @noshade
        :public method findParentInPrimaryLine cl {

            set result ""
            odfi::closures::withITCLLambda $cl 0 {

                ## Go up 
                set current [current object]
                while {![$current isRoot]} {

                    ## Take parent 
                    set parent [[$current getParentsRaw] at 0]

                    ## Test 
                    set res [$lambda apply [list it $parent]]
                    if {$res} {
                        set result $parent 
                        break
                    }
                

                    ## Next current is parent 
                    set current $parent


                }
            }

            return $result
            

        }

        ## Returns a hierarchy string by running a closure on each parent 
        ## @shade
        :public method formatHierarchyString {closure separator} {

            #set res {}
            #odfi::closures::withITCLLambda $closure 0 {
             #   set res [[:getPrimaryParents] map $closure]

                #return $res
            #}
            set res [[:getPrimaryParents] map $closure]

            #puts "Done MAP hierarchy string $res [$res size] -> [$res mkString $separator]"
            return [$res mkString $separator]
           

            #set parents [:shade odfi::dev::hw::h2dl::Module getPrimaryParents]
            #return [[$parents map { return [$it name get]}] mkString $separator]

        }


        
        ## Children Interface 
        ################################


        ## @return The Children FList with full content or the shade sub-content if a shade criterion is defined at the moment
        :public method children args {
            if {${:currentShading}==""} {
                return [${:children} copy]
            } else {
                set res [odfi::flist::MutableList new]
                ${:children} foreach {
                    #puts "is $it of type $select"
                    #if {[odfi::common::isClass $it ${:currentShading}]}
                    if {[$it shadeMatch ${:currentShading}]} {
                        $res += $it
                    
                    }
                    
                }
                return $res
            }
        }
        
        ## @shade
        :public method indexOfChild child {
            return [[:children] indexOf $child]
            
        }


        ## @shade
        :public method eachChild closure {
            [:children] foreach $closure
            #${:children} foreach $closure -level 1
        }

        ## @shade
        :public method eachChildFrom {start closure} {
            [:children] foreachFrom $start $closure
            #${:children} foreach $closure -level 1
        }

        
        ## @shade
        :public method child index {
           
            return [[:children] at $index]
        }

        ##@:shade 
        :public method lastChild args {
            return [[:children] last] 
        }

        ##@:shade 
        :public method firstChild args {
            return [[:children] first] 
        }

        ## @shade
        :public method childCount args {
            return [[:children] size]
        }

        ## @shade
        :public method isLeaf args {
            if {[:childCount]>0} {
                return false
            } else {
                return true
            }
        }
        
        ## @shade
        :public method isFirstChild args {
            if {[:isRoot]} {
                return true
            } else {
                set p [:noShade parent]
                if {$p!="" && [$p firstChild]==[current object]} {
                    return true
                } else {
                    return false
                }
                
            }
        }
        
        #### Siblings
        
        ## @shade
        :public method getPreviousSibling args {
            if {[:isFirstChild]} {
                return ""
            } else {

                ## Take Children and get previous index 
                ::set __c [[:noShade parent] children]
                #puts "Getting sibling with children count: [${__c} size] , current at: [${__c}  indexOf [current object]]"
                return [${__c} at [expr [${__c}  indexOf [current object]]-1]]
              
            }
        }
        
        ## Add the node as child of this, and adds itself to the possible parents
        :public method addChild nodes  {

            foreach node $nodes {

                if {$node=="" || $node==[current object]} {
                    continue
                }

                ## Return if node is empty 
                #puts "Trying to add $node"
                ## Check node is a flexnode
                if {![odfi::common::isClass $node [namespace current]::FlexNode]} {
                    error "Cannot add node $node to [[curren$at object] info class] if it is not a FlexNode"
                }
                
                ## If already a child, ignore 
                if {![${:children} contains $node]} {

                    $node addParent [current object]

                    ## Double safe in case addParent inserts itself
                    if {![${:children} contains $node]} {

                       # puts "adding $node"
                        ${:children} += $node

                        ## Event point 
                        #puts "Calling event point"
                        :callChildAdded $node
                    }

                }
                
                
        

                
            }


            next
            
            return $nodes
            
        }
        
        ## Add the node as child of this, and adds itself to the possible parents
        :public method add node {

            return [:addChild $node ]
            
        }
        
        ## Remove
        :public method remove child {
            ${:children} -= $child
        }

        ## Remove
        :public method removeChild child {
            ${:children} -= $child
        }
        
        

        ## Clear Parents 
        ## @noshade
        :public method clearChildren args {
            
            ${:children} clear
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
        
        ## @noshade
        :public method indexOf child {
            return [${:children} indexOf $child]
        }
        
        ## Returns a sublist of children from start index to end index
        :public method select {start end} {
            return [[:children] sublist $start $end]
        }
        
        ## Find a child by testing a property
        ## @shade
        :public method findChildByProperty {name value} {
           # try {
                #puts "lookin for property $name $value"
               # return [[:children] find [list expr {[$it $name get] == $value}]
               set opt [[:children] findOption [list expr {[$it $name get] == $value}]]
               $opt match {
                :some res {
                    return $res 
                }
                :none {
                    return ""
                }
               }
            #} on error {res resOptions} {
                #return ""
            #}
         
        }
        
        ## Find a child by testing a closure
        ## @shade
        :public method findFirstChild closure {

          return [[:children] find $closure]
                
                
        }        

        ## Find children by testing a property
        ## @shade
        ## @parameter -match uses string matching instead of equivalence
        :public method findChildrenByProperty {name value {-match false}} {

            ## Prepare Filder Closure
            if {$match} {
                set filterClosure "string match $value \[\$it $name get\]"
            } else {
                set filterClosure [list expr {[$it $name get] == $value}]
            }

            ## Take children and filter 
            set children [:children]
            set result   [$children filter $filterClosure]

            return $result
        
         
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

        ## Breadth First is a level order walk        
        :public method walkBreadthFirst { {-level 0} wclosure} {




            ## Prepare list : Pairs of Parent / node
            ##################
            set componentsFifo [odfi::flist::MutableList new]
            #$componentsFifo += [:children]
            $componentsFifo += [list "false" [current object]]

            #puts "CFifo Size: [$componentsFifo size]"

             ## Create Walk Closure Object 
            ::set walkLambda  [::new odfi::closures::LambdaITCL #auto]
            $walkLambda configure -definition $wclosure
            $walkLambda configure -level $level
            $walkLambda prepare

            ## Visited list 
            ::set visited {}

            ## Common Shade 
            set shade ${:currentShading}

            ## Go on FIFO 
            ##################
            $componentsFifo popAll {
                
                parentAndNode => 

                    #puts "PANODE $parentAndNode"
                    ::set node [lindex $parentAndNode 1]
                    ::set parent [lindex $parentAndNode 0]
                
                    #odfi::log::info "On node2 [$node info class] $visited"
                    #äodfi::log::info "on node $node, parent: $parent ()"
                    ## Evaluation With heuristic
                    #############
                    lappend visited $node
                    
                    #$node inShade {
                        #puts "On Node $node [$node info class] with shade [$node currentShading get]"

                        ## Shade match 
                        ::set continue true 
                        if {[$node shadeMatch $shade]} {
                            set tres [$walkLambda apply [list node $node] [list parent $parent]]
                            #puts "Red after $node -> $tres"
                            if {$tres!="" && [string is boolean $tres]} {
                                ::set continue  $tres
                            }
                        }

                        ## Keep Going
                        #################
               
                        ## Add children of current to back 
                        if {$continue} {
                            ## WARNING: If a child has already been visited, don't add it to avoid cycles
                            set currentDepth [$node noShade getPrimaryTreeDepth]
                            set nodeChildren [$node noShade children]
                            $nodeChildren foreach {
                                #puts "---> adding chuld of depth [$it noShade getPrimaryTreeDepth] from $currentDepth "
                                #if {[$it noShade getPrimaryTreeDepth]>$currentDepth} {
                                #    $componentsFifo += [list $node $it] 
                                #}
                                if {[lsearch -exact $visited $it]==-1} {
                                    $componentsFifo += [list $node $it] 
                                }
                                
                            }
                        }
                        
                    #}
                    #puts "CFifo Size: [$componentsFifo size]"           
            }

            #puts "Done WB"
            #unset walkLambda
            #$walkLambda destroy
             itcl::delete object $walkLambda
        }

        ## PreOrder Walk 
        :public method walkDepthFirstPreorder {{-level 0} wclosure} {


            ## Prepare list : Pairs of Parent / node
            ##################
            set componentsFifo [odfi::flist::MutableList new]
            #$componentsFifo += [:children]
            $componentsFifo += [list "false" [current object]]

            #puts "CFifo Size: [$componentsFifo size]"

             ## Create Walk Closure Object 
            set walkLambda  [::new odfi::closures::LambdaITCL #auto]
            $walkLambda configure -definition $wclosure
            $walkLambda configure -level $level
            $walkLambda prepare

            ## Visited list 
            set visited {}

            ## Common Shade 
            set shade ${:currentShading}

            #odfi::log::info "Starting with shade $shade"

            ## Go on FIFO 
            ##################
            $componentsFifo popAll {
                
                parentAndNode => 

                    #puts "PANODE $parentAndNode"
                    set node [lindex $parentAndNode 1]
                    set parent [lindex $parentAndNode 0]
                
                    #odfi::log::info "On node [$node info class], which has own shading: [$node currentShading get]"
                    
                    ## Evaluation With heuristic
                    #############
                    lappend visited $node
                    
                    #$node inShade {
                        #puts "On Node $node [$node info class] with shade [$node currentShading get]"

                        ## Shade match 
                        ::set continue true 
                        if {[$node shadeMatch $shade]} {
                            set tres [$walkLambda apply [list node $node] [list parent $parent]]
                            if {$tres!="" && [string is boolean $tres]} {
                                ::set continue  $tres
                            }
                        }

                        ## Keep Going
                        #################
               
                        ## Add children of current to back 
                        if {$continue} {
                            ## WARNING: If a child has already been visited, don't add it to avoid cycles
                            set currentDepth [$node getPrimaryTreeDepth]
                            set nodeChildren [$node noShade children]

                            ## AddFirst to proceed by depth first, but reverse children order otherwise is reverses the order
                            foreach c [lreverse [$nodeChildren asTCLList]] {
                           
                                #puts "---> adding chuld of depth [$it noShade getPrimaryTreeDepth] from $currentDepth "
                                #if {[$it noShade getPrimaryTreeDepth]>$currentDepth} {
                                #    $componentsFifo += [list $node $it] 
                                #}
                                if {[lsearch -exact $visited $c]==-1} {
                                    $componentsFifo addFirst [list $node $c] 
                                }
                                
                            }
                        }
                        
                    #}
                    #puts "CFifo Size: [$componentsFifo size]"           
            }

           #unset walkLambda

        }



        

        ## PreOrder Walk 
        :public method walkDepthFirstPostorder {{-level 0} wclosure} {


            ## Prepare list : Pairs of Parent / node
            ##################
            set componentsFifo [odfi::flist::MutableList new]
            #$componentsFifo += [:children]
            $componentsFifo += [list "false" [current object]]

            #puts "CFifo Size: [$componentsFifo size]"

             ## Create Walk Closure Object 
            set walkLambda  [::new odfi::closures::LambdaITCL #auto]
            $walkLambda configure -definition $wclosure
            $walkLambda configure -level $level
            $walkLambda prepare

            ## Visited list 
            set visited {}
            set postProcess {}

            ## Common Shade 
            set shade ${:currentShading}

            #odfi::log::info "Starting with shade $shade"

            ## Go on FIFO 
            ##################
            $componentsFifo popAll {
                
                parentAndNode => 

                    #puts "PANODE $parentAndNode"
                    set node [lindex $parentAndNode 1]
                    set parent [lindex $parentAndNode 0]
                
                    #odfi::log::info "On node [$node info class], which has own shading: [$node currentShading get]"
                    
                    ## Evaluation With heuristic
                    #############
                    
                    ## Mark as visited 
                    lappend visited $node
                    
                    ## Set to continue 
                    ::set continue true 

                    ## If not marked as postprocess, just readd to stack and mark as visited
                    ## Otherwise we can run the closure 
                    ::set postProcessIndex [lsearch -exact $postProcess $node]
                    if {$postProcessIndex==-1} {
                        $componentsFifo addFirst [list $parent $node] 
                        lappend postProcess $node
                    } else {

                        ## Shade match 
                        if {[$node shadeMatch $shade]} {
                            set tres [$walkLambda apply [list node $node] [list parent $parent]]
                            if {$tres!="" && [string is boolean $tres]} {
                                ::set continue  $tres
                            }
                        }
                    }
             
                    

                   

                    ## Keep Going
                    #################
           
                    ## Add children of current to back 
                    ## Never do that if in post process
                    if {$continue && $postProcessIndex==-1} {
                        ## WARNING: If a child has already been visited, don't add it to avoid cycles
                        set currentDepth [$node getPrimaryTreeDepth]
                        set nodeChildren [$node noShade children]

                        ## AddFirst to proceed by depth first, but reverse children order otherwise is reverses the order
                        foreach c [lreverse [$nodeChildren asTCLList]] {
                       
                            #puts "---> adding chuld of depth [$it noShade getPrimaryTreeDepth] from $currentDepth "
                            #if {[$it noShade getPrimaryTreeDepth]>$currentDepth} {
                            #    $componentsFifo += [list $node $it] 
                            #}
                            if {[lsearch -exact $visited $c]==-1} {
                                $componentsFifo addFirst [list $node $c] 
                            }
                            
                        }
                    }
                        
                    
                    #puts "CFifo Size: [$componentsFifo size]"           
            }

           #unset walkLambda

        }
        
        
        
        ## Reducing
        ##########################
        
        ## Reduce goes starts with leaves
        ## - produces a result for each
        ## - Go to upper level, calling the reduce function, with the subtree results
        ## Closure format: (node, results)
        :public method reduceOld {{reduceClosure {}}} {
            
            
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

                                    ## If Reduce Results are not empty -> add 
                                    ::puts "(REDUCE) Results: $reduceRes"
                                    
                                    #set leafResults [concat $leafResults $reduceRes]                                    
                                    
                                    if {[llength $reduceRes]>1} {
                                        concat $leafResults $reduceRes      
                                    } else {
                                        #concat $leafResults $reduceRes      
                                        #lappend leafResults $reduceRes                               
                                    }                                       
                                    
                                     #lappend leafResults $reduceRes
                                     set     nodeResults {}
                                    
                                } else {
                                    
                                    ## If closure provided, use it, otherwise try the reduce Produce
                                    if {[llength $reduceClosure] >0} {
                                        set reduceRes [odfi::closures::applyLambda $reduceClosure [list it [current object]] [list args $leafResults]]                                   
                                    } else {
                                        set reduceRes [[current object] reduceProduce $leafResults]   
                                    }

                                    ::puts "(REDUCE) Results: $reduceRes"
                                    
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
                                         
                                    #::puts "(REDUCE) Results: $reduceRes [llength $reduceRes]"                           
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
                                    #lappend leafResults  [list $reduceRes]                                   
                                }                                  
                                
                                #set reduceRes [[current object] reduceProduce]   
                                #lappend leafResults $reduceRes
                                
                                
                            } elseif {![$node isLeaf]} {
                                
                                ## Bounce back to top, and add children to be done before
                                #::puts "---> Not leaf, Push on top [[current object] info class]"
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
            

            
        }


        ## Reduce goes starts with leaves
        ## - produces a result for each
        ## - Go to upper level, calling the reduce function, with the subtree results
        ## Closure format: (node, results)
        :public method reduce2 { {reduceClosure ""}} {
            
            ## If no reduce closure, then map to reduceProduce function
            if {$reduceClosure==""} {
                set reduceClosure {$it reduceProduce $args}
            }
          

            ## Prepare list : Pairs of Parent / node
            ##################
            set componentsFifo [odfi::flist::MutableList new]
            #$componentsFifo += [:children]
            $componentsFifo push [current object]

            #puts "CFifo Size: [$componentsFifo size]"
            
            set parentStack [odfi::flist::MutableList new]
            set leafResults {}
            set nodeResults {}
            set lastNode [current object]

            ::odfi::log::info "Reduce Start with shade ${:currentShading}"
            set shade ${:currentShading}

            ## Go on FIFO 
            ##################
            $componentsFifo popAll {
                            
                node => 
                    
                    ## Work on the node using the actually defined Shade
                    $node inShade {
                        
                        
                        ## Stack and reduce conditions:
                        ##  -> If not a leaf

                        
                        ## If on top of stack, then operate reduce if in shade
                        ## Otherwise, go deeper in the tree
                        if {[$parentStack peek]==[current object]} {
                            
                            if {[$node shadeMatch $shade]} {

                               

                                ## Consume most up to date results 
                                set tempResults {}
                                if {[llength $leafResults]>0 && [llength $nodeResults]>0} {
                                    set tempResults [concat $leafResults $nodeResults]
                                    set leafResults {}
                                    set nodeResults {}
                                } elseif {[llength $leafResults]>0} {
                                    set tempResults $leafResults
                                    set leafResults {}
                                } elseif {[llength $nodeResults]>0} { 
                                    set tempResults $nodeResults
                                    set nodeResults {}
                                }

                                #::odfi::log::info "Reduced back to Parent [[current object] info class] , with input $tempResults "

                                ## Produce using leaf results 
                                ::set reduceRes [odfi::closures::applyLambda $reduceClosure [list it [current object]] [list args $tempResults]] 
                                set lastNode [current object]

                                #::odfi::log::fine "-> Reduce res: $reduceRes"

                                ## Now we are a node, so add to node results
                                lappend nodeResults $reduceRes 

                                ## Clean, if some leafResults were available, then we can just clean the leaf results 
                                ## Otherwise we just merged some node results, so we are now leaf
                                if {[llength $leafResults]>0} {
                                    #::odfi::log::info "----> Cleaning Leaf Results, our results are in nodeResults: $nodeResults"
                                    #set leafResults {}
                                    #lappend nodeResults $reduceRes 
                                } else {
                                    
                                    #lappend leafResults $nodeResults

                                    #::odfi::log::info "----> Switch node results to leaf results: $leafResults"

                                    #set nodeResults {}
                                }
                                

                      
                                
                            } else {
                                #::odfi::log::info "Reduced back to non active Parent [[current object] info class], just rejoin the leaf results to the nodes results "
                                #lappend nodeResults [join $leafResults]
                                #set leafResults {}
                            }
                            
                            ## Remove from top to make sure we don't enter infinite loop
                            $parentStack pop
                            
                        } else {
                            
                            ## Either Behave as parent, or as leaf
                            #############
                            
                            
                            if {[$node isLeaf] && [$node shadeMatch $shade]} {
                                
                                #::odfi::log::info "On Node [$node info class] which is a leaf [[$node children] size], Reduce"

                                ## Produce result, and add as as result list
                                #::puts "---> Produce Result on leaf [[current object] info class]"
                                
                                ## If closure provided, use it, otherwise try the reduce Produce
                                set reduceRes [odfi::closures::applyLambda $reduceClosure [list it [current object]] [list args ""]] 
                                set lastNode $node

                                ## 
                                #::odfi::log::fine "-> Reduce res $reduceRes"
                                #puts "--------------------------"
                                
                                lappend leafResults  "$reduceRes"

                                #puts "--------------------------"

                                #::odfi::log::fine "-> Reduce temp res  $leafResults"
                                #if {[llength $reduceRes]>1} {
                                 #   lappend leafResults  "$reduceRes"
                                #} else {
                                 #   lappend leafResults  [list $reduceRes]
                                    #lappend leafResults  [list $reduceRes]                                   
                                #}                                  
                                
                                #set reduceRes [[current object] reduceProduce]   
                                #lappend leafResults $reduceRes
                                
                                
                            } elseif {![$node isLeaf]} {
                                
                                #::odfi::log::info "On Node [$node info class] which has children, add as parent and go to children "

                                ## Bounce back to top, and add children to be done before
                                #::puts "---> Not leaf, Push on top [[current object] info class]"
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
            
            #::odfi::log::fine "-> Reduce final res  $leafResults"

            #return [join $leafResults]

            if {[llength $leafResults]>0} {
                return [join $leafResults]
            } else {
                return [join $nodeResults]
            }
            
 
            
        }


        ## Reduce goes starts with leaves
        ## - produces a result for each
        ## - Go to upper level, calling the reduce function, with the subtree results
        ## Closure format: (node, results)
        :public method reduce3 { {reduceClosure ""}} {
            
            ## If no reduce closure, then map to reduceProduce function
            if {$reduceClosure==""} {
                set reduceClosure {$it reduceProduce $args}
            }
          

            ## Prepare list : Pairs of Parent / node
            ##################
            set componentsFifo [odfi::flist::MutableList new]
            #$componentsFifo += [:children]
            $componentsFifo push [current object]

            #puts "CFifo Size: [$componentsFifo size]"
            ## Parents Stack Reducing parents
            set parentStack [odfi::flist::MutableList new]

            ## Results Depth list 
            ## Format: 
            ##   - Each entry stores the results of a specific depth 
            ##   - Each entry is a list of temp results 
            ##   - Entries are cleared when parent is merged
            set resultsList [odfi::flist::MutableList new]
            set currentLevel 0


            set leafResults {}
            set nodeResults {}
            set lastNode [current object]

            ::odfi::log::info "Reduce Start with shade ${:currentShading}"
            set shade ${:currentShading}

            ## Go on FIFO 
            ##################
            $componentsFifo popAll {
                            
                node => 
                    
                    ## Work on the node using the actually defined Shade
                    $node inShade {
                        
                    
                      
                        ## If on top of stack, then operate reduce if in shade
                        ## Otherwise, go deeper in the tree
                        if {[$parentStack peek]==[current object]} {
                            
                            ## WARNING: Level increase is independent from shading
                            ## Decrease level 
                            set currentLevel [expr $currentLevel-1]

                            if {[$node shadeMatch $shade]} {

                                ## Results: Take Content of currentLevel+1 (children)  and clear it
                                set tempResults [$resultsList at [expr $currentLevel+1]]
                                $resultsList setAt [expr $currentLevel+1] {}


                                #::odfi::log::info "Reduced back to Parent [[current object] info class] , with input $tempResults "

                                ## Produce using leaf results 
                                ::set reduceRes [odfi::closures::applyLambda $reduceClosure [list it [current object]] [list args $tempResults]] 
                                set lastNode [current object]

                                #::odfi::log::fine "-> Reduce res: $reduceRes"

                                ## Results: Set to parent's node level, which is the current level 
                                ## Now we are a node, so add to node results
                                $resultsList appendAt $currentLevel $reduceRes

                           
                      
                                
                            } 
                            
                            ## Remove from top to make sure we don't enter infinite loop
                            $parentStack pop

                           
                            
                        } else {
                            
                            ## Either Behave as parent, or as leaf
                            #############
                            
                            
                            if {[$node isLeaf] && [$node shadeMatch $shade]} {
                                
                                #::odfi::log::info "On Node [$node info class] which is a leaf at level $currentLevel"

                                ## Produce result, and add as as result list
                                ##########
                                if {[catch {set reduceRes [odfi::closures::applyLambda $reduceClosure [list it [current object]] [list args ""]]} res]} {
                                    ::odfi::log::info "Reduce error occured on node $node of type [$node info class]"
                                    error $res 
                                }
                                set lastNode $node

                                ## Add Results to current Level results 
                                ##############

                                ## The Results list of this level might not have been opened 
                                ## Open level 
                                if {[$resultsList size]<= $currentLevel} {
                                    $resultsList += [list ]
                                }

                                $resultsList appendAt $currentLevel $reduceRes

                               
                                
                                
                            } elseif {![$node isLeaf]} {
                                
                                ## Parent:
                                ##  - Set children to be processed 
                                ##  - Open Level in results if necessary
                                ##  - increase level 
                                ##  - Add to stack for destacking

                                ## Children 

                                #::odfi::log::info "On Node [$node info class] which has children, add as parent and go to children "

                                ## Bounce back to top, and add children to be done before
                                #::puts "---> Not leaf, Push on top [[current object] info class]"
                                $componentsFifo addFirst [current object]
                                foreach it [lreverse [${:children} asTCLList]] {
                                    $componentsFifo addFirst $it 
                                }

                                ## Open level 
                                if {[$resultsList size]<= $currentLevel} {
                                    $resultsList += [list ]
                                }

                                ## Increase level
                                incr currentLevel
                                
                                ## Add our selves to the stack
                                $parentStack push [current object]
                                
                            }
                            
                            
                            
                        }
                         
                        
                    }       

            }
            
            ## Return Current level 
            return [join [$resultsList at $currentLevel]]
        
            
 
            
        }

        ## Reduce goes starts with leaves
        ## - produces a result for each
        ## - Go to upper level, calling the reduce function, with the subtree results
        ## Closure format: (node, results)
        :public method reduce { {reduceClosure ""}} {
            
            ## If no reduce closure, then map to reduceProduce function
            if {$reduceClosure==""} {
                set reduceClosure {return [$it reduceProduce $args]}
            }

            ## Create reduce Object 
            #set reduceLambda [odfi::closures::Lambda::build $reduceClosure]
            set reduceLambda  [::new odfi::closures::LambdaITCL #auto]
            $reduceLambda configure -definition $reduceClosure
            $reduceLambda prepare

            ## Prepare list : Pairs of Parent / node
            ##################
            set componentsFifo [odfi::flist::MutableList new]
            set componentsFifoList [current object]

            #$componentsFifo += [:children]
            $componentsFifo push [current object]

            #puts "CFifo Size: [$componentsFifo size]"
            ## Parents Stack Reducing parents
            set parentStack [odfi::flist::MutableList new]

            set topNode [current object]

            ## Results Depth list 
            ## Format: 
            ##   - Each entry stores the results of a specific depth 
            ##   - Each entry is a list of temp results 
            ##   - Entries are cleared when parent is merged
            set resultsList [odfi::flist::MutableList new]
            set currentLevel 0


            set leafResults {}
            set nodeResults {}
            set lastNode [current object]

            ::odfi::log::info "Reduce Start with shade ${:currentShading}"
            set shade ${:currentShading}

            ## Go on FIFO 
            ##################
            while {[llength $componentsFifoList]>0} {
            #$componentsFifo popAll
                            
                #node => 
                    
                    set node [lindex $componentsFifoList 0]   
                    set componentsFifoList [lreplace $componentsFifoList 0 0]

                    ## Work on the node using the actually defined Shade
                    
                    #$node currentShading set $shade    
                    
                      
                        ## If on top of stack, then operate reduce if in shade
                        ## Otherwise, go deeper in the tree
                        if {[$parentStack peek]==$node} {
                            
                            ## WARNING: Level increase is independent from shading
                            ## Decrease level 
                            set currentLevel [expr $currentLevel-1]

                            if {[$node shadeMatch $shade]} {


                                #::odfi::log::info "Reduced back to Parent [$node info class] "

                                ## Results: Take Content of currentLevel+1 (children)  and clear it
                                set tempResults [$resultsList at [expr $currentLevel+1] ]
                                if {[$resultsList size]>[expr $currentLevel+1]} {
                                    $resultsList setAt [expr $currentLevel+1] {}
                                }
                                


                                

                                ## Produce using leaf results 
                                #::set reduceRes [odfi::closures::applyLambda $reduceClosure [list it $node] [list args $tempResults] ] 
                                ::set reduceRes [$reduceLambda apply [list it $node] [list args $tempResults]]
                                #::set reduceRes ""
                                #set lastNode [current object]

                                #::odfi::log::fine "-> Reduce res: $reduceRes"

                                ## Results: Set to parent's node level, which is the current level 
                                ## Now we are a node, so add to node results
                                $resultsList appendAt $currentLevel $reduceRes

                           
                      
                                
                            } 
                            
                            ## Remove from top to make sure we don't enter infinite loop
                            $parentStack pop

                           
                            
                        } else {
                            
                            ## Either Behave as parent, or as leaf
                            #############
                            
                            
                            if {[$node isLeaf] && [$node shadeMatch $shade]} {
                                
                               # ::odfi::log::info "On Node [$node info class] which is a leaf at level $currentLevel"

                                ## Produce result, and add as as result list
                                ##########
                                #if {[catch {set reduceRes [odfi::closures::applyLambda $reduceClosure [list it $node] [list args ""]]} res]} {
                                #    ::odfi::log::info "Reduce error occured on node $node of type [$node info class]"
                                #    error $res 
                                #}

                                #::set reduceRes [odfi::closures::applyLambda $reduceClosure [list it $node ] [list args "" ] ]
                                ::set reduceRes [$reduceLambda apply [list it $node ] [list args ""] ]
                                #::set reduceRes ""
                                set lastNode $node

                                #odfi::log::fine "Reduce Res on leaf: $reduceRes"
                                ## Add Results to current Level results 
                                ##############

                                ## The Results list of this level might not have been opened 
                                ## Open level 
                                if {[$resultsList size]<= $currentLevel} {
                                    $resultsList += [list ]
                                }

                                $resultsList appendAt $currentLevel $reduceRes

                               
                                
                                
                            } elseif {![$node isLeaf]} {
                                
                                ## Parent:
                                ##  - Set children to be processed 
                                ##  - Open Level in results if necessary
                                ##  - increase level 
                                ##  - Add to stack for destacking

                                ## Children 

                                #::odfi::log::info "On Node [$node info class] which has children, add as parent and go to children "

                                ## Bounce back to top, and add children to be done before
                                #::puts "---> Not leaf, Push on top [[current object] info class]"
                                
                                #$componentsFifo addFirst $node
                                set componentsFifoList [concat $node $componentsFifoList]

                                set childrenOfCurrent [$node children]

                                #::odfi::log::info "On Node size: [$childrenOfCurrent size] "

                                foreach it [lreverse [$childrenOfCurrent asTCLList]] {
                                    #::odfi::log::info "Adding node $it"
                                    
                                    #$componentsFifo addFirst $it 
                                    set componentsFifoList [concat $it $componentsFifoList]
                                }

                                ## Open level 
                                if {[$resultsList size]<= $currentLevel} {
                                    $resultsList += [list ]
                                }

                                ## Increase level
                                incr currentLevel
                                
                                ## Add our selves to the stack
                                $parentStack push $node
                                
                            }
                            
                            
                            
                        }
                         
                       

            }
            
            ## Return Current level 
            return [join [$resultsList at $currentLevel]]
        
            
 
            
        }

        ## Reduce goes starts with leaves
        ## - produces a result for each
        ## - Go to upper level, calling the reduce function, with the subtree results
        ## Closure format: (node, results)
        :public method reducePlus { {reduceClosure ""}} {
            
            ## If no reduce closure, then map to reduceProduce function
            if {$reduceClosure==""} {
                set reduceClosure {return [$it reduceProduce $args]}
            }

            ## Create reduce Object 
            #set reduceLambda [odfi::closures::Lambda::build $reduceClosure]
            set reduceLambda  [::new odfi::closures::LambdaITCL #auto]
            $reduceLambda configure -definition $reduceClosure
            $reduceLambda prepare

            ## Prepare list : Pairs of Parent / node
            ##################
            set componentsFifo [odfi::flist::MutableList new]
            set componentsFifoList [list [list [:parent] [current object]] ]

            #$componentsFifo += [:children]
            $componentsFifo push [list [:parent] [current object] ]

            #puts "CFifo Size: [$componentsFifo size]"
            ## Parents Stack Reducing parents
            set parentStack [odfi::flist::MutableList new]

            set topNode [current object]

            ## Results Depth list 
            ## Format: 
            ##   - Each entry stores the results of a specific depth 
            ##   - Each entry is a list of temp results 
            ##   - Entries are cleared when parent is merged
            set resultsList [odfi::flist::MutableList new]
            set emptyResults [odfi::flist::MutableList new]
            set currentLevel 0


            set leafResults {}
            set nodeResults {}
            set lastNode [current object]

            ::odfi::log::info "Reduce Start with shade ${:currentShading}"
            set shade ${:currentShading}

            ## Go on FIFO 
            ##################
            while {[llength $componentsFifoList]>0} {
            #$componentsFifo popAll
                            
                #node => 
                    set nodeAndParent [lindex $componentsFifoList 0]  
                    set parent [lindex $nodeAndParent 0]   
                    set node [lindex $nodeAndParent 1]  
                    ::set componentsFifoList [lreplace $componentsFifoList 0 0]

                    ## Work on the node using the actually defined Shade
                    
                    #::odfi::log::info "Node and parent: $nodeAndParent"

                    #$node currentShading set $shade    
                    
                      
                        ## If on top of stack, then operate reduce if in shade
                        ## Otherwise, go deeper in the tree
                        if {[$parentStack peek]==$node} {
                            
                            #::odfi::log::info "On Top: $nodeAndParent, [$node info class]"

                            ## WARNING: Level increase is independent from shading
                            ## Decrease level 
                            set currentLevel [expr $currentLevel-1]

                            if {[$node shadeMatch $shade]} {


                                

                                ## Results: Take Content of currentLevel+1 (children)  and clear it

                                if {[$resultsList size]==[expr $currentLevel+1]} {
                                    $resultsList += [odfi::flist::MutableList new]
                                    set tempResults [$resultsList at [expr $currentLevel+1] ]
                                    #$resultsList setAt [expr $currentLevel+1] [odfi::flist::MutableList new]
                                } else {
                                    set tempResults [$resultsList at [expr $currentLevel+1] ]
                                    $resultsList setAt [expr $currentLevel+1] [odfi::flist::MutableList new]
                                }
                                
                                
                               # ::odfi::log::info "Reduced back to Parent [$node info class] -> $tempResults"
                                ## Produce using leaf results 
                                ::set reduceRes [$reduceLambda apply [list it $node] [list results $tempResults]]
                               

                                ## Results: Set to parent's node level, which is the current level 
                                ## Now we are a node, so add to node results
                                [$resultsList at $currentLevel] +=  [list $node $reduceRes]
                                #$resultsList appendAt $currentLevel [list $node $reduceRes]

                           
                      
                                
                            } 
                            
                            ## Remove from top to make sure we don't enter infinite loop
                            $parentStack pop

                           
                            
                        } else {
                            
                            ## Either Behave as parent, or as leaf
                            #############
                            
                            
                            if {[$node noShade isLeaf] && [$node shadeMatch $shade]} {
                                
                               # ::odfi::log::info "On Node [$node info class] which is a leaf at level $currentLevel"

                                ## Produce result, and add as as result list
                                ##########
                                ::set reduceRes [$reduceLambda apply [list it $node ] [list results $emptyResults] ]

                                set lastNode $node

                                #odfi::log::fine "Reduce Res on leaf: $reduceRes"
                                ## Add Results to current Level results 
                                ##############

                                ## The Results list of this level might not have been opened 
                                ## Open level 
                                if {[$resultsList size]<= $currentLevel} {
                                    $resultsList += [odfi::flist::MutableList new]
                                }

                                [$resultsList at $currentLevel] +=  [list $node $reduceRes]
                                #$resultsList appendAt $currentLevel $reduceRes

                               
                                
                                
                            } elseif {![$node noShade isLeaf]} {
                                
                                ## Parent:
                                ##  - Set children to be processed 
                                ##  - Open Level in results if necessary
                                ##  - increase level 
                                ##  - Add to stack for destacking

                                ## Children 

                                set componentsFifoList [concat [list [list $parent $node]] $componentsFifoList]

                                #::odfi::log::info "Adding children, before readd node and parent: $componentsFifoList"
                                set childrenOfCurrent [$node noShade children]

                                #::odfi::log::info "On Node size: [$childrenOfCurrent size] "

                                foreach it [lreverse [$childrenOfCurrent asTCLList]] {
                                    #::odfi::log::info "Adding node $it"
                                    
                                    #$componentsFifo addFirst $it 
                                    set componentsFifoList [concat [list  [list $node $it]] $componentsFifoList]
                                }

                                ## Open level 
                                if {[$resultsList size]<= $currentLevel} {
                                    $resultsList += [odfi::flist::MutableList new]
                                }

                                ## Increase level
                                incr currentLevel
                                
                                ## Add our selves to the stack
                                $parentStack push $node
                                
                            } else {

                            }
                            
                            
                            
                        }
                         
                       

            }
            
            ## Return Current level 
            return [$resultsList at $currentLevel]
            #return [join [$resultsList at $currentLevel]]
        
            
 
            
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
        :public method mapOld mapType {
                  
            ## Prepare Stacks and list 
            set parentStack [odfi::flist::MutableList new]
            set componentsFifo [odfi::flist::MutableList new]
            $componentsFifo push [current object]

            ## Visited List 

            ## Proceed 
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
            
       
        }

        ## This method is called by other shade methods, to generate a version of this node matching the provided criterion
        ##  - The Method should create some new nodes, and can add them to the tree
        ##  - Subsequent optimisations shall be performed by the API
        :public method mapNode select {
            
            next
            
        }


        ## Performs Tree Mapping 
        ## Mapper can be
        ##  - A Closure, in which case, the closure is used to produced the mapping tree
        ##  - A Type name, in which case, the internal node map function is used to produced trees
        :public method map2 mapFunc {
                  
            ## If map function is a type, adapt to be calling mapNode function 
            if {[::nsf::is class $mapFunc]} {
                set mapFunc "return \[\$node mapNode $mapFunc\]"
            }



            ## Prepare Stack and list
            set parentStack [odfi::flist::MutableList new]
            set componentsFifo [odfi::flist::MutableList new]
            $componentsFifo push [current object]

            ## Visited list 
            set visited {}

            ## Proceed 
            $componentsFifo popAll {
             node => 
                
                ## Visited list 
                lappend visited $node

                ## If node is equal to parent, destack parent!
                ## If node is in the parents, just ignore (algorithm glitch)
                if {[$parentStack peek]==$node} {
                   
                    odfi::log::info "(MAP)---- On node $node [$node info class]  destack"

                    ## If we are back on parent, remove parent from stack
                    if {[$parentStack size]>1} {
                        $parentStack pop
                    }
                    
                    
                    
                } elseif {[$parentStack contains $node]} {
                    
                    #odfi::log::info "(MAP)---- On node $node [$node info class]  destack"
                    #$parentStack remove $node
                    #$componentsFifo

                } else {
                    
                    odfi::log::info "(MAP) On node $node [$node info class] , top of stack ([$parentStack peek])"
                    
                    ## See if node is leaf before mapping, because mapping may keep result node stored as child
                    set isLeaf [$node isLeaf]

                    ## Map Node to new Node 
                    set newNode [odfi::closures::applyLambda $mapFunc [list it $node]]
                    
                    ## Call Mapping
                    ## If node is already the target mapping type, don't map
                    #set mr false
                    #if {[odfi::common::isClass $node $mapType]} {
                    #    set mr $node
                    #} else {
                    #    set mr [$node mapNode $mapType]
                    #}
                    
    
                    ## Stack the result to current parent if there is a result
                    if {[odfi::common::isClass $newNode odfi::flextree::FlexNode]} {
                        
                        #$$newNode!=$node &&

                        ## Add To current parent 

                        if {[$parentStack size]>0} {
                            [$parentStack peek] addChild $newNode
                        }
                        
                        ## If not a leaf, add result node to parent stack
                        if {!$isLeaf} {
                            
                            $parentStack push $newNode
                        }
                    } 
                    
                    
                    ## Continue with the normal children
                    ## After the children are done, add a closure to destack the parent
                    if {!$isLeaf} {
                        
                        ## Check non visited nodes to avoid loops 
                        [$node children] foreach {
                            if {[lsearch -exact $visited $it]==-1} {
                                $componentsFifo addFirst $it
                            }
                        }
                        ## Readd new node to have it destacked
                        $componentsFifo += $newNode
                        
                        #$componentsFifo += [$node children]
                        
                    }
                    
                } 
                   
            }
            
            return [$parentStack peek]
            
       
        }


        ## Performs Tree Mapping 
        ## Mapper can be
        ##  - A Closure, in which case, the closure is used to produced the mapping tree
        ##  - A Type name, in which case, the internal node map function is used to produced trees
        :public method map { {-root ""} mapFunc} {
                  
            ## If map function is a type, adapt to be calling mapNode function 
            if {[::nsf::is class $mapFunc]} {
                ::set mapFunc "return \[\$node mapNode $mapFunc\]"
            }

            ## Create Lambda
            ::set mapLambda  [::new odfi::closures::LambdaITCL #auto]
            $mapLambda configure -definition $mapFunc
            #$mapLambda configure -level 1
            $mapLambda prepare

            ## Prepare Stack and list
            ::set topRes $root
            ::set componentsFifo [odfi::flist::MutableList new]
            $componentsFifo push [list $root [current object]]
            ::set destackList [odfi::flist::MutableList new]

            ## Visited list 
            ::set visited {}

            ## Proceed 
            $componentsFifo popAll {
             nodeAndParent => 
                

                
                ::set parent [lindex $nodeAndParent   0]
                ::set node   [lindex $nodeAndParent   1]
                

                ## Destack closure,if parent is CLOSURE , then the node is a closure 
                if {$parent=="CLOSURE"} {

                    #puts "Running destackClosure $node"
                    eval $node
                    

                } else {

                    ## Visited list 
                    ::lappend visited $node

                   
                    ## See if node is leaf before mapping, because mapping may keep result node stored as child
                    ::set isLeaf [$node isLeaf]

                    ## Map Node to new Node 
                    ::set newNode [$mapLambda apply [list node $node] [list parent $parent]]
                    ::set destackClosure {}

                    ## New node format: NODE or {NODE DESTACKCLOSURE}
                    if {[llength $newNode]>1} {

                        ::extract $newNode 0 1 newNode destackClosure
                    }

                    ::set nextParent $newNode

                    ## Check result is node 
                    ::set resultIsNode [odfi::common::isClass $newNode odfi::flextree::FlexNode]

                    ## If result is not a node, keep actual parent as next parent and ignore it from there
                    if {!$resultIsNode} {
                        ::set nextParent $parent
                    } else {

                        ## Add to current parent or as top if no current parent 
                        ## Don't do anything if the node already has a parent itself
                        if {$topRes=="" && $parent==""} {
                            ::set topRes $newNode
                        } elseif {$topRes!="" && $parent==""} {
                            error "In Map, no actual parent and top result is already set, something weird happened"
                        } elseif {[$node isRoot]} {
                            #puts "(M) adding $newNode to $parent"
                            $parent addChild $newNode
                        }

                    }

                    #puts "Next parent is $nextParent"

                    ## Add Children
                    ## Continue with the normal children
                    ## After the children are done, add a closure to destack the parent
                    if {!$isLeaf} {
                        
                        ## Check non visited nodes to avoid loops 
                        [$node noShade children] foreach {
                            if {[lsearch -exact $visited $it]==-1} {
                                $componentsFifo += [list $nextParent $it]
                            }
                        }

                        ## Add destack closure if necessary 
                        if {[llength $destackClosure]>0} {
                            #$componentsFifo += [list CLOSURE [list $newNode apply $destackClosure]]
                            $destackList addFirst [list $newNode [odfi::richstream::embeddedTclFromStringToString $destackClosure]]
                        }
                        ## Readd new node to have it destacked
                        #$componentsFifo += $newNode
                        
                        #$componentsFifo += [$node children]
                        
                    }


                }

                
                
                    
                    
                 
                   
            }

            ## Do destacking 
            $destackList popAll {

                [lindex $it 0] apply [lindex $it 1]
                #eval $it
            }
            
            return $topRes
            
       
        }
        
        

        ## Search/Find 
        #########################

        ## @noshade
        :public method findFirstInTree closure {

            set found false
            set res "" 
            set matchClosure [odfi::closures::newITCLLambda $closure]
            :walkBreadthFirst {
                if {!$found} {
                    set found [$matchClosure apply [list it $node]]
                    set res $node
                }
                return [expr ! $found]
            }

            ::odfi::common::deleteObject $matchClosure

            return $res
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

            ## Check shading, it must be a closure 
            ## If it is a type, adapt the closure 
            if {[::nsf::is class $select]} {
                set select "odfi::common::isClass \$it $select"
                #puts "Changed shading to $select"
            }

            ## Set shading 
            #set :currentShading $select 
            set :currentShading  [odfi::closures::buildITCLLambda $select]

            ## Propagate and make sure shading is resetted 
            try {
                #puts "Calling method $method with [lindex $args  0] // $args  "
                #:$method [lindex $args  0]
                eval ":$method $args"
            } finally {
                odfi::closures::redeemITCLLambda ${:currentShading}
                set :currentShading ""
            }
        }   

        ## Run a closure with no shading activated. Shading is restored if was set before 
        :public method noShade {method args} {

            set savedShading ${:currentShading}
            set :currentShading ""
            ## Propagate and make sure shading is resetted 
            try {
                :$method [lindex $args  0]
            } finally {
                set :currentShading $savedShading
            }
        }

        ## Checks whether the current node matches the shade 
        ## Checks against provided shade in args if so 
        :public method shadeMatch {{provided ""}} {

            set returnRes true
            if {$provided!="" && ![odfi::common::isClass $provided odfi::closures::LambdaITCL ]} {
                puts "Runing on $provided"
                odfi::closures::withITCLLambda $provided 0 {
                    set returnRes [$lambda apply [list it [current object] ] ]
                }
               
               # return [odfi::closures::applyLambda $provided [list it [current object]] ]
            
            } elseif {$provided!=""} {

                set returnRes [$provided apply [list it [current object] ] ]

            } elseif {${:currentShading}==""} {

                return true 

            } else {
                #::puts "Shade Match testing [[current object] info class] against ${:currentShading}"
                #return [odfi::common::isClass [current object] ${:currentShading}]
                
                #return [odfi::closures::applyLambda ${:currentShading} [list it [current object]] ]
                
                #odfi::closures::withITCLLambda ${:currentShading} 0 {
                #    set returnRes [$lambda apply [list it [current object]]]
                #}
                set returnRes [${:currentShading} apply [list it [current object] ] ]
                
            } 

            #puts "Shade match [current object] with $args"
            return $returnRes
        }



        ## Runs closure on current node, previously copying parent shading 
        :public method inShade closure {

            set importedShade false

            ## Import Shade, only if none is defined 
            #############
            ## Check tehre is a parent 
            if {${:currentShading}=="" && [${:parents} size]>0} {

               ## Copy shading 
               set current [current object]
                while {true} {
                    if {[$current isRoot]} {
                        set :currentShading [$current currentShading get]
                        set importedShade true
                        break
                    } elseif {[$current currentShading get]!=""} {
                        set :currentShading [$current currentShading get]
                        set importedShade true
                        break
                    } else {
                        set current [$current parent]
                    }
                }
                
            }


            ## Run
            #odfi::closures::run $closure
            try {
                :apply %closure
            } finally {
                ## Remove imported shading to avoid it staying on!
                if {$importedShade} {
                    set :currentShading ""
                }
                
            }
            
        }



    }


    ## Utilities 
    #################
    proc ::reduceJoin {input {separator " "}} {

      

        if {[llength $input]==1} {
            set input [lindex $input 0]
        }
        if {[llength $input]==1} {
            set input [lindex $input 0]
        }
        return [join $input $separator]
    }

    proc ::reduceJoin1 {input {separator " "}} {

      

        if {[llength $input]==1} {
            set input [lindex $input 0]
        }
       
        return [join $input $separator]
    }

    proc ::reduceJoin0 {input {separator " "}} {

      

        return [join $input $separator]
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
