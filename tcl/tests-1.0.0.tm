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

    variable mainSuite ""

    #################################################
    ## Main Factory
    #################################################
    proc suite {name closure} {
 
        odfi::common::println "Create suite $name"
        ## Create Suite
        set mainSuite [::new [namespace current]::Suite #auto $name $closure]
        $mainSuite printExpectList
    }

    proc expandExpectName {name expect_list} {
        set return_list {}
        foreach {element} $expect_list {
            set expect_name [lindex $element 0]
            set status [lindex $element 1]
            lappend return_list [list ${name}_$expect_name $status]
        }

        return $return_list
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

        odfi::common::classField public expect_list {}

        constructor {cName cClosure} {
            ## Set Name and execute Closure
            set name $cName
            odfi::closures::doClosure $cClosure
        }

        public method test {name closure} {
            odfi::common::println "Create test $name in [$this name]"

            ## Create Test object
            set test [::new odfi::tests::Test #auto $name $closure]

            ## Add to Current Suite
            lappend tests $test
            lappend expect_list [odfi::tests::expandExpectName [$this name] [$test expect_list]]
        }

        public method printExpectList {} {
            ::puts $expect_list
        }

        public method suite {name closure} {
            odfi::common::println "Create suite $name in [$this name]"

            ## Create Suite object
            set suite [::new odfi::tests::Test #auto $name $closure]

            #Add to Current Suite
            lappend subSuites $suite
            $this expect_list [odfi::tests::expandExpectName [$this name] [$suite expect_list]]
        }

    }

    itcl::class Test {

        ## The name of the Test
        odfi::common::classField public name ""
        
        odfi::common::classField public expect_list {}

        ## The Closure to be run for the test
        odfi::common::classField public testClosure {}

        constructor {cName cTestClosure} {

            ## Defaults
            ###############
            set name $cName
            odfi::closures::doClosure $cTestClosure

        }

        #################################################
        ## Expectations
        #################################################
       
        public method expect {name expected actual} {
            
            if {$expected != $actual} {
                lappend expect_list [list "[$this name]_$name" FAIL]
                ::puts "\[  FAIL \] Failed $name , expected: $expected, actual value: $actual"
            } else {
                lappend expect_list [list "[$this name]_$name" SUCCESS]
                ::puts "\[SUCCESS\] $name"
            }
        
        }

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
