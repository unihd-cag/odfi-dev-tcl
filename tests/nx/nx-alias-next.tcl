package require nx 2.0.0
package require odfi::tests
package require nx::trait 0.4


odfi::tests::msg "Handle and next"
nx::Class create A {

    :public method test args {
        puts "A: Hi"
    }

}
nx::Class create B -superclass A {

    :public method test args {
        next
        puts "B: Hi"

    }

    :public alias al1 [:info method handle test]

    #:public alias at [:info method handle test]
    #:public forward at2 [:info method definitionhandle test]

    puts "HANDLE: [:info method definitionhandle test]"
}

nx::Class create C  {

  :public alias rfg:test ::nsf::classes::B::test
}
#C trait add B 


B create b 
b al1

C create c 
c rfg:test

puts "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
exit 0
