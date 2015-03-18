package require odfi::flextree


## Create a few classes for testing purpose
###########
nx::Class create A -superclass odfi::flextree::FlexNode {

}

nx::Class create A_A -superclass A -mixin odfi::flextree::FlexNode {
    
}
nx::Class create A_B -superclass A -mixin odfi::flextree::FlexNode {
    
}



nx::Class create BMix  {
    
}

nx::Class create B -superclass odfi::flextree::FlexNode -mixin BMix {
    
}

nx::Class create B_A -superclass B -mixin odfi::flextree::FlexNode {
    
}

nx::Class create B_B -superclass B -mixin odfi::flextree::FlexNode {
    
}

## Type check test 
########################
set a1 [A new]
set a2 [A new]

set a_a1 [A_A new]
set a_b1 [A_B new]

set b1 [B new]

puts "Eq: [$a_a1 info has type [$a1 info class]]"

puts "Eq: [$a_a1 info has type odfi::flextree::FlexNode]"

puts "Eq: [$b1 info has mixin BMix]"

## Shade
###############
set top [odfi::flextree::FlexNode new]

$top addChild $a1 
$top addChild $b1 

## Print Children
###############
$top eachChild {
    puts "Child: $it"
}

## Create a Shade and list A children
############
$top shade A eachChild {
    puts "Child: $it"
}

## Return shaded content list 
################
set aContent [$top shade A children]
puts "Number of A children: [llength $aContent]"
