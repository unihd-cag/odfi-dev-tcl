package require Thread 
package require odfi::closures 3.0.0
package require odfi::tests 1.0.0
package require nx 2.0.0

nx::Class create A {


}
A create a 

set test_var 0
proc do_incr args {
    odfi::closures::applyLambda {
        #set test_var 0
        puts "inside do incr lambda: [info frame] $test_var ([thread::id])"
        #incr test_var    
    }    
    
}


set th1 [thread::create -joinable {
    
    package require odfi::closures 3.0.0    
    puts "in TH1: [thread::id]"
    #puts "Val: [odfi::closures::value test_var]"
    
    puts "Interpreter: "
    
     odfi::closures::applyLambda {
         #puts "inside do incr lambda: [info frame] $test_var ([thread::id])"     
     
     }
}]

set th2 [thread::create -joinable {
    
    package require odfi::closures 3.0.0    
    puts "in TH2: [thread::id]"
    
    A create a2
         
}]

puts "Slaves: [interp slaves]"
thread::join $th1
thread::join $th2

exit 0
#
#
#
#
#
#
#set closure {
#
# puts "inside closure"
# incr test_var
#    do_incr 
#}
#
#set th1 [thread::create -joinable [list package require odfi::closures 3.0.0 ;do_incr]]
#set th2 [thread::create -joinable [list package require odfi::closures 3.0.0 ;do_incr]]
#
#
#puts "Waiting done"
#thread::join $th1
#thread::join $th2
#
#puts "done-> $test_var"
#odfi::tests::expect "Var must be incremented" 2 $test_var