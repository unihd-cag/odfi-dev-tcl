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
        
        for {set i 0} {$i < [llength $lst]} {incr i} {
            eval "uplevel 1 {set i $i;" "set it [lindex $lst $i];" "$script}"
                      
        }
        
    }
    
    
}