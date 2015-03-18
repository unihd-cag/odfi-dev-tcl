package require odfi::closures 3.0.0
package require odfi::tests 1.0.0
package require nx 2.0.0

## Create Classes
#######################




nx::Class create A {
    
    :property {c 3}
    :property -accessor public {fingers 1}
        
    :public method apply closure {
        odfi::closures::run %closure
    }
    
}

nx::Class create B {
    
    :property {b 2}
    
    :public method apply closure {
        odfi::closures::run %closure
    }
    
}

## Test
###################

A create a 

a apply {

    
    set b [B new]
    $b apply {
    
        puts "inside B, readin prop :c ${:c} :b is ${:b}"
    }
    
}

