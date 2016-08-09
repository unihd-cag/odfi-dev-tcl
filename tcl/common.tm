
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

package provide odfi::common 1.0.0


#package require textutil::adjust

namespace eval odfi::common {

    #############################################################################
    ## Itcl Utilities
    #############################################################################

    ## For a given namespace, resets all the defined classes
    # This is very useful to resource classes definitions
    # Typical usage:
    # namespace eval ns {
    #   resetNamespaceClasses [namespace current]
    # }
    proc resetNamespaceClasses nsName {

        #puts "Reset namespace: $nsName"

        ## Reset classes in IO namespace
        foreach cl [itcl::find classes "*"] {

            ## Reset only this namespaces classes
            if {[string match "${nsName}::*" $cl]==1} {
                catch {itcl::delete class $cl}
                #puts "-> Found class to reset: $cl"
            }


        }
    }


    ## For a given namespace, resets all the defined classes and Objects
    # This is very useful to re-source classes definitions
    # Typical usage:
    # namespace eval ns {
    #   resetNamespaceClassesObjects [namespace current]
    # }
    proc resetNamespaceClassesObjects nsName {

       # puts "Reset namespace: $nsName"

        ## Reset classes in  namespace
        foreach cl [itcl::find classes "${nsName}::*"] {

            #puts "-> Found class to reset: $cl"
            catch {itcl::delete class $cl}

            ## Reset only this namespaces classes
            #if {[string match "${nsName}::*" $cl]==1} {

               #set classObjects [itcl::find objects -class  $cl]
               # foreach obj $classObjects {
               #     puts "need to delete $obj for $cl"
                #    itcl::delete object $obj
                #}




              #  itcl::delete class $cl
                #puts "-> Found class to reset: $cl"
            #}


        }
    }

    ## \brief returns 1 if object is of classname type, otherwise 0
    proc isClass {object className} {

        set result false 

        ## Search ITCL  and NX 
        if {[catch {set result [itcl::find objects $object -isa $className]}]} {
            set result false
        } else {
            if {$result==""} {
                set result false
            } else {
                set result true
            }
            #set result true
        }
        #if {[catch {set nxRes [string equal [$object info class] $className]}]} {
        #    set nxRes 0
        #}
        if {![catch {package present nx}]} {
            if {!$result && [::nsf::is object $object] && ([$object info has type $className] || [$object info has mixin $className])} {
                set result true
            } else {
                #set nxRes 0
            }
        }
        
        
        
        #puts "NX RES: $nxRes -> [$object info class]"
        
        ## Search
        return $result
    }
    
    proc isObject object {
    
        ## Search ITCL  and NX 
        #########
        
        ## ITCL
        set result false
        if {[catch {set result [itcl::find objects $object -isa $className]}]} {
        } else {
            if {$result==""} {
                set result false
            } else {
                return true
            }
            #set result true
        }
        
        ## NX
        if {![catch {package present nx}]} {
            if {[::nsf::is object $object]} {
                return true
            } else {
                #set nxRes 0
            }
        }
        
        return $result
    
    }
    
    proc objectHasMethod {object method} {
        
        if {[::odfi::common::isObject $object]} {
        
            if {![catch {package present nx}]} {
                
                if {[lsearch -exact [$object info lookup methods] $method]>=0} {
                    return true
                } else {
                    return false
                }
                
            } else {
                puts "Cannot check object for method, only NX supported for now"
                return false
            }
        } else {
            return false
        }
        
    }

    ## \brief Deletes object without outputing an error if the object is not found
    proc deleteObject object {

        catch {uplevel 1 "itcl::delete object " $object}

    }

    ## \brief Deletes if necessaray, and creates the object of specified type with given args
    #
    proc newObject {type name args} {

        ## Delete
        uplevel 1 "odfi::common::deleteObject $name"

        ## Create
        set res [uplevel 1 $type $name $args]
        return $res

    }

    proc ::new {type name args} {

        ## Replace %auto with #auto in name 
        set name [regsub {%auto} $name #auto]

        ## Delete
        uplevel 1 "odfi::common::deleteObject $name"

        ## Uplevel namespace
        set upns [uplevel 1 {namespace current}]

        ## Create
        set res [uplevel 1 $type $name $args]

        if {[string match "::*" $res]} {
            return $res
        }
        if {$upns=="::"} {
            return "::$res"
        } else {
            return ${upns}::$res
        }


    }

    ## \brief Returns Object if already exists, otherwise create
    proc ::newIfNotDefined {type name args} {

        ## Uplevel namespace
        set upns [uplevel 1 {namespace current}]

        #puts "**************** Looking for defined "

        ## find (if no absolute NS defined, add parent one)
        ###########
        set searchName $name
        #if {[string match "::*" $searchName]==0} {
        #    set searchName "${upns}::$searchName"
        #}
        set existing [uplevel 1 itcl::find objects $searchName]
        if {[llength $existing]>0} {

            return [lindex $existing 0]
        } else {
           # puts "**************** Will create $searchName"
        }

        ## Create if we come up to here
        uplevel 1 "odfi::common::deleteObject $name"

        ## Create
        #puts "newIfNotDefined not found object with args: [llength $args] [llength [split $args]]"
        #set splittedArgs {}
        #foreach arg $args {
        #    lappend splittedArgs $arg
        #}
        set res [uplevel 1 $type $name [join $args " "]]

        if {[string match "::*" $res]} {
            return $res
        }
        return ${upns}::$res


    }

    proc ::newAbsolute {type name args} {

        ## Delete
        uplevel 1 "odfi::common::deleteObject $name"

        ## Uplevel namespace
        set upns [uplevel 1 {namespace current}]

        ## Create
        set res [uplevel 1 $type $name $args]

        if {$upns=="::"} {
        return "::$res"
        } else {
            return ${upns}::$res
        }

        return ${upns}::$res


    }

    ## To be called in an itcl::class definition to create class field and autogenerate getters/setters
    ## @args may contain:  -noget -noset to avoid generating a getter setter the user would like to define by himself
    ##                     -list to specify the variable is a list
    proc classField {visibility name default args} {

        set visibility "public"

        if {$default==""} {
            set default "\"\""
        }

        ## Declaration
        set script ""
        if {[lsearch -exact $args -noDeclaration]==-1} {

            #puts "Setting class variable using line: $visibility variable $name $default"
            uplevel "$visibility variable $name $default"
        }

        ## Method
        #puts \"Setting value of $name to \[lindex \$args 0\]\"

        uplevel " 
        public method $name args {

            if { \$args != \"\" } {
                
                \$this configure -$name \[lindex \$args 0\]
                #set $name \[lindex \$args 0\]
            }
            return \${$name}
        }
        "


    }


	## Returns the directory of the current script
	proc scriptDirectory args {

		return [file dirname [file normalize [info script] ]]
	}

    ## @return true if top script (frame 1)
    proc isTopScript args {
        set lvl [uplevel [list info level]]
        puts "lvl: $lvl"
        if {$lvl==0} {
            return true
        } else {
            return false
        }
    }

    ### Handle request for a single argument
    proc handleCommandLineOption askedArgument {

        global argv
        set inputArgs $argv

        # Gather info on asked argument
        ############
        set required true
        set long false

        while {true} {

            # Get last char
            set lastchar [string index $askedArgument [expr [string length $askedArgument]-1]]

            # Test
            if {$lastchar=="?"} {
                set required false
            } elseif {$lastchar==":"} {
                set long true
            } else {
                # no match, stop searching
                break;
            }

            # Remove last char that was a special info char
            set askedArgument [string range $askedArgument 0 [expr [string length $askedArgument]-2]]
        }

        # Look up argument in args list
        ####################
        set found false
        set foundValue false
        set nextValue false
        foreach arg $inputArgs {

            ## If it is a value for the previous argument
            if {$nextValue} {
                set foundValue $arg
                break;
            }

            ## If no match, then continue
            #puts "Exploring cmd argument: $arg"
            set match [string match "-$askedArgument" $arg]
            if {!$match} {
                continue;
            }

            ## Match
            set found true

            # If not long, set boolean value
            if {!$long} {
                set foundValue true
                break
            } else {
                # If long, next argument it the value
                set nextValue true
            }

        }

        ## Was required ?
        if {!$found && $required} {
            error "Required argument $askedArgument was not provided"
        }

        ## Set value to asked argument variable
        #namespace eval aflTools set argv_$askedArgument \"$foundValue\"
        #set argv_$askedArgument $foundValue
        variable argv_$askedArgument
        set argv_$askedArgument $foundValue

        # Remove from argv
        array unset filtered_argv $askedArgument
        array unset filtered_argv $foundValue

    }

    ## Get Values from arguments
    proc getOptionsFromArgument args {
        global argv

        # Prepare filtered argvs

        # Asked arguments
        foreach askedArgument $args {

            # Clean argument name
            set cleanedArgument $askedArgument
            regsub {([a-zA-Z_]+):?} $askedArgument {\1} cleanedArgument

            # Argument handler
            if {[catch {odfi::common::handleCommandLineOption $askedArgument} errormsg]} {

                odfi::common::logError "$errormsg"
                exit -1

            } else {
                variable argv_$cleanedArgument
                set vname "argv_$cleanedArgument"
            }

        }
    }

    ## Gives the path to an ini and the requried arguments on the same format as handleCommandLineArguments
    ## Look for value in argument or ini if not found, and store value in ini for later usage
    proc getOptionsFromArgumentOrIni {ini args} {

        global argv

        # Prepare filtered argvs
        variable filtered_argv
        set filtered_argv $argv

        # Asked arguments
        foreach askedArgument $args {

            # Clean argument name
            set cleanedArgument $askedArgument
            regsub {([a-zA-Z_]+):?} $askedArgument {\1} cleanedArgument
            #puts "CArg: $cleanedArgument"

            # Argument handler
            if {[catch {odfi::common::handleCommandLineOption $askedArgument} errormsg]} {

                ## No argument found, try into init
                set val [odfi::common::getValueFromIni $ini $cleanedArgument]
                if {$val==false} {
                    odfi::common::logError "$errormsg"
                    exit -1
                } else {
                    # Set value then
                    variable argv_$cleanedArgument
                    set argv_$cleanedArgument $val
                }
            } else {

                variable argv_$cleanedArgument
                set vname "argv_$cleanedArgument"
                if {[info exists $vname]} {
                    #puts " Writing Value is [subst $$vname]"

                    ## Update into ini if set
                    odfi::common::writeValueToIni $ini $cleanedArgument [subst $$vname]
                }
            }
        }

    }

    ## Reads initFile and search for a ^key=value$ pair and returns its value
    ## Returns false if value not found
    proc getValueFromIni {iniFile key} {

        # Check file presence
        if {[file isfile $iniFile]==0} {
            exec touch $iniFile
        }

        # Read data
        set iniFileHandle [open $iniFile "r"]
        set data [read $iniFileHandle]

        # Search
        set value ""
        regexp -line "^$key=(.*)$" $data -> value

        close $iniFileHandle

        if {$value==""} {
            set value false
        }
        return $value

    }

    ## Write/replace a key=value pair in an ini file
    proc writeValueToIni {iniFile key value} {

        ## Is the key already in there ?

        ## Open file & read
        set iniFileHandle [open $iniFile "a+"]
        seek $iniFileHandle 0 start
        set data [read $iniFileHandle]

        ## Substitution
        set substituted $data
        set count [regsub -line -all "^$key=.*$" $data "$key=$value" substituted]
        if {$count == 0} {
            # Nothing substituted, create value and add
            seek $iniFileHandle 0 end
            puts $iniFileHandle "$key=$value"
        } else {

            # Overwrite
            close $iniFileHandle
            set iniFileHandle [open $iniFile "w+"]
            puts $iniFileHandle $substituted
        }

        # Close file
        close $iniFileHandle
    }

    ## Makes a copy with globbing if a pattern is provided
    ## If pattern is used, src and dest must be directories
    ## ex: copy ./ ../newdir/ *.v
    proc copy {src dst {pattern ""} {force true}} {

        # Result
        set copied {}

        if {$pattern!=""} {
            # Pattern copy
            ###################

            ## prepare destination
            if {![file exists $dst]} {
                file mkdir $dst
            }

            ## Glob
            set files [glob -nocomplain -directory $src $pattern]

            ## Copy single files if there are some
            if {[llength $files]>0} {
                foreach f $files {

                    ## Ignore directories
                    if {[file isdirectory $f]} {
                        continue
                    }

                    if {$force==true} {
                        file copy -force $f $dst
                    } elseif {[file exists $dst/[file tail $f]]==0} {
                        file copy $f $dst
                    }
                    lappend copied $f

                }
            }

        } else {
            # No pattern copy
            ###################
            if {$force==true} {
                file copy -force $src $dst
            } elseif {[file exists $dst/[file tail $src]]==0} {
                file copy $src $dst
            }
            lappend copied $src

        }

        return $copied

    }

    proc readFileContent {filePath} {

        set f [open $filePath]
        set content [read $f]
        close $f

        return $content


    }

	## Appends the content of src into the dst
	proc append {src dst} {

		## Open Source and Destination
		set dstChan [open $dst "a"]
		set srcChan [open $src "r"]

		## Write source into destination
		puts $dstChan [read $srcChan]

		## Close Source and Destination
		close $dstChan
		close $srcChan
	}

    ## This method replaces all ${VAR} bash-like env variable with the $::env(VAR) TCL syntax
    proc resolveEnvVariable src {

        global env

        set res [regsub -all {\$\{?([A-Z_0-9]*)\}?} $src {$::env(\1)}]

        #puts "ENV Resolv res: $res"
        #eval "return $res"
        #return [eval "return $res"]
        subst $res
    }

    ## \brief If @str is a variable definition string like: "$var" name, get the value of the variable
    # @return str variable value, or str if not a variable
    proc resolveVariable str {

        if {[string match "\$*" $str]} {
            return [set [string range $str 1 end]]
        }

        return $str

    }

    ## Parses the provided string by:
    ##  - Resolve ${} like environement variables
    ##  - eval the string for eventual tcl commands parsing, only if starting with [
    ##  - if starts with @ , transform as object syntax
    proc parseRichString str {

        set str [resolveEnvVariable $str]
        set res $str

        ## Resolve [] commands
        ## IF eval fails, only return the content
        ######################
        if {[string match "\[*" $res]} {
            set res  [eval $str]
        } else {
            set res $str
        }

        ## Starts with @ ?
        ####################
        if {[string match "@*" $res]} {

            ## Transform and eval
            ###############
            set transformed ""
            odfi::regexp::pregexp {(?:((?:::)?\$?[a-zA-Z_0-9]+))?\.([a-zA-Z_0-9]+)(?:\(([a-zA-Z_0-9]*)\))?} $res {

                #puts "Matched: $matchContent // $groupCount"

                ## Gather full match
                ::switch $groupCount {
                    1 {
                        set subject     ""
                        set method      "$group0"
                        set parameter   ""
                    }
                    2 {
                        set subject     ""
                        set method      "$group0"
                        set parameter   "$group1"
                    }
                    3 {
                        set subject     "$group0"
                        set method      "$group1"
                        set parameter   "$group2"
                    }
                }


                ## If not first loop, no subject
                set unbalanced false
                set startD ""
                set endD   ""
                if {[string length $transformed]>0 && [llength $transformed]==1} {
                     #set transformed "\[$transformed"
                     #set unbalanced true
                     set startD " \["
                    set endD   "\]"
                } elseif {[string length $transformed]>0} {
                    set transformed "\[$transformed\]"

                }


                #puts "Rich object: $group0 , method $group1 and parameter $group2"

                set transformed [string trim "$transformed$startD$subject $method $parameter$endD"]

                if {$unbalanced==true} {
                    set transformed "$transformed\]"
                }

                #puts "End of step. $transformed"

            }
            #set regRes [regexp -inline -all ]
            #set transformed
            #puts "Transform result: $transformed"


             set res [uplevel $transformed]
        }

        return $res
    }


	## Returns the provided path as an absolute path, using the provided
	# base path as resolution folder for Relative paths
	proc absolutePath {path {basePath ""}} {

		## Use pwd if basePath is ""
		if {[string length $basePath]==0} {
			set basePath [pwd]
		}


		## If Relative -> append to basePath and normalize
		## Otherwise it should already be absolute
		if {[file pathtype $path]=="relative"} {
			set path [file normalize $basePath/$path]
		}

		## Return
		return $path

	}

    ## \brief Returns the folder path from absolute paths #fromPath to #toPath as a relative path.
    # For Example, "relativePath /a/b/c/d /a/b/e" will return ../../e
    # @param fromPath An absolute folder path
    # @param toPath An absolute folder path
    proc relativePath {fromPath toPath} {

        #puts "From path has for length: [string length $fromPath]"

        ## Make sure paths are absolute
        ###########
        set fromPath [file normalize $fromPath]
        set toPath [file normalize $toPath]

        ## For on the strings until no common part anymore
        ###########
        set commonPathParts 0
        for {set i 0} {$i < [string length $fromPath] && $i < [string length $toPath] } {incr i} {


            ## Stop condition:
            ##  - character difference
            if {[string index $fromPath $i]!=[string index $toPath $i]} {
                break
            }

            ## If not stoped, and we are on a '/', then we have one path component more in common
            if {[string index $fromPath $i]=="/"} {
                incr commonPathParts
            }

        }

        #puts "Path have $commonPathParts in common"

        ## Get remaining non common part
        #############
        set fromNonCommon [lrange [file split $fromPath] $commonPathParts end]
        set toNonCommon [lrange [file split $toPath] $commonPathParts end]

        #puts "From non common: $fromNonCommon"
        #puts "To non common: $toNonCommon"


        ## 1. Go back to common part using ../
        ##    There are as much ../ as the length of the non common part
        set relpath ""
        foreach noncommon $fromNonCommon {
            set relpath "../$relpath"
        }

        ## Append the toNoncommon part
        set relpath "$relpath/[join $toNonCommon /]"

        ## Return
        #################
        return $relpath


    }


    proc logWarn msg {

        puts "*W: $msg"

    }

    proc logInfo msg {

        puts "*I: $msg"

    }

    proc logFine msg {

        puts "*F: $msg"

    }

    proc logError msg {
        puts "*E: $msg"
    }

    


    ##################################################################################
    ## Print
    ##  - offers convinient procedures to make println in a stream
    ##  - Allows for example to retain indenting whish among calls
    ##################################################################################

    variable indentation ""

    ## Equivalent to put
    proc print {str {channelId -1}} {
        variable indentation

        ## No channelId outputs to stdout
        if {$channelId==-1} {
            set channelId "stdout"
        }

        ## Output
        puts -nonewline $channelId $indentation$str
    }

    ## Equivalent to puts
    ## No channelId outputs to stdout
    proc println {str {channelId -1} args} {
        variable indentation

        ## No channelId outputs to stdout
        if {$channelId==-1} {
            set channelId "stdout"
        }

        ## Output
        puts $channelId $indentation$str

    }

    ## Equivalent to puts with an extra second new line
    proc printlnln {str {channelId -1}} {
        println $str $channelId
        println "" $channelId
    }

    proc printlnIndent args {
        variable indentation
        set indentation "$indentation    "
    }

    proc printlnOutdent args {
        variable indentation
        set indentation [string replace $indentation 0 3]
    }


   

	proc execCommand {execCommand {targetChannel stdout}} {

        set localChannel false

		## Start Command
		set execChan [open "|$execCommand 2>@1"]

        ## String channel output if no target channel specified
        if {$targetChannel==-1} {
            set targetChannel [odfi::common::newStringChannel]
            set localChannel true
        }

		## Pull Output until finished
		while {1} {


			# Test end
			if {[eof $execChan]} { break; }

           # puts "Get Line of output"
            set data [read $execChan 20]
            puts -nonewline $targetChannel $data
            flush $targetChannel
            
			# Output
			#set line [string trim [gets $execChan]]
			#puts $targetChannel $line

		}

        ## Closre local channel and return result if it is one
        if {$localChannel==true} {

            flush $targetChannel
            set res [read $targetChannel]
            close $targetChannel
            return $res

        }

	}
	
	
	## Common EXEC
	###################
	
    proc execRead chan {
        if {[eof $chan]} {
            fileevent $chan readable {}
            set odfi::powerbuild::eofexec true
            #puts "In Exec eof channel "
        } else {
            #puts "In Exec read "
            puts -nonewline [read $chan]
            #puts "In Exec done "
            if {[eof $chan]} {
                fileevent $chan readable {}
                set odfi::common::eofexec true
               # puts "In Exec eof channel "
            }
        }
        

    }

    ##
    proc exec args {


        set monitorProcess [open "|$args 2>@1" r]
        fconfigure $monitorProcess -blocking 0

        #puts "Setup file event"
        fileevent $monitorProcess readable  [list odfi::common::execRead $monitorProcess]
        vwait odfi::common::eofexec

        catch {close $monitorProcess}
        return 0

    }
	
	



    ###############################
    ## Source file location utilities 
    ###############################

    ## @return {file line}
    proc findFileLocation {{baseLevel 1} {resetMatch ""}} {

        ## Resolve file and line
        ## Start at -2
        ## Look for frame level with file
        ## If we find eval, add line to current line in file
        set currentLineInFile 1
        set foundFile ""
        set maxlevel [info frame]
        set level $baseLevel
        while {$level<[expr $maxlevel]} {
            
            set callerFrame [info frame -$level]
            
            #puts "Type -> [dict get $callerFrame type]"
            
            ## If file -> finish
            ## If eval -> add line
            if {[dict get $callerFrame type]=="eval"} {

                incr currentLineInFile [expr [dict get $callerFrame line] -1]
              
            } elseif {[dict get $callerFrame type]=="source"} {
            
                ## If File matches the reset match, keep going and reset everything
                set foundFile  [dict get $callerFrame file]
                if {$resetMatch!="" && [string match "*$resetMatch*" $foundFile]} {
                    set currentLineInFile 1
                    set foundFile ""
                } else {
                    incr currentLineInFile [expr [dict get $callerFrame line] -1]
                    break
                }
                
                
            }
            
            incr level

        }
        
        return [list $foundFile $currentLineInFile]


    }
    
    ## @return {file line}
    proc findFileLocationSegments {{baseLevel 1}} {
    
    
        set result {}
        
        ## Resolve file and line
        ## Start at -2
        ## Look for frame level with file
        ## If we find eval, add line to current line in file
        set currentLineInFile 1
        set foundFile ""
        set maxlevel [info frame]
        set level $baseLevel
        while {$level<[expr $maxlevel]} {
            
            set callerFrame [info frame -$level]
            
            ##puts "Type -> [dict get $callerFrame type]"
            ## If file -> finish
            ## If eval -> add line
            if {[dict get $callerFrame type]=="eval"} {

                incr currentLineInFile [expr [dict get $callerFrame line] -1]
              
            } elseif {[dict get $callerFrame type]=="source"} {
            
                ## If File matches the reset match, keep going and reset everything
                set foundFile  [dict get $callerFrame file]
                
                incr currentLineInFile [expr [dict get $callerFrame line] -1]
                lappend res [list $foundFile $currentLineInFile]
                
                set foundFile ""
                set currentLineInFile 1
                
                
            }
            
            incr level

        }
        
        return $res


    }

     ## @return {file line}
    proc findFileLocationStack args {

        set maxlevel [info frame]
        #puts "Max search level: $maxlevel"
        set level 1
        set res {}
        while {$level<[expr $maxlevel]} {

           # puts "level: $level"
            ## Get 
            if {[catch [list set fd [info frame -$level]]]} {
                break
            } else {

                ## If file, return 
                if {[dict exists $fd file]} {

                    lappend res [list [dict get $fd file] [dict exists $fd closure]]
                } else {
                    
                }

            }

            incr level
        }

        return $res 

    }

    ## @return {file line}
    proc getFileLocationStack args {

        set maxlevel [info frame]
        #puts "Max search level: $maxlevel"
        set level 1
        set res {}
        while {$level<[expr $maxlevel]} {

           # puts "level: $level"
            ## Get 
            if {[catch [list set fd [info frame $level]]]} {
                break
            } else {

                ## If file, return 
                if {[dict exists $fd file]} {

                    lappend res [list [dict get $fd file] [dict get $fd line] [dict get $fd cmd]]
                } else {
                    
                }

            }

            incr level
        }

        return $res 

    }

    ## Black magic to find out the file location for the currently active script 
    proc findUserCodeLocation args {

        ## Active script 
        set script [info script]
       # puts "Active Script: $script"

        ## Get Frame stack 
        set stack [getFileLocationStack]

        #foreach s $stack {

         #   puts "*** $s"
        #}

        ## Find the entry with the file 
        foreach entry $stack {

            if {[string match *$script* [lindex $entry 0]]} {
                return $entry
            }

        }

        return {"" 0}

    }


}

