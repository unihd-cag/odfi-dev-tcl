package require odfi::closures 3.0.0
package require odfi::tests 1.0.0
package require nx 2.0.0


nx::Class create Test {
    
    :property {a 20}
    
    :public method apply cl {
        odfi::closures::run $cl
    }

}



Test create t 


t apply {

    puts "A is ${:a}"

}   