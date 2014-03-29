#!/usr/bin/env tclsh

package require odfi::closures 2.0.0


proc assert {expected value {message ""}} {

    set success "\[SUCCESS\] "
    if {$expected!=$value} {
    set success "\[FAILED\]  "
    }
    puts "$success Expected $expected <-> $value "

}

#########################################
## Regexp test 
#############################################
set closureString "

    incr i
    incr j
"
set vars [regexp -all -inline {(?:\$[a-zA-Z0-9:\{_]+\}?)|(?:incr [a-zA-Z0-9:_]+)} $closureString]

foreach var $vars {

    set var [string trim $var]
    
    ## Clean var name 
    if {[string match "incr*" $var]} {
        puts "Replacing"
        set var [regsub -all {.*incr\s+(.+)} $var "\\1"]
    } else {
        set var [string trim [string range $var 1 end]]
        set var [regsub -all {\{|\}} $var ""] 
    }

    puts "Found var: $var"

}

set i 0
odfi::closures::doClosure {

    incr i
    ::assert 1 $i

    set j 0
    odfi::closures::doClosure {

        incr i
        incr j
    }
    ::assert 2 $i
    ::assert 1 $j

    odfi::closures::doClosure {

        incr i
        incr j
    }
    ::assert 3 $i
    ::assert 2 $j

    foreach v {a b c} {

        incr j

        odfi::closures::doClosure {

            incr j
        }

    }

    ::assert 8 $j

}




#################################
## Simple Variable Hierarchy
#################################

puts "Simple Hierarchy Test........"

set var "hello"
odfi::closures::doClosure {

    set localVar "hi"
    ::assert hi $localVar

    ::assert hello $var

    set var "modified"
}

assert modified $var

##################################
## Double Hierarchy
##################################

puts "Double Hierarchy Test........"

set var "hello"
odfi::closures::doClosure {

    set localVar "hi"
    ::assert hi $localVar

    ::assert hello $var

    set var "modified"

    odfi::closures::doClosure {

        set localVar2 "hi"
        ::assert hi $localVar2

        set var "modified"
        set localVar "modified"

    }

    assert modified $localVar

}
assert modified $var

##################################
## Iterator
##################################
puts "Iterator Test........"

set l1 {a b c}
odfi::closures::doClosure {

    set i 0
    foreach it $l1 {


        odfi::closures::doClosure {

           # puts "List item: $it // $i"

            ::assert [lindex $l1 $i] $it

            
        }
        incr i

    }

}

##################################
## list
##################################
## \brief Evaluates script for each element of lst, providing $it variable as pointer to element, and $i as index
# Script is called in one uplevel + the caller whish
proc each {lst script args} {

    ## -level option
    ###########
    set execlevel 1
    if {[lsearch -exact $args -level]} {
        set execlevel [lindex $args [expr [lsearch -exact $args -level]+1]]
    }

    ## Exec level +1 to cover the current execution level
    set execlevel [expr $execlevel+1]

    ####

    foreach it $lst {

        #uplevel $execlevel set it $it
        odfi::closures::doClosure $script $execlevel
    }



}

puts "Imbricated each without level change..."
set i 0 
set l1 {x y z}
::each $l1 {


    ::assert [lindex $l1 $i] $it
    

    set j 0 
    
    set l2 {d e f}

    ::each $l2 {


        ::assert [lindex $l2 $j] $it
        incr j
    }

    ::assert [lindex $l1 $i] $it
    incr i

}

 
