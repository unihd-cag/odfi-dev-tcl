package provide odfi::common 1.0.0
package require Itcl 3.4
#package require textutil::adjust

namespace eval odfi::common {

	## Returns the directory of the current script
	proc scriptDirectory args {
		
		return [file dirname [file normalize [info script] ]]
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

    ## Makes a copy with globbing is a pattern is provided
    ## If pattern is used, src and dest must be directories
    ## ex: copy ./ ../newdir/ *.v
    proc copy {src dst {pattern ""} {force true}} {

        # Result
        set copied {}

        if {$pattern!=""} {
            # Pattern copy
            ###################

            ## Glob
            set files [glob -nocomplain -directory $src $pattern]

            ## Copy single files if there are some
            if {[llength $files]>0} {
                foreach f $files {
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
        eval return $res

    }
	
    
    ## Parses the provided string by:
    ##  * Resolve ${} like environement variables
    ##  * eval the string for eventual tcl commands parsing, only if starting with [
    proc parseRichString str {
        
        set str [resolveEnvVariable $str]
        
        ## IF eval fails, only return the content
        if {[string match "\[*" $str]} {
            return [eval $str]
        } else {
            return $str
        }
    }
    
	
	## Returns the provided path as an absolute path, using the provided
	## base path as resolution folder for Relative paths
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


    proc logWarn msg {

        puts "*W: $msg"

    }

    proc logInfo msg {

        puts "*I: $msg"

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
    proc println {str {channelId -1}} {
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

    ##################################################################################
    ## Embedded TCL
    ##  -  Replace embbeded TCL between <% %> markors in data with evaluated tcl
    ##################################################################################

    ## Replace embbeded TCL between <% %> markors in data with evaluated tcl
    ## <% standard eval %>
    ## <%= evaluation result not outputed %>
    ## @return resulting stream
    proc embeddedTclStream {dataStream {caller ""} } {

        set resultChannel [chan create "write read" "odfi::common::[StringChannel #auto]"]

        ## Stream in the data, and gather everything between <% ... %> an eval
        ################

        set token [read $dataStream 1]
        set gather false
        set script ""
        while {[string length $token]==1} {

            ## Gather / Eval
            ########################

            #### If <%, gather
            if {$gather == false && $token == "<" } {

                ## If % -> We can start
                set nextChar [read $dataStream 1]
                if {$nextChar=="%"} {
                    set gather true

                    ## Output Modifiers
                    #########################
                    set outputNoEval false

                    #### If the next character is '=', set no eval output mode
                    set modifier [read $dataStream 1]
                    if {$modifier== "=" } {

                        ## Don't use the eval output
                        set outputNoEval true

                    } else {

                        ## Not a modifier -> Output to script
                        set script "${script}$modifier"
                    }

                } else {

                    ## Not a start -> Output to result
                    puts -nonewline $resultChannel $token
                    #puts -nonewline $resultChannel $nextChar
                    set token $nextChar
                    continue
                }

            } elseif {$gather==true && $token == "%" } {

                #### If %>, eval
                set nextChar [read $dataStream 1]
                if {$nextChar==">"} {

                    set gather false

                    ## Prepare a Channel
                    ############################
                    set eout [chan create "write read" "odfi::common::[StringChannel #auto]"]

                    #puts "Script: $script "

                    ## Eval Script
                    ###########################
                    set evaled [string trim [eval $script]]

                    ## If evaluation output is to be ignored, set to ""
                    if {$outputNoEval==true} {
                        set evaled ""
                    }

                    ## Get Embedded output
                    ######################
                    flush $eout
                    set output [read $eout]
                    close $eout

                    ## Result
                    ######################

                    ## If the embedded output is not empty, use it instead of evaluation result
                    set evalResult $evaled
                    if {[string length $output]>0} {
                        set evalResult $output
                    }

                    ## Adjust output
                    # set evalResult [::textutil::adjust::adjust [::textutil::adjust::indent $evalResult "    " 0] -justify left]
                    #set evalResult [::textutil::adjust::indent $evalResult "    " 1]

                    ## Output to result string
                    puts -nonewline $resultChannel $evalResult

                    ## Reset script
                    set script ""

                } else {

                    ## Not an end -> Output to script
                    set script "${script}$token"
                    set script "${script}$nextChar"

                }

            } elseif {$gather==true} {

                #### If gather -> Gather characters for script
                set script "${script}$token"

            } else {

                #### If not gather, output to result
                puts -nonewline $resultChannel $token
            }

            ## Read next token
            #############
            set token [read $dataStream 1]
        }

        ## Output result
        #######################
        flush $resultChannel
        set result [read $resultChannel]
        close $resultChannel

        return $result

    }

	
	## Replace embbeded TCL between <% %> markors in source file with evaluated tcl, and returns the result as a string
	## <% standard eval %>
	## <%= evaluation result not outputed %>
	proc embeddedTclFromFileToString inputFile {
		
		## Open source file
		set inChannel  [open $inputFile "r"]
		
		## Replace and store result
		set res [embeddedTclStream $inChannel]
		
		## Close
		close $inChannel
		
		return $res
	}
	
    ## Replace embbeded TCL between <% %> markors in source file with evaluated tcl, and writes result to outfile
    ## <% standard eval %>
    ## <%= evaluation result not outputed %>
    proc embeddedTclFromFileToFile {inputFile outputFile {caller ""}} {

            
            
        ## Open target file
        set outChannel [open $outputFile "w+"]
        set inChannel  [open $inputFile "r"]

        ## Replace and write
        #puts -nonewline $outChannel [embeddedTcl [read $inChannel]]
       
            puts -nonewline $outChannel [embeddedTclStream $inChannel $caller]
        
        
        ## Close
        close $outChannel
        close $inChannel

            
    }


    ## Process all files in inputFiles list through the embeded TCL procedure
    ## and append all results to the target outputFile
    proc embeddedTclFromFilesToFile {inputFiles outputFile} {

        ## Open target file
        set outChannel [open $outputFile "w+"]

        ## Foreach List
        ###########################
        foreach inputFile $inputFiles {
            
            ## Process input File and write to output
            set inChannel  [open $inputFile "r"]
            puts -nonewline $outChannel [embeddedTclStream $inChannel]   
            close $inChannel
            
        }
       
        ## Close Target File
        ###########################
        close $outChannel

    }
	
	proc exec {execCommand {targetChannel stdout}} {
	
		## Start Command
		set execChan [open |$execCommand]
		
		## Pull Output until finished
		while {1} {
			
			# Test end
			if {[eof $execChan]} { break; }
			
			# Output
			set line [string trim [gets $execChan]]
			puts $targetChannel $line
			
		}
		
	}

    ## A String channel usable to create custom channel that outputs into a string
    ## Usage example:
    ##      set eout [chan create "write read" "odfi::common::[StringChannel #auto]"]
    ##      puts $eout
    ##      flush $eout
    ##      read $eout
    ##      close $eout
    ##
    ##      Don't forget that read won't return the correct result if not flushed before!!
    ##
    itcl::class StringChannel {

        variable data
        variable pos

        constructor args {
            #if {$encoding eq ""} {set encoding [encoding system]}
            #set data [encoding convertto $encoding $string]
            set data ""
            set pos 0
        }

        method initialize {ch mode} {
            return "initialize finalize watch read seek write"
        }
        method finalize {ch} {
            set data ""
            set pos 0
        }

        method watch {ch events} {
            # Must be present but we ignore it because we do not
            # post any events
        }

        # Must be present on a readable channel
        method read {ch count} {
            set d [string range $data $pos [expr {$pos+$count-1}]]
            incr pos [string length $d]
            return $d
        }

        ## Must be present on write channel
        method write {channelId nData} {

            set data "$data$nData"
            return [string length $nData]
        }

        # This method is optional, but useful for the example below
        method seek {ch offset base} {
            switch $base {
                start {
                    set pos $offset
                }
                current {
                    incr pos $offset
                }
                end {
                    set pos [string length $data]
                    incr pos $offset
                }
            }
            if {$pos < 0} {
                set pos 0
            } elseif {$pos > [string length $data]} {
                set pos [string length $data]
            }
            return $pos
        }
    }

}