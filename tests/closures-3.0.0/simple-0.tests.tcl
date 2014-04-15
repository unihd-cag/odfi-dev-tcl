#!/usr/bin/env tclsh8.6

package require odfi::closures 3.0.0


puts "******* Simple Test: ***********"
set var 0 
set var2 2
odfi::closures::close {

    incr var
    puts "Resolved Var: $var"
    set var 2

}

odfi::closures::close {

    puts "Resolved Var: $var"
    incr var

}

puts "Updated var: $var"

puts "******* Error Formatting test **********"




odfi::closures::close {

    odfi::closures::close {

        puts "Resolved Var: $var_no2"      

    }

    puts "Resolved Var: $var_no"      

}

