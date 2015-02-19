#!/usr/bin/env tclsh8.6

package require odfi::closures 3.0.0
package require odfi::tests 1.0.0

set name "Foo"

proc testProc name {

    foreach test {"a" "b"} {
        odfi::closures::applyLambda {

            puts "Name is $name , it is $it"

        }  [list it $test]
    }

    #testProc "BarRec"

}

testProc "Bar"
testProc "Buzz"

