package provide odfi::tests 1.0.0
package require odfi::closures 2.0.0
package require Itcl

namespace eval odfi::tests {

    ##################################
    ## Gathered tests
    ##################################
    variable toRun {}

    variable currentSuite ""

    #################################################
    ## Factories
    #################################################

    proc test {name closure} {

        odfi::common::println "Create test $odfi::tests::currentSuite"

        ## Create Test
        set test [::new [namespace current]::Test #auto $name $closure]

        ## Add to Current Suite if necessary
        if {[odfi::common::isClass $odfi::tests::currentSuite [namespace current]::Suite]} {

            $odfi::tests::currentSuite addTest $test

        } else {

            ## Otherwise Just Run

        }



    }

    proc suite {name closure} {

        ## Create Suite

        ## Record as current

        ##

    }



    #################################################
    ## Classes
    #################################################

    itcl::class Suite {

        ## The name of the Test
        odfi::common::classField public name ""

        ## The Sub suites
        odfi::common::classField public subSuites {}

        ## The Tests
        odfi::common::classField public tests {}

        constructor {cName} {

            ## Defaults
            ###############
            set name        $cName
            set tests {}
            set subSuites {}

        }

        ## Applies closure to object
        public method apply closure {

            odfi::closures::doClosure $closure
        }

        ## Method called to run the suite
        public method run args {

            odfi::common::println "Running Suite: $name"

            ## Call All Tests
            ##########
            foreach test $tests {
                $test run
            }


            ## Call All Suites
            #######################
            foreach suite $subSuites {
                $suite run
            }
        }


        public method addTest testObject {

            odfi::common::println "Adding test to suite"

            lappend tests $testObject
        }

        public method addSuite {name closure} {

            ## Create Suite
            set suite [::new [namespace current] #auto $name]
            lappend subSuites $suite

            ## Record as current
            set [namespace parent]::currentSuite $suite

            ## Apply
            $suite apply $closure

            ## Reset current
            set [namespace parent]::currentSuite ""

        }

    }

    itcl::class Test {

        ## The name of the Test
        odfi::common::classField public name ""

        ## The Closure to be run for the test
        odfi::common::classField public testClosure {}

        constructor {cName cTestClosure} {

            ## Defaults
            ###############
            set name        $cName
            set testClosure $cTestClosure

        }

        ## Method called to run the test. This only starts the #testClosure
        public method run args {

            odfi::closures::doClosure $testClosure

        }


        #################################################
        ## Expectations
        #################################################

        ## #map is a lit containing pair of result and expected value
        ## the result
        public method expectMap map {

            foreach {result expect} $map {

                ## Ifnore if result starts with #
                if {[string match "#*" $result]} {
                    continue
                }

                ## Parse result and expect string
                set resultParsed [odfi::common::parseRichString $result]
                set expectParsed [odfi::common::parseRichString $expect]

                ## Check
                if {$resultParsed!=$expectParsed} {

                    error "Test Failed, expected  $expectParsed, but got $resultParsed, while checking $result against $expect"

                }


            }

        }

    }






}
