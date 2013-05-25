#!/usr/bin/env tclsh


package require odfi::list 2.0.0


proc closureEvaluator closure {

    set evaluator "Yo mama"

    odfi::closures::doClosure $closure

}


set topLevelVariable "TopLEvel"
set modifyVariable "ToBeModified"
for {set i 0} {$i<1} {incr i} {


    closureEvaluator  {

        #upvar 1 i i
        set localVar "tt"
        puts "Hello $i"
        puts "Hello with special ${i}*"
        puts "Hello $i -> $localVar on evaluator $evaluator "

        puts "Toplevel variable resolved using upvar. $topLevelVariable"

        set modifyVariable "$modifyVariable Was Modified"
        puts "Modified Variable: $modifyVariable"

    }

}


set lst [lrepeat 5 "Hi"]
set pattern "hhhh"
odfi::list::each $lst {


    puts "Test using pattern $pattern on $it and ${it}"

}


set i 0
odfi::list::each $lst {

    set newvar [string length _${i}_]
    puts "Test using pattern $pattern on ${it} and i is: $newvar"

}

::repeat 15 {

    odfi::closures::doClosure {

        set newvar text_${i}_I
        puts "IN repeat with: $newvar"

    }

}
