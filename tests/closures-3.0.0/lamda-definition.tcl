#!/usr/bin/env tclsh8.6

package require odfi::closures 3.0.0
package require odfi::tests 1.0.0


## Simple Lambda with variable bound 
########################
set closure {
    i => 
        puts "Variable i is $i"
        odfi::tests::expect "i" 1 $i
}

odfi::closures::applyLambda $closure 1


## Simple Lambda with automatic implicit argument
########################
set closure {

    puts "Input argument is $arg0"
    odfi::tests::expect "autmatic input argument" 1 $arg0
}
odfi::closures::applyLambda $closure 1

## Simple Lambda with automatic named implicit argument
########################
set closure {

    puts "Input argument is $j"
    odfi::tests::expect "autmatic named input argument" 1 $j
}
odfi::closures::applyLambda $closure {j 1}

## Simple Lambda with name protection
########################
set i 10

set closure {
    i => 
        puts "Variable i is $i"
        odfi::tests::expect "Input argument i should be local and not conflict with toplevel defined i" 1 $i

        set i 25
        odfi::tests::expect "Local variable i update is working ($i)" 25 $i


}


odfi::closures::applyLambda $closure 1

odfi::tests::expect "Top level i must no have beem overwritten by closure ($i)" 10 $i


## Test Against  imbricated repeat 
##################################
set topV Hello
::repeat 2 {

     i => 

     #puts "in Top repeat $j"

     ::repeat 2 {
        j -> 
        puts "in sub repeat $i -> $j $topV"
    }

    puts "in Top repeat $i : $topV"

}
exit 0
::repeat2 2 {
    i => 
   
    ::repeat2 2 {
        puts "in sub repeat $i"
    }
     puts "in Top repeat $i"

}
