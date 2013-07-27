package provide odfi::files 1.0.0
package require odfi::list 2.0.0

namespace eval odfi::files {


    #############################################################################
    ## File Utilities
    #############################################################################

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

}
