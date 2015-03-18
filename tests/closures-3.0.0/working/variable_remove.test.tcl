package require odfi::flextree



namespace eval tt  {
    proc apply {closure} {
        
        odfi::closures::run %closure
    }

}




#############

set a 0
set closure {

    puts "inside closure"
    incr a


}

tt::apply {
    
    puts "First apply:"
    incr a
    
    apply $closure
}
#apply $closure


puts "A is $a"