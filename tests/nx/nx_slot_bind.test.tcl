

package require nx 


nx::Class create Test {

    :variable -accessor public var1  "A"

    :property -accessor public  {p1 "A"}

    #:method ff args {
     #   puts "In Filter $args"
    #    next
    #}

    #:p1 filters add ff

}


Test create a 
Test create b

#a  object filters add {} 0

proc fp args {
     puts "In Filter for var1 $args -> [current calledmethod]"
     next
}

a object method f args {
     puts "In Filter for var1 $args -> [current calledmethod]"
     next
}
a object filters add fp 
a object filters guard fp {
    [current calledmethod] == "var1"
}

a var1 set "B"

#a var1 guard
#a p1 reconfigure multiplicity
