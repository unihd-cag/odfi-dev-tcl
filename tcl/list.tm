package provide odfi::list 1.0.0


namespace eval odfi::list {
    
    ## transforms given #lst list using provided #script, with $elt beeing the current element
    ## The #script output will be used to create a new list
    ## @return The new list transformed by #scriptClosure
    proc transform {lst scriptClosure} {
        
        set newlst {}
        foreach elt $lst {
            
            #puts "-> transforming: $elt ([llength $lst])"
            
            lappend newlst [eval $scriptClosure]
        }
        
       # puts "New List: $newlst"
        return [list $newlst]
        
    }
    
    ## \brief Evaluates script for each element of lst, providing $it variable as pointer to element, and $i as index
    # Script is called in one uplevel
    proc each {lst script} {
        
    
        
        for {set ::odfi::list::i 0} {$::odfi::list::i < [llength $lst]} {incr ::odfi::list::i} {
            eval "uplevel 1 {" "set it [lindex $lst $::odfi::list::i];" "$script}"
                      
        }
        
    }
    
    ## \brief Evaluates script for each key/pair arrayVar, providing $key variable as pointer to key, and $value as value
    # Script is called in one uplevel
    proc arrayEach {arrayVar script} {
        
        foreach {key value} [array  get $arrayVar] {
            eval "uplevel 1 {set key $key;set value $value;"  "$script}"
        }
        
    }
 
    
    ################################################################################
    ## Classes
    ################################################################################
    odfi::common::resetNamespaceClasses [namespace current]
    
    
    
    
}