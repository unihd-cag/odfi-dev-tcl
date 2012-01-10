package provide odfi.common 1.0.0

namespace eval odfi::common {
	

	# Handle request for a single argument
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
	
	
	
	# This method replaces all ${VAR} bash-like env variable with the $::env(VAR) TCL syntax
	proc resolveEnvVariable src {
        
        global env
        
		set res [regsub -all {\$\{?([A-Z_0-9]*)\}?} $src {$::env(\1)}]
		eval return $res
		
		
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
    

}