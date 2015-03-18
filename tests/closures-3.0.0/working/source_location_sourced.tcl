package require nx 2.0.0


puts "inside sourced file"

puts "--> At line [odfi::closures::getCurrentLine]"
puts "--> At line [odfi::closures::getCurrentLine]"


## Try with an object 
nx::Class create Test {

    :variable -accessor public line -1

    :public method init {} {
        set :line [odfi::closures::getCurrentLine]
    }

}

Test create t 

puts "-> Test created at line [t line get]"
