package require odfi::closures 3.0.0
package require odfi::tests 1.0.0



## Create Proc which calls itself recursively
namespace eval test::a::b {

    proc start_point stop {
        
        odfi::closures::applyLambda { 
            
            test_rec false
            
        }    
        
    }
    
    proc test_rec stop {
        
        puts "-- In test rec [info frame]"
        set localvar 0  
        set localvar 0          
        set validpoint true      
        odfi::closures::applyLambda {    
            
            
           puts "---- current value before updating $localvar"
            
            lappend listContent a 
            
            #puts "-- Update local var in frame [info frame] : $localvar"  
            #set localvar 0
                            
            if {!$stop} {
            
                set localvar [expr $localvar+1]                
                test_rec true        
                
                set localvar [expr $localvar+1]                
                puts "-- After rec call $localvar"
               
                odfi::tests::expect "After rec call and two increments" 2 $localvar               
                                                   
            } else {
                odfi::tests::expect "If stop, local var mus be 0" 0 $localvar                
            }
            
        }
        
    }    


}

set listContent {}
set validpoint false 

test::a::b::start_point false

puts "After all $listContent -> $validpoint"

odfi::tests::expect "Global list updated from closures" "a a" [join $listContent]               
odfi::tests::expect "Global variable updated from closures" true $validpoint                      


