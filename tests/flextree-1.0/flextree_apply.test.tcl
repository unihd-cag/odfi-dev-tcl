package require odfi::flextree 1.0.0



nx::Class create A -superclass odfi::flextree::FlexNode {

    :property {c 2}

}


A create a 

set closure {

    puts "Hello 2 ${:c}"
    :apply {
        puts "Hello 2 ${:c}"    
    }
}

a apply {

    puts "Hello"
    
    :apply  $closure
}
