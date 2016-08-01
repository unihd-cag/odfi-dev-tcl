#source tcl_error_sourced.tcl

set location [file normalize [file dirname [info script]]]


namespace eval odfi::errortrace {

    variable all_functions {}
    
    proc tracer args {
        puts "In tracer at level [info frame]"
        #puts "Tracer args: $args"
        puts "Tracer for command: [lindex [lindex $args 0] 1]"
        set callerFrame [info frame -2]
        puts "Current frame: [dict get $callerFrame type] [dict get $callerFrame line] [dict get $callerFrame file]"
        set currentFrame [list  [dict get $callerFrame type] [dict get $callerFrame line] [dict get $callerFrame file]]
        puts $currentFrame
        puts "Namespace: [uplevel namespace current]"
        set current_namespace [uplevel namespace current]
        if {$current_namespace=="::"} {
            set current_namespace ""
        }
        
        lappend ::odfi::errortrace::all_functions [list  ${current_namespace}::[lindex [lindex $args 0] 1] [dict get $callerFrame file] [dict get $callerFrame line]]
        
        #lappend all_functions $currentFrame
        #lappend all_functions $current_namespace
        #puts $all_functions   
    }
}


trace add execution "::proc" enter "::odfi::errortrace::tracer" 

proc b args {
    #c
    source tcl_error_sourced_2.tcl

}

foreach {type line file namespace} ${::odfi::errortrace::all_functions} {
    
    puts "TEST: $type $line $file $namespace"
}


exit

proc a args {
   b
    
}



proc b args {
    #c
    source ${::location}/tcl_error_sourced_2.tcl

}


proc bgerror {message} {
    puts "BGEror"
}





try {
    a
    puts "a was executed"
} on error {res option} {
    
    #puts $res
    #puts $option
       
    set stack [dict get $option -errorinfo ]
    #set stackInfo [dict get $option -errorinfo ]
    set stack_length [string length $stack]
    
    
    #puts "Stack: $stack"
    #puts "Statck Info: $stackInfo"
 
    
    
    # save the error message in the variable stack
    puts $stack
    #puts "The length of the stack is: $stack_length"
    puts "\v\v"
    
    array set sub_array {}
    set x 0 
    set index 0 
    #puts $x
    
    
    # save every row of the error message into an array
    while {$index != -1} {
        set index_tmp [string first "\n" $stack $index+1]
        set sub_array($x) [string range $stack $index $index_tmp]
        #puts "index_tmp: $index_tmp"
        incr x
        #puts "x: $x"        
        if {$index_tmp == -1} {
            set m [expr {$x-1}]
            set sub_array($m) [string range $stack $index+1 end]
            #puts $sub_list(0)
        }  
        set index $index_tmp
    }
    
        
    # check whether the size of the array is odd or even an compute
    # how many times the loop which swaps the array entries has to be executed
    set array_size [array size sub_array]
    if {int(fmod($array_size,2)) == 0} {
        set n [expr {$array_size/2}]
    } else {
        set n [expr {($array_size-1)/2}]
    }


    # rearrange the array, so that the last element will become the first and so on.
    # This is important, because the procedure or something else which started the error stack
    # is always named at the end of the error message.
    if 1 {
    for {set i 0} {$i < $n} {incr i} {      
        set tmp $sub_array($i)
        set m [expr {$array_size-$i-1}]
        set sub_array($i) $sub_array($m)
        set sub_array($m) $tmp
    }
    }
   
    # ONLY FOR TEST:
    # display the elements of the sub_list which contains the error message
    if 0 {
    for {set i 0} {$i < $array_size} {incr i} {
        if {$sub_array($i) == {} } {
            puts "Attention: empty string"
        } else {
        puts $sub_array($i)
        }
    }
    }
    
    
    
    
    
    
    # check the sub_array due to characetristic expressions which most of the error
    # messages contain. These expressions are especially keywords like "file", "procedure",
    # "try"-blocks and "line". 
    # if there is a keyword matched, then it is usual that the explicit name will follow 
    # within quotes.
    puts "The following error message gives you a hint what files, procedures or variables\nare involved due to the occured error:"
    puts "Please note the following notation: "
    puts "The line number is not that one which you see at your editor. The line number is just counted from\n\
    the respective procedure or file."
    puts "Usually there went something wrong within the last two points which are indicated.\nSo please check them\
    carfully due to errors." 
    
    
    # define a extra counting variable, so that at the output you can see how many 
    # files, procedures and so on are involved. 
    set count 0
    
    for {set i 0} {$i < $array_size} {incr i} {
        set index_file [string first "file" $sub_array($i)]
        set index_procedure [string first "procedure" $sub_array($i)]
        set index_try [string first "try" $sub_array($i)]

        if {$index_file != -1} {
            incr count
            # finding the indizes of the explicit name within the quotes.
            set bracket_left [string first "\"" $sub_array($i)]
            set bracket_right [string last "\"" $sub_array($i)]
            
            # extract the keyword from the string 
            set file_name [string range $sub_array($i) $bracket_left $bracket_right]
   
            # if any line number exists, then extract it.
            set index_line [string first "line" $sub_array($i)]
            if {$index_line != -1} {
                set index_line_end [string last ")" $sub_array($i)]
                set index_line_end [expr {$index_line_end-1}]
                set line_number [string range $sub_array($i) $index_line $index_line_end]
                if {$count==1} {
                    puts "\nThe following file started the error stack:"
                    puts [concat $count ":" "file" $file_name]
                    #puts "--> withing this try-block the next procedures or files were called:"
                } else { 
                    puts [concat $count ":" "file" $file_name]
                }
                
            }
            
            # name of the procedure, command file etc. which was called during the try-block
            puts [concat "withing this file" $sub_array([expr {$i+1}]) "was executed at" $line_number]
            puts ""
        }

        if {$index_procedure != -1} {
            incr count
            # finding the indizes of the explicit name within the quotes.
            set bracket_left [string first "\"" $sub_array($i) ]
            set bracket_right [string last "\"" $sub_array($i) ]
            
            # extract the keyword from the string 
            set procedure_name [string range $sub_array($i) $bracket_left $bracket_right]
   
            # if any line number exists, then extract it.
            set index_line [string first "line" $sub_array($i) ]
            if {$index_line != -1} {
                set index_line_end [string last ")" $sub_array($i)]
                set index_line_end [expr {$index_line_end-1}]
                set line_number [string range $sub_array($i) $index_line $index_line_end]
                if {$count==1} {
                    puts "\nThe following procedure started the error stack:"
                    puts [concat $count ":" "procedure" $procedure_name]
                    #puts "--> withing this try-block the next procedures or files were called:"
                } else { 
                    puts [concat $count ":" "procedure" $procedure_name]
                }
                
            }
            
            # name of the procedure, command file etc. which was called during the try-block
            puts [concat "withing this procedure" $sub_array([expr {$i+1}]) "was executed at" $line_number]
            puts ""
        }
        
        if {$index_try != -1} {
            incr count
            # finding the indizes of the explicit name within the quotes.
            set bracket_left [string first "\"" $sub_array($i) ]
            set bracket_right [string last "\"" $sub_array($i) ]
            
            # extract the keyword from the string 
            set try_name [string range $sub_array($i) $bracket_left $bracket_right]
   
            # if any line number exists, then extract it.
            set index_line [string first "line" $sub_array($i) ]
            if {$index_line != -1} {
                set index_line_end [string last ")" $sub_array($i)]
                set index_line_end [expr {$index_line_end-1}]
                set line_number [string range $sub_array($i) $index_line $index_line_end]
                if {$count==1} {
                    puts "\nThe error stack was started within the following try-block:"       
                    puts [concat $count ":" $try_name "- block"]
                    #puts "--> withing this try-block the next procedures or files were called:"
                } else { 
                    puts [concat $count ":" $try_name "- block"]
                }
                
            }
            
            # name of the procedure, command file etc. which was called during the try-block
            puts [concat "withing this try-block" $sub_array([expr {$i+1}]) "was executed at" $line_number]
            puts ""
        }
    }
    

    #puts "Caught error: $stack"
    #puts "Caught error: [dict get $options -errorstack]"
    #puts $res
    #puts [info errorstack]
    #puts $stack
}

