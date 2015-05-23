package require odfi::flextree

## Fast type
##########################
set tstack [odfi::flist::MutableList new]
cproc type {name closure} {
    
    ## Superclass 
    if {[$::tstack size]>0} {
        set _superclass [$::tstack peek]
    } else {
        set _superclass odfi::flextree::FlexNode
    }

    #::puts "Superclass type $_superclass"
    $::tstack push $name

    nx::Class create $name  -superclass $_superclass {
        eval $closure
    }
    $::tstack pop
    
}

cproc mixin {target name closure} {
    
    nx::Class create ::$name {
        
        eval $closure
   }
    $target mixins add ::$name   
}


## Definitions
###########################
type A {
    
    
    
}
type B {
    
}

type C {
    
}



## Tree
################
package require odfi::flist
set stack [odfi::flist::MutableList new]

cproc root {type closure} {
    
    set p [$type new]
    $::stack push $p
    $p apply $closure
    
}

cproc node {type closure} {
    
   
    ## Create
    set p [$type new]

    ## Add to current parent
    puts "Add child $p to [$::stack peek] of type $type"
    [$::stack peek] addChild $p
    ## Now new parent
    ## Run
    ## Remove
    $::stack push $p
    $p apply $closure
    $::stack pop
    
    #::puts "Current P is $currentP"
    #$currentP addChild $p
    
}

puts "--------- Start creating"

root A {
    
    node B {
     
        node C {
            
        }
    }
    
    node B {
        
        node C {
                    
        }
        
    }
    
}



set root [lindex [A info instances] 0]

#$root object mixins add odfi::flextree::utils::StdoutPrinter
#$root printAll

::puts "root is: [$root info class] size [$root childCount]"
$root eachChild {
    ::puts "Child: [$it info class]"
}

flush stdout
exit 0


## Setup mapping types
###########################
type BIS {
    
    type ABis {
        
        mixin A AMapper {
            



            :public method mapNode select {

                odfi::log::info "Mapping A to $select"

                :addChild [::ABis new]

                next
            }
            
        }
        
    }
    
    type BBis {
        

        mixin B BMapper {
            



            :public method mapNode select {

                odfi::log::info "Mapping B to $select"

                :addChild [::BBis new]

                next
            }
            
        }


    }
    
    type CBis {
        
        mixin C CMapper {
            



            :public method mapNode select {

                odfi::log::info "Mapping C to $select"

                :addChild [::CBis new]

                next
            }
            
        }

    }
    
}


## Try to do mapping
####################



set bisRoot [$root map BIS]

## Display
$root walkDepthFirstPreorder {

    set tab "----[lrepeat [$node getPrimaryDepth] ----]"

    ::puts "$tab[$node info class]"

}


## Shade Print
########################
puts "--- Shade walk"
$root shade BIS walkDepthFirstPreorder {


    set tab "----[lrepeat [$node getPrimaryDepth] ----]"

    ::puts "$tab[$node info class]"


}

