#!/usr/bin/env tclsh8.6

package require odfi::flist 1.0.0
package require odfi::tests 1.0.0


set list [odfi::flist::MutableList new]
$list += "a"
$list += "b"
$list += "c"
$list += "d" "e" f

## List has 6 elements
#################
odfi::tests::expect "Listh as 6 Elements" 6 [$list size]


## Try Find with conflicting naming
################
set name "Foo"

proc searchName name {
    upvar list list

    $list find {

        puts "Testing $it agains $name"
        if {$name != $it} {
            return false
        } else {
            return true
        }

    }
    return
    
    ::foreach it [$list content] {

        odfi::closures::applyLambda {

            puts "Testing $it agains $name"
            if {$name != $it} {
                return false
            } else {
                return true
            }

        } [list it "$it"]
               
    }
    return


}

searchName "e"
