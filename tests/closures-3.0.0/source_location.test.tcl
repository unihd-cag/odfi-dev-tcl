#!/usr/bin/env tclsh8.6

package require odfi::closures 3.0.0


odfi::closures::run {

    puts "In CL1 [info script]"


    puts "--> At line [odfi::closures::getCurrentLine]"

    puts "--> At line [odfi::closures::getCurrentLine]"

    odfi::closures::run { 

        puts "In CL2"

        puts "--> At line [odfi::closures::getCurrentLine]"


        odfi::closures::run { 

        puts "In CL3"
        puts "--> At line [odfi::closures::getCurrentLine]"

       

            
        }

    }

    source source_location_sourced.tcl

}
