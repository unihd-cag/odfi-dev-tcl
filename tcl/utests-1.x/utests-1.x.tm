package provide odfi::utests 1.0.0
package require odfi::language 1.0.0
package require odfi::log 1.0.0

namespace eval odfi::utests {

    odfi::language::Language default {


        :suite name {
            +exportToPublic
            +exportTo Suite 
            +var success true
            
            ## Test 
            :test name script {
            
                ## Running
                +method run args {
                    if {[catch {:apply ${:script}} res resOptions]} {
                        odfi::log::info $res
                        [:parent] success set false
                    }
                }
                
                ## Assertions
                +method assertNXObject {v args} {
                    set res false
                    if {$v!="" && [::nsf::is object $v]} {
                        set res true
                    } 
                    
                    :assert "Expecting $v is an NX Object" true $res
                    
                    ## If the args contain -> name , then output the tested value to the name
                    if {[lindex $args 0]=="->" && [llength $args]>1} {
                        uplevel [list set [lindex $args 1] $v]
                    }
                }   
                
                +method assert {message expected value} {
                    
                    if {$expected!=$value} {
                        error "Assertion $message failed, expected=$expected, found=$value"
                    }
                    
                    
                }
            }
        }


    }


    ## Runners
    ###########

    ## Run All available root suites 
    proc run args {

        ## Get All Root suites 
        #############
        set suites [odfi::flist::MutableList::fromList [odfi::nx::getAllNXObjectsOfType ::odfi::utests::Suite]]
        set suites [$suites filter {$it isRoot}]

        odfi::log::info "Found [$suites size] suite(s)"

        
        ## Run Suites 
        #####################
        $suites foreach {
            {suite i} => 

                odfi::log::info "Running suite [$suite name get]"

                ## Run tests 
                $suite shade odfi::utests::Test eachChild {

                    {test i} =>

                        odfi::log::info "Running test: [$test name get]"
                        $test run
                }

        }



        #runFile [info script]
    }

    proc runFile file {

        odfi::log::info "Running File $file"

    }

}
