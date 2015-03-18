package require odfi::nx::domainmixin 1.0.0

odfi::nx::Class create test {
    
    
}

odfi::nx::Class create EnrichTrait {
    odfi::nx::CommonTrait mixins add EnrichTrait
    
    :public method allThis2 args {
                                
    }
}

nx::Class create ObjM {
    
    :variable count 0
    
    :public method hello args {
          puts "Count: ${:count}"             
     }
}

test create inst1
inst1 object mixins add ObjM

inst1 allThis2

inst1 hello
