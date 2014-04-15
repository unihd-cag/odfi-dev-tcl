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
