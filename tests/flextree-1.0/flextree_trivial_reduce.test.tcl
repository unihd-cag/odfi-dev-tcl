
package require odfi::flextree 1.0.0

nx::Class create A -superclass odfi::flextree::FlexNode {
}

A create a 
A create b 
A create c


a addChild b
a addChild c


## Reduce

set reduceRes [a reduce {
   return "H$args"
}]

puts "Reduce res: $reduceRes"

