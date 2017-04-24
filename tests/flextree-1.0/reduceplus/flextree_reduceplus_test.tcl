package require odfi::flextree 1.0.0
package require odfi::language::nx 

namespace eval ::testns {

    ::odfi::language::nx::new ::testns {
    
        :top {
            +exportToPublic
            
            :a {
                
                :a_a {
                
                }
                
                :a_b {
                
                }
            }
            
            :b {
            
                :c {
                
                    :d {
                    
                    }
                    
                }
            }
        
        }
    }
}

set v [::testns::top {
    
    :a {
        
    }
    
    set laterC ""
    :b {
        :c {
            set laterC [current object]
            :d {
            
            }
            :d {
                        
            }
        }
        
        :c {
        
        }
    }
    
    :b {
    
        :addChild $laterC
    }

}]

set res [$v reducePlus {

    return "([$node info class])"
}]

puts [$res at 0]