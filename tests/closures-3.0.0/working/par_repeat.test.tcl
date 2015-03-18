

package require Thread 
package require odfi::closures 3.0.0
package require odfi::tests 1.0.0




::repeatpar 20 {

    puts "In Loop $i [thread::id]"
    if {[expr $i%2]==0} {
        for {set vv 0} {$vv < 20000} {incr vv} {
            
        }
    }
    

}
