#!/usr/bin/env tclsh8.6

package require odfi::closures 3.0.0

proc assert {expected value {message ""}} {

    set success "\[SUCCESS\] "
    if {$expected!=$value} {
    set success "\[FAILED\]  "
    }
    puts "$success Expected $expected <-> $value "

}

proc msg arg {
    puts "==== $arg ===="
}

##############################################

msg "Return value"
set res [odfi::closures::run {

  return 2
}]

assert 2 $res

msg "Break using simple for"
set res [odfi::closures::run {
    set a 0
    for {set x 0} {$x < 10} {incr x} {
        set a $x
        if {$x==4} {
            break
        }
    }
    return $a
}]
assert 4 $res
puts "break: $res"



msg "Break using repeat"
set res [odfi::closures::run {
    set a 0

    puts "Closure running in [namespace current]"
    ::repeat 10 {
 
        puts "Iteration : $i , a is $a, proc: [dict get [info frame 0] proc], ns: [namespace current]"
        set a $i
        if {$i==5} {
            break
            #return
        }
    }
    return $a
}]

puts "break: $res"
assert 5 $res


msg "Test Imbricated loops"
set a 0
set b 0
set res [odfi::closures::run {
    ::repeat 10 {
 
        #puts "(A) Started a $i"

        ::repeat 10 {
            
            #puts "  (B) b is $i"

            if {$i==2} {

               set b $i
                
               break
            #    #return
            }

        }
        #puts "(A) a is $i"

        #puts "Iteration : $i , a is $a, b is $b"
        set a $i
        if {$i==5} {
            break
            #return
        }

    }
    return $a
}]
assert 5 $a "A must be 5"
assert 2 $b "A must be 5"
#puts "EOF test: $a and $b"
