

puts "Language test"

package require odfi::closures  3.0.0
package require odfi::flist     1.0.0
package require odfi::flextree
package require nx

## Infrastructure
#######################
nx::Class create Language {
    
    :variable classStack 1
    :variable targetNamespace ""
    
    :method init args {
        set :classStack [odfi::flist::MutableList new]
        set :targetNamespace [uplevel  namespace current]
    }
    
    ## Hierarchy Stack
    
    :public method apply cl {
        odfi::closures::run $cl
    }
    
    ## Unknown method used to create class
    :method unknown {called_method args} {
        puts "Unknown method '$called_method' called"
        
        set realArgs {}
        foreach arg $args {
            puts "Arg: $arg -> [string is alnum $arg]"
            if {[string is alnum $arg]} {
             lappend realArgs $arg   
            }
        }
        
        puts "Real args : [list $realArgs args]"
        
        ## Last argument in args may be the configuration closure for the language element
        set configClosure ""
        if {[llength $args]>0 && [string is list [lindex $args end]]} {
            puts "Found config closure"
            set configClosure [lindex $args end]
        }
        
        ## Create Class Name
        ################
        set className [string toupper $called_method 0 0]
        set canonicalName ${:targetNamespace}::$className
        #set targetNamespace [uplevel 2 namespace current]        
        
        ## Create Class for the name
        ########
        puts "Creating class: $canonicalName"
        ::nx::Class create $canonicalName -superclasses odfi::flextree::FlexNode {
            
        }
        
        ## Create Builder
        ##   -> Into parent class
        ##   -> As top main method otherwise
        ######################
        if {[${:classStack} size] >0} {
            
            puts "Creating building in parent class"
            
            ## Create BuilderTrait
            #############
            ::nx::Class create ${canonicalName}Builder {
                
                upvar className className
                :public method [string tolower $className] args {
                    puts "In Input builder"
                }
            }
            
            ## Import to Parent
            ############
            [${:classStack} peek] mixins add   ${canonicalName}Builder          
            
        } else {
            
            puts "Creating builder: [string tolower $canonicalName]"
            eval "proc [string tolower $canonicalName] {$realArgs args} {
                
                ## Create instance of class
                set inst [$canonicalName new]
                
                return \$inst
            }"
           
            
        }
        
        ## Stack and Configure
        ##########
        ${:classStack} push $canonicalName
        
        :apply $configClosure
        
        ## UnStack
        ${:classStack} pop        
    }    
    
}

## Define Language
##########################
namespace eval hwdesign {
    Language create HW
    
    HW apply {
        
        :module name {
            
            :input name {
                
            }
        }
    }    
    
    puts "HW -> [HW info class]"    
}



nx::Class create TEESST {
    
}

## Stats
################
puts "--------- After language definition -----------"

puts "Test: [lsort [nx::Class info instances]]"
puts "Test: [nx::Object info children]"

#set commands [lsort [info commands "nsf::*"]]
#foreach c $commands {
#    puts "-> Command: $c"
#}

## Use It
#############

set m [::hwdesign::module test {
    
}]

puts "Created Module: $m -> [$m info class] -> [$m info lookup mixins]"

$m apply {
 
    :input "test"
    
}

exit 0
module Test {
	
	
	
    module Test2 {
    	
    }
}