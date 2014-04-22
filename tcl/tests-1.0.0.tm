#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    Copyright (C) 2008 - 2014 Computer Architecture Group @ Uni. Heidelberg <http://ra.ziti.uni-heidelberg.de>
#

package provide odfi::tests 1.0.0
package require odfi::closures 2.0.0
package require Itcl

namespace eval odfi::tests {

    ##################################
    ## Gathered tests
    ##################################
    variable toRun {}

    variable currentSuite ""

    ####################################
    ## Global Expects
    ####################################
    proc expect {name expected actual} {
        if {$expected != $actual} {
            ::puts "\[  FAIL \] Failed $name , expected: $expected, actual value: $actual"
        } else {
            ::puts "\[SUCCESS\] $name"
        }
        
    }

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
