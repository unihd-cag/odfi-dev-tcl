package require odfi::nx::domainmixin


nx::Class create A {



    :method init args {
        puts "->In A"
        next
    }

}

nx::Class create ATarget -superclass A {

    :property enrichWith:required

    :method init args {
        puts "In ATarget"

        odfi::nx::domainmixin::addMixinsFor ${:enrichWith} {
            "B" B
            "C" C
        }
       
        next

    }

}

nx::Class create B {
    
    :method init args {
        puts "-> In B"
    }

}

nx::Class create C {
    :method init args {
        puts "-> In C"
    }
}


## Enrich with B
ATarget new -enrichWith B

## Enrich with C
ATarget new -enrichWith C
