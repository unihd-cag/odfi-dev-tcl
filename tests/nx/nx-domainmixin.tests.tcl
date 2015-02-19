package require odfi::nx::domainmixin

## Trait inheritance chain
############

nx::Trait create A {

    :public method test args {
        next
        puts "A: Hi [list a b]"

    }

}


nx::Trait create B -superclass A {

    :public method test args {
        next
        puts "B: Hi"

    }

}

nx::Trait create C -superclass B {
    
    :public method test args {
        next
        puts "C: Hi"

    }

}

## Normal usage
##########
nx::Class create Test1 {

   # :domain-mixins add B

}
Test1 domain-mixins add C

Test1 create t1 
t1 test

## Prefix usage 
######
nx::Class create Test2 {

    #:domain-mixins add B -prefix pf1

}
Test2 domain-mixins add C -prefix pf1

Test2 create t2
t2 pf1:test

## Duplicate prefix usage 
######
nx::Class create Test3 {

    #:domain-mixins add B -prefix pf1

}
Test3 domain-mixins add C -prefix pf1

## Object domain Mixin 
##################
nx::Class create Test4 {

}
Test4 create t4
#t3 m add C -prefix pf2
