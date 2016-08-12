set location [file dirname [info script]]

source $location/tcl_error.tcl

package require odfi::language::nx 1.0.0
package require odfi::errortrace
#source E:/Common/Projects/git/odfi-manager-3/private/odfi.tm




puts "----- START -------"

namespace eval test {
    
    
    ::odfi::language::nx::new [namespace current] {
        #puts "In NS: [uplevel  6 ::odfi::common::findFileLocation]"
        
        :A name {
        
            +exportToPublic
            
            +builder {
                
                ## var d doest not exist
                puts "Creating A $d"
            }
            
            
            
            
            :B name {
                
                +method test args {
                    puts "Error in B.test"
                    error "ERROR"
                }
            }
        }
    }
}


try {
 
 set a [::test::a test]
 
   
} on error {res option} {
    
        puts "On Error catch"
        ## Resolve file and line
        ## Start at -2
        ## Look for frame level with file
        ## If we find eval, add line to current line in file
        set currentLineInFile 1
        set foundFile ""
        set maxlevel [info frame]
        set level 1
        while {$level<[expr $maxlevel]} {
            
            set callerFrame [info frame -$level]

            ## If file -> finish
            ## If eval -> add line
            if {[dict get $callerFrame type]=="eval"} {

                incr currentLineInFile [expr [dict get $callerFrame line] -1]
              
            } elseif {[dict get $callerFrame type]=="source"} {
                set foundFile  [dict get $callerFrame file]
                incr currentLineInFile [expr [dict get $callerFrame line] -1]
                break
            }
            
            incr level

        }
        
        puts "Found F: $foundFile -> $currentLineInFile "
        
        #puts "$res"
        
        set output_list [odfi::errortrace::errorToList $res $option]
        odfi::errortrace::printErrorList $output_list
          
}

exit 0

set odfi [::odfi::odfi main {

    
    :config test {
    
    
    
    
    
    
    
       :module adl {
       
       
           :command hello {
           
               puts "Hello"
           
           }
       }
    
    }

}]

$odfi runCommand adl/hello