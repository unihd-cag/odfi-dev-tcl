#!/usr/bin/env tclsh8.6

source [file dirname [info script]]/test_common.tcl

set a ff
odfi::closures::run {

    odfi::closures::run {

        odfi::closures::run {

            puts "Hi $a"

        }

    }

}


itcl::class A {

    public variable name "hello"

    public method apply cl {
        odfi::closures::run $cl 1
    }

    public method addComponent {name cl} {
        odfi::closures::run $cl 1
    }
}

set a [::new A #auto]

$a apply {
    puts "Name of A is: $name"
}

$a apply {
    puts "Name of A is: $name"

    addComponent "tt" {
        set name "componentName"
    }

    puts "Name of A is: $name"
}

## Test oproc 
odfi::closures::oproc te {cname} {
    
    puts "Running in NS  [uplevel namespace current]"
   
    addComponent $cname {
        puts "Added component: $cname"
    }
}

#proc te {name} {

 #   puts "Setting param [odfi::closures::resolve cname 1]"
    
 #   odfi::closures::uplink name 1

   # puts "Set param"


  #  odfi::closures::run {
   #     puts "(TE) Running in NS  [namespace current]"
   #     
     #   addComponent $name {
     #       puts "Added component: $name"
     #   }
    #} 2

#}

$a apply {
    puts "Testing OPROC [namespace current]"
    te "Blabla"
    te "Blabla2"

}
puts "Name of A is: [$a cget -name]"
