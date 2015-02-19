#!/usr/bin/env tclsh8.6

package require odfi::closures 3.0.0
package require odfi::tests 1.0.0


## Simple Name
######################
set closure {
    i => 
        puts "Variable i is $i"
        odfi::tests::expect "i" 1 $i
}

odfi::closures::applyLambda $closure 1

## NX Like Name Outscoped
###############################
set :i 2
set closure {
        puts "Variable :i is ${:i}"
        odfi::tests::expect "i" 2 ${:i}
}

odfi::closures::applyLambda $closure 
