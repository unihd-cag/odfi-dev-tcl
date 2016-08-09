
set location [file dirname [info script]]


package require nx 2.0.0
source $location/tcl_error.tcl



namespace eval testns {

    if 1 {
    proc a args {
        error "Error in a"
    }
    }

    ::nx::Class create A {
        
        :public method test args {
            #error "Error in class"
            :test2
        }
        
        :method test2 args {
            error "Error in class"
        }
        
        :object method constantMethod args {
        
            error "Error in object method"
        }
    
    }

}

#####################
if 1 {
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


proc b args {
    #c
    source ${::location}/tcl_error_sourced_2.tcl
    #error "Error in b"

}


proc c args {
        error "Error in c"
        rror "ERROR"
}       
}
###################


set a [::testns::A new]
set b [::testns::A new]


#if 0 {
#try {
    #b
    #$a test
    #$b test

#} on error {res option} {
    
        #set stack [dict get $option -errorinfo]
        #puts $stack
        
        #puts "Object call: [$a info class]"
#}
#}



puts "---------------"
try {
    #c 1 2 3
    #b 1 2 3 
    #b
    #testns::a

    #$a test2
    
    #::testns::A::constantMethod test
    
    puts "Object b is $b"
    $b test test  
   
} on error {res option} {
    
        set stack [dict get $option -errorinfo]
        #puts $stack
        
        set output_list [odfi::errortrace::errorToList $res $option]
        odfi::errortrace::printErrorList $output_list
        
        #odfi::errortrace::printErrorListReverse $output_list
        #puts "Object call: [$a info class]"        
}

#------------------------------------------------------------------------------




