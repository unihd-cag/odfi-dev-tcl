package provide odfi::os 1.0.0
package require odfi::closures

namespace eval odfi::os {


    ## Tries to return a precise description of OS.
    ## Example: linux.ubuntu.10.04
    proc getOs args {

        ## Get Basic info
        #############
        set baseOS [string tolower $::tcl_platform(os)]

        ## Linux case, tries to determine distribution
        ##########
        if {$baseOS=="linux"} {

            ## Try to find OS info
            ###########
            fileSetVariables /etc/os-release
            if {[info exists ID]} {

                ## Update ID
                set baseOS ${baseOS}.$ID

                ## Try to get more infos
                ####################
                switch -exact -- $ID {
                    debian {
                       set baseOS ${baseOS}.[odfi::common::readFileContent /etc/debian_version]
                    }
                    default {}
                }


            }


        }


        return $baseOS

    }


    ## Executes the provided switch input on getOs.
    ##  - If no match, outputs an error
    ##  - switch is executed using glob
    ## @warning: switch is called in uplvel 1
    proc onOs switchInput {

        set realSwitch [concat $switchInput {default {

                error "onOs call was provided no implementation for [odfi::os::getOs]"
        }}]

        #puts "Switch patterns: $realSwitch"

        uplevel 1 "switch -glob -- \"[odfi::os::getOs]\" $realSwitch"


    }


    ## For each VAR=VALUE line, make a tcl set call to have variable defined
    ########
    proc fileSetVariables file {

        if {![file exists $file]} {
            return
        }

        ## Read Content
        ###################
        set fileContent [odfi::common::readFileContent $file]

        ## Execute Regexp
        ###################
        #puts "Variables from $fileContent"
        foreach {match var value} [regexp -inline -all -line {^([\w_]+)=(.+)$} $fileContent] {
            #puts "Found $var -> $value"
            uplevel "set $var $value"
        }
    }


}
