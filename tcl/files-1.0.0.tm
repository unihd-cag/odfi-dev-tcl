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

package provide odfi::files 1.0.0
package require odfi::list 2.0.0
package require odfi::closures 2.0.0

namespace eval odfi::files {


    #############################################################################
    ## File Utilities
    #############################################################################

    ## Write Given Content to file
    proc writeToFile {f content} {

        set fStream [open $f w]
        puts -nonewline $fStream $content
        flush $fStream
        close $fStream

    }

    ## Improved Glob, that can run recursively and executes provided closure on each file
    proc glob {args closure} {

        set args [split $args]
        ## Recursive
        ####################
        if {[odfi::list::arrayContains $args "-recursive"]} {

            ## Get Base Folder
            #####################
            set baseFolder [odfi::list::arrayGetDefault "-directory" $args [pwd]]
            set args [odfi::list::arrayDelete $args "-directory"]
            set args [odfi::list::arrayDelete $args "-recursive" -keyOnly]
            set folders {}
            lappend folders $baseFolder

            ## Start
            ###################
            while {[llength $folders]>0} {

                ## Pop first
                set currentFolder [lindex $folders 0]
                set folders [lreplace $folders 0 0]

                #::puts "Searching folder: $currentFolder with $args"

                ## Look For All subfolders and enque them
                #################
                set folders [concat $folders [::glob -nocomplain -type d -directory $currentFolder *]]

                ## Do actual Search
                ##########################

                foreach file [eval "::glob -nocomplain -directory $currentFolder $args"] {

                    uplevel "set file $file"
                    odfi::closures::doClosure $closure 1
                }

            }

        }


    }


    ## Executes closure inside a directory, and return back in all cases
    ## The closure is executed in uplevel 1 to cover this proc level
    proc inDirectory {path closure} {

        set saved [pwd]
        cd $path

        set catched [catch [list odfi::closures::doClosure $closure 1] res resOptions]
        cd $saved

        ## handle error
        if {$catched} {
            error $res
        }


    }

}
