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

package provide odfi::os 1.0.0
package require odfi::closures 3.0.0

namespace eval odfi::os {


    ## Returns the platform: win and linux for example
    proc getPlatform args {
    
        ## Get Basic info
        #############
        set basePlatform [string tolower $::tcl_platform(os)]
        
        if {[string match "*windows*" $basePlatform]} {
            return "win"
        }
        return $basePlatform
    }

    proc getArchitecture args {
    
        #puts "All vars: [array get ::tcl_platform *]"
        set arch  [string tolower $::tcl_platform(machine)]
        if {[string match *64* $arch]} {
            return "x86_64"
        }
        return $arch
    }
    



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


        } elseif {[string match "*windows*" $baseOS]} {
            return "windows"
        }


        return $baseOS

    }

    proc isWindows args {
        
        if {[string match "windows" $::tcl_platform(platform)]} {
            return true
        } else {
            return false
        }
    }
    
    proc isWindowsMsys args {
    
        if {[::odfi::os::isWindows] && [string match "*msys*" "$::tcl_library"]} {
            return true
        } else {
            return false
        }   
    }
    
    proc processHasShell args {
        if {[llength [array names ::env SHELL]] > 0} {
            return true
        } else {
            return false
        }
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


    ## Find Command in path
    ##########
    
    proc isCommandInPath command {
        
        ## Separators and exe extension
        if {[::odfi::os::isWindows] && ![::odfi::os::processHasShell]} {
            set pathSeparator ";"
            set exeExtension "exe"
        } else {
            set pathSeparator ":"
            set exeExtension ""
        }
        
        ## Get path and split
        set envPaths [split $::env(PATH) $pathSeparator]
        foreach envPath $envPaths {
        
            if {[file exists $envPath/${command}.$exeExtension]} {
                return true
            }
        }
        
        return false
    
    }

}
