
namespace eval odfi::errortrace {

    variable all_functions {}
    variable output_list {}

    proc tracer args {

        set callerFrame [info frame -2]
        set currentFrame [list  [dict get $callerFrame type] [dict get $callerFrame line] [dict get $callerFrame file]]
        set current_namespace [uplevel namespace current]
    
        if {$current_namespace == "::"} {
            set current_namespace ""
        }
                  
        lappend ::odfi::errortrace::all_functions [list ${current_namespace}::[lindex [lindex $args 0] 1] [dict get $callerFrame file] [dict get $callerFrame line]]
    }

    trace add execution "::proc" enter "::odfi::errortrace::tracer" 
  
}
# end of namespace odfi::errortrace

    namespace eval test {

        proc testf args {
            b
        }
    }


    namespace eval test2 {

        proc testf args {
            ::b
        }
    
        namespace eval subns {
    
            proc testfsubns args {
                ::b
            }
        }
    }
  
    
    
    proc a args {
        b
    
    }
    
    proc c args {
        b
    }

    proc b args {
        #c
        source tcl_error_sourced_2.tcl

    }
    
    
    try {
        
        test2::testf
        #a
        #c
        #::test::testf
        
    } on error {res option} {
    
        set stack [dict get $option -errorinfo]
        #puts $stack
        
        # save the first line of the error stack     
        #set first_error_stack_line [regexp {(.*\n\s)} $stack]       
        set index_tmp [string first "\n" $stack]
        set first_error_stack_line [string range $stack 0 $index_tmp]
        #puts "first error stack line: $first_error_stack_line"      
        
        set mres [regexp -all -inline {\((procedure)\s+"([\w\d:\._-]+)"\s+line\s+(\d+)\)} $stack ]
    
        #puts [lreverse $mres]
        #puts $::odfi::errortrace::all_functions

        foreach {line name type match} [lreverse $mres] {
                                  
            ## Name must be Fully Qualified (starts with :: )
            if {![string match "::*" $name]} {
                set name "::$name"
            }
           
            # search the index within the result mres from the regexp expression
            # Get Function location from error namespace if found
            set search_index_name [lsearch -index 0 -exact $::odfi::errortrace::all_functions $name]
            if {$search_index_name == -1 } {
                puts "Cannot find  $name in global traced functions"
                continue
            }
            set search_result [lindex $::odfi::errortrace::all_functions $search_index_name]
            
            # due to the search_index, create the output list         
            # type, i.e. "procedure"
            if {$type == ""} {
                puts "Cannot find $type in global traced functions"
                continue
            }
            lappend ::odfi::errortrace::output_list $type
            
            # Fully Qualified Name (::ns::name)
            if {[lindex $search_result  0] == ""} {
                puts "Cannot find fully qualified name (::ns::name) in global traced function"
                continue
            }
            lappend ::odfi::errortrace::output_list [lindex $search_result 0] 
                          
            # file name
            if {[lindex $search_result 1] == ""} {
                puts "Cannot find file name in global traced function"
                continue
            }
            lappend ::odfi::errortrace::output_list [lindex $search_result 1]
            
            #compute the correct line number       
            if {[lindex $search_result 2] ==  ""} {
                puts "Cannot find line number in global traced function"
                puts "Cannot compute the correct line number"
                continue
            }
            set line_number [expr $line+[lindex $search_result 2]-1]
            lappend ::odfi::errortrace::output_list $line_number         
        }
       
        # Output of output_list
        # the first line of the error stack will be always printed
        puts $first_error_stack_line
        set i 0
        foreach {type name file line_number} $::odfi::errortrace::output_list {

            puts stderr "[lrepeat $i ---] on $type $name , in (file \"$file\" line $line_number)" 
            incr i
            #error "rrr"
        }          
    }

