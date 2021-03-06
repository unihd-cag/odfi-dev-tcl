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

    proc ::rsource f {
            
        if {[::odfi::files::isRelative $f ]} {
            lassign [::odfi::common::findFileLocation] caller line up
            puts "Rsource: [file dirname $caller]/$f"
            puts "Rsource [uplevel namespace current]"
            uplevel [list source [file normalize [file dirname $caller]/$f]]
        } else {
            uplevel [list source $f]
        }
        
       
        
    }
    
    proc fileRelativeToCaller f {
        if {[odfi::files::isRelative $f]} {
       
            lassign [::odfi::common::findFileLocation] rf
            set f [file normalize [file dirname $rf]/$f]
        }
        return $f
    }

    ## return true if the file path has a format of a relative path
    proc isRelative f {
        
        if {[string match "/*" $f] || [string match "\[A-Z\]:/*" $f]} {
            return false
        } else {
            return true
        }
    
    }
    
    ## The filePath is transformed if neccessary, and made absolute using the caller's call file
    ## It is useful to create absolute file from a passed relative file, which logically should not be relative to the execution location
    ## but from the file where the code was written
    proc absolutePathFromCallLocation filePath {
    
        if {[::odfi::files::isRelative $filePath]} {
            lassign [::odfi::common::findFileLocation 2] buildFile buildLine
            #puts "Caller location: $buildFile"
            set filePath [file normalize [file dirname $buildFile]/${filePath}]
        }
        
        return $filePath
    
    }

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
    
    ## @line line number from file
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

        #set catched [catch [list odfi::closures::runITCLLambda 1 $closure] res resOptions]
        
        set catched [catch [list uplevel $closure] res resOptions]
        
        cd $saved

        ## handle error
        if {$catched==1} {
            error $res
        }
        
        return $res


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


    ########################
    ## Monitoring
    ## File Monitor is implemented using polling to be easily compatible with all systems
    #############################
    
    ::nx::Class create FileMonitor {
        
        #:domain-mixins add ::odfi::log::Logger -prefix log
        
        :property -accessor public closure:required
        :property -accessor public target:required
        
        # FOrmat { {FILE LASTMOD} ... }
        :variable -accessor public files {}
        
        ## Running function monitor
        :variable -accessor public afterId ""
        :variable -accessor public pollTimeMS 500
        
        :method init args {
            next 
            
            #:log:setPrefix "fileMonitor"
            set :closure [::odfi::closures::newITCLLambda ${:closure}]
            
        
        }
        
        :public method start args {
            if {${:afterId}==""} {
                set :afterId [after ${:pollTimeMS} "[current object] run"]
            }
        }
        
        :public method stop args {
            if {${:afterId}!=""} {
                after cancel ${:afterId}
                set :afterId ""
            }
        }
        
        :public method run args {
            
            #puts "Testing files"
            
  
            
            ## go through files and regather fiels in new list
            ## This is because we are doing removal during foreach, so indexes have to match in :files
            ## 
            try {
                set i 0
                foreach fileDef ${:files} {
                
                    lassign $fileDef filePath lastModificationTime
                    
                    ## If file does not exist anymore remove
                    ## If actual mtime is newer, call closure and update
                    ## Otherwise just keep file
                    if {![file exists $filePath]} {
                        
                        ## Replace in main files, and don't increment i because list is one shorter now
                        set :files [lreplace ${:files} $i $i]
                        
                        ## Call closure
                        ${:closure} apply [list f $filePath]
                        
                    
                    } elseif {[file mtime $filePath]> $lastModificationTime} {
                          
                          ## Update
                          lset :files $i [list $filePath [file mtime $filePath]]
                          
                          ## Call closure
                          ${:closure} apply [list f $filePath]
                          
                          incr i
                                       
                    } else {
                        incr i
                    }
                    
                    
                }
            } finally {
                ## Reschedule, use after idle to avoid starving other event listeners
                set :afterId [after idle [list after ${:pollTimeMS} [current object] run ] ] 
            }
            
            
        }
        
        :public method addFiles files {
            foreach f $files {
                if {[file exists $f]} {
                
                    lappend :files [list $f [file mtime $f ]]
                    
                } else {
                
                    puts "Cannot monitor non existing file: $f"
                    
                }
                
            }
        }
        
    }
    
    ## FORMAT: list of monitors objects
    variable monitors {}
    
    proc startFileMonitor args {
    
    }
    
    proc stopFileMonitor args {
    
    }
    
    proc newFileMonitor {target files closure} {
    
        ## Create
        set m [FileMonitor new -target $target -closure $closure]
        
        ## Add files
        $m addFiles $files
        
        #lappend ::odfi::files::monitors 
        
        return $m
    }
    
    
    
    
    
    

}
