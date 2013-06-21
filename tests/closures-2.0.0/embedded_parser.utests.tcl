#!/usr/bin/env tclsh

package require odfi::closures 2.0.0

## Test Embedded Parser in a namespace
###########################

namespace eval test1 {

    ## Test 1: String to String
    #################
    set input "<% puts foo %>"
    set reference1 "foo"



    puts "testing odfi closures string to string"
    set output [odfi::closures::embeddedTclFromStringToString $input]
    if {[string trim $output]==$reference1} {
        puts "working"
    } else {
        error "Test 1 : not working, output: $output, expected"
    }


    ## Test 2: File to String
    #################

    ## First write to file
    set testFileName "/tmp/closureInputTestFile"
    set fileChannel [open $testFileName "w+"]
    puts $fileChannel $input
    close $fileChannel

    puts "testing odfi closure file to string"

    ## Execute and test
    set output [odfi::closures::embeddedTclFromFileToString $testFileName $input]

    if {[string trim $output]==$reference1} {
      puts "working"
    } else {
      error "not working, output:t diff $output"
    }


    ## Test 3: String to String with only variable name inside closure
    #################
    set foo    "true"
    set input  {<% $foo %>}
    set result "true"

    set output [odfi::closures::embeddedTclFromStringToString $input]
    if {[string trim $output]!=$result} {
        error "Test 3 : not working, output: $output, expected $result"
    }
}
