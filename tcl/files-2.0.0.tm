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

package provide odfi::files 2.0.0
package require odfi::list 3.0.0


namespace eval odfi::files {

    odfi::common::resetNamespaceClassesObjects ::odfi::files
    
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

    ## Read File Content 
    proc readFileContent {filePath} {

        set f [open $filePath]
        set content [read $f]
        close $f

        return $content


    }
    
    proc getFileLine {path line} {
        
        set fd [open $path]
        set i 1
        while {![eof $fd]} {
           
           set lineContent [gets $fd]
           
           if {$i==$line} {
                
                close $fd
                return $lineContent
           }
           
           incr i
        }
        close $fd
        return ""
        
    }


    ## Copying a list of file from a folder to another one
    proc mcopy { from baseFolder files filesList to outputBaseFolder} {
    
        foreach f $filesList {
            catch {file delete -force $outputBaseFolder/$f}
            file copy -force $baseFolder/$f $outputBaseFolder/$f
        }
    
    }

    ## Return true if the provided file content contains the provided match
    ## The match string is in the format of string match
    proc fileContains {file match args} {

        if {[file exists $file] && [string match *$match* [::odfi::files::readFileContent $file]]} {
            return true

        } else {
            return false
        }
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

        set catched [catch [list odfi::closures::runITCLLambda 1 $closure] res resOptions]
        cd $saved

        ## handle error
        if {$catched} {
            error $res
        }


    }

    ##########################################
    ## Line Reader to read a channel line by line and isolate sections 
    ###############################################
    itcl::class LineReader {

        public variable file ""
        public variable fileHandle ""
        constructor cFile {

            ## If File is a file
            if {[file isfile $cFile]} {

                set file $cFile
                set fileHandle [open $file]

            } else {

                ## If file is a channel 
                set file "channel"
                set fileHandle $cFile
            }
            
        }
        public method read args {
            return [::read $fileHandle]
        }
        public method line args {
            set c [gets $fileHandle l]
            if {$c==-1} {
                return -1
            } else {
                return $l
            }
            
        }

        public method eachLine closure {

             odfi::closures::withITCLLambda $closure 1 {
                set line [line] 
                while {$line!=-1} {
                    $lambda apply [list line \"$line\"]
                    set line [line] 
                }
             }
            
        }

        public method skipLines count {
            ::repeat $count {
                line
            }
        }

        public method section {from to closure} {

            ## Search from start delimiter
            set l [line]
            while { $l!=-1 && ![string match "*$from*" $l]} {
                #puts "Non valid line: $l"
                set l [line]
            }
            #puts "Found start: $l"
            
            ## EOF 
            if {$l==""} {
                return
            }

            ## Start found
            ## Buffer until end
            set sectionChannel [odfi::common::newStringChannel]
            set l [line]
            while { $l!=-1 && ![string match "*$to*" $l]} {
                puts $sectionChannel $l
                set l [line]
            }

            #puts "Found stop: $l"

            ## Create New Line Reader 
            ##############
            set sectionReader [::new [namespace current] #auto $sectionChannel]

            ## Call Closure with sectionReader
            odfi::closures::withITCLLambda $closure 1 {
                $lambda apply [list sectionReader $sectionReader]
            }
            #uplevel odfi::closures::::applyLambda [list $closure] [list [list sectionReader $sectionReader]]
        

            ## Return reader anyways
            return $sectionReader

        }

    }

}
