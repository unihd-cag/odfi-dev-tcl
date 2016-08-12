package provide odfi::errortracer 1.0.0
package require odfi::closures 3.0.0 
package require odfi::files    2.0.0 


namespace eval odfi::errortrace {

    variable all_functions {} 
  
    proc testTracer args {
        puts "Called: $args"
    }
    
    # still to implement
    proc namespaceTracer args {
    
    }
    

   
    ## Tracer for procedures
    proc procTracer args {
    
        ## Resolve proc full name
        set current_namespace [uplevel namespace current]
        set procName "[lindex [lindex $args 0] 1]"
        #puts $current_namespace
 
        
    
        ## Resolve file and line
        ## Start at -2
        ## Look for frame level with file
        ## If we find eval, add line to current line in file
        set currentLineInFile 1
        set foundFile ""
        set maxlevel [info frame]
        set level 2
        while {$level<[expr $maxlevel]} {
            
            set callerFrame [info frame -$level]
           
           # puts "---------------------"
           # puts "$callerFrame"
           
            ## If file -> finish
            ## If eval -> add line
            if {[dict get $callerFrame type]=="eval"} {
            
                
                incr currentLineInFile [expr [dict get $callerFrame line] -1]
              
            } elseif {[dict get $callerFrame type]=="source"} {
                set foundFile  [dict get $callerFrame file]
                incr currentLineInFile [expr [dict get $callerFrame line] -1]
                break
            }
            
            incr level
            
        
        }
        
        ## Clean Name
        if {$current_namespace == "::"} {
            set current_namespace ""
        } 
        
        #puts "Found $current_namespace :: $procName at $foundFile -> $currentLineInFile"
      
        lappend ::odfi::errortrace::all_functions [list ${current_namespace}::$procName $foundFile $currentLineInFile]
        
       
       return
    
    }
   
    
    ## Tracer for ::nx::Class 
    proc nxClassTracer args {
        
        #puts "NX tracer: $args"        
      
        if {[lindex [lindex $args 0] 1] == "create"} {

            set className [lindex [lindex $args 0] 2]  
            set callerFrame [info frame -2]
            set currentNamespace [uplevel namespace current]
            
            ## Resolve file and line
            ## Start at -2
            ## Look for frame level with file
            ## If we find eval, add line to current line in file
            set currentLineInFile 1
            set foundFile ""
            set maxlevel [info frame]
            set level 2
            while {$level<[expr $maxlevel]} {
                
                set callerFrame [info frame -$level]

                ## If file -> finish
                ## If eval -> add line
                if {[dict get $callerFrame type]=="eval"} {
  
                    incr currentLineInFile [expr [dict get $callerFrame line] -1]
                  
                } elseif {[dict get $callerFrame type]=="source"} {
                    set foundFile  [dict get $callerFrame file]
                    incr currentLineInFile [expr [dict get $callerFrame line] -1]
                    break
                }
                
                incr level

            }
            
            
            if {$currentNamespace == "::"} {
                set currentNamespace ""
            }
            
                       
            #puts "Creating Class ${currentNamespace}::$className -> $foundFile at $currentLineInFile"
            
            
            
            ## Looking for method
            ##  -> Split at line to easily get line number, and match line with regex to detect method definition
            set lines [split $args \n]
            set i 0
            foreach l $lines {
                #puts "Line $i: $l"
                if {[regexp {.+method\s+([\w\d:_-]+).*} $l -> mname]} {
                    #puts "Found method $mname"
                    set correct_line_number [expr {[dict get $callerFrame line] + $i}]
                    lappend ::odfi::errortrace::all_functions [list ${currentNamespace}::${className}::$mname  [dict get $callerFrame file] $correct_line_number]
                }                      
                incr i
            }

            # lappend ::odfi::errortrace::all_functions [list ${currentNamespace}::$className  [dict get $callerFrame file] [dict get $callerFrame line]]
            ## Trace execution on class name for further method definition for example
           
            #trace add execution "${currentNamespace}::${className}" enter "::odfi::errortrace::testTracer"
       }
    }
    
    trace add execution "::proc" enter "::odfi::errortrace::procTracer" 
    trace add execution "::nx::Class" leave "::odfi::errortrace::nxClassTracer"

    proc recordProcWithOutputType {name file line outputType} {
        
        #puts "Recording  $name $file $line OUTPUT $outputType"
        
        lappend ::odfi::errortrace::all_functions [list $name $file $line OUTPUT $outputType ]
    }
    
    proc recordProc {name file line} {
            
       # puts "Recording  $name $file $line"
        
        lappend ::odfi::errortrace::all_functions [list $name $file $line ]
    }

    proc getOutputType {name} {
        
        set res ""
        set index [lsearch -index 0 -exact ${::odfi::errortrace::all_functions} $name]
        if {$index>0} {
            set traceData [lindex ${::odfi::errortrace::all_functions} $index]
            set outputIndex [lsearch -exact ${traceData} OUTPUT]
            if {$outputIndex>=0} {
                set res [lindex $traceData [expr $outputIndex +1]]
                
            }
        }
        
        return $res
        
    }
    
    ## REturn not -1 only if one trace matches
    proc getSingleTraceForMethodName name {
    
        set indexes [lsearch -all -glob -index 0 ${::odfi::errortrace::all_functions} *$name] 
        if {[llength $indexes]==1} {
            return [lindex ${::odfi::errortrace::all_functions} [lindex $indexes 0]]
        } else {
            return -1
        }
    }

    proc errorToList {res option} {
        
        
       
        
        
        set stack [::odfi::closures::declosure [dict get $option -errorinfo]]
        puts $stack
        
        # save the first line of the error stack         
        set index_tmp_first [string first "\n" $stack]
        #set first_error_stack_line [list [string range $stack 0 $index_tmp_first]]
        
        ## First ENTRY in Output list is MESSAGE
        ##########
        set first_error_stack_line [string range $stack 0 ${index_tmp_first}-1]
        
        puts "first error stack line: $first_error_stack_line"

        set output_list [list [list MESSAGE "$first_error_stack_line"]]
        
        ## Next Entry is the start point in last file
        ################
        
        ## Try to determine Start where this function is called
        set callerLocation [::odfi::common::findFileLocation 3]
        puts "Start point for error list: $callerLocation"
        
        lappend output_list [list INVOKE START [lindex $callerLocation 0] [lindex $callerLocation 1] ABSOLUTELINE  [lindex $callerLocation 1]]

        ## TEST OUTPUT of all_functions
        #foreach {output} $::odfi::errortrace::all_functions {
            
        #    puts "all_functions: $output"
        #}
      
        
        #set mres [regexp -all -inline {\s*\(.+\s+"([\w\d:\._-]+)"\s+.+(\d+)\s*\)\s*(?:invoked\s+from\s+within)\s+"(.+)"\n} $stack]
        #set mres [regexp -all -inline -line {\s*\(.+\s+"([\w\d:\._+-]+)"\s+.+(\d+)\s*\)\s*(?:invoked\s+from\s+within)\s+"(.+)"\n\s*(\(.+body\s+line\s+(\d+)\)\n?)?} $stack]
        set mres [regexp -all -inline -line {\s*\(?([^\n]+)\s"?([^"]+)"?\s+line\s+(\d+)\s*\)(?:\n\s*(?:invoked\s+from\s+within)\s+"((?:[^"\(]|"[^\(]*")*)"\n\s+\()?} $stack]
        
        puts $mres
        
        
        ## TEST OUTPUT of the matched regexp
        #puts "TEST OUTPUT of the matched regexp: "
        set i 0
        set nextEntryAdd 0
        foreach {mcall line procedureName name match} [lreverse $mres] {
        
            puts "Iteration i: $i"
            #puts $match
            puts "name: $name"
            puts "Procedure: $procedureName"
            
            ## Line; add next entry value if needed
            set line [expr $line - 1 ]
            puts "line: $line"
            
            
            
            puts "called method or procedure: $mcall"
            
            #if {$invokeline!=""} {
            #    set line [expr $invokeline - 1 ]
            #}
            #puts "Invoked: $invokeline"
            
            ## Resolved name must be produced by search for this error stack level to be searched for location
            set resolvedName ""
            set resolvedType PROC
                       
            ## decide whether there is probably a method call or a procedure call
            ## if in "mcall" there is only one entry, then it is probably a procedure call.
            ## if there are more than one entries in "mcall" then it is probably a method 
            ## call. In this case "name" and "mcall" at position one have to be equal.
            ## 
            
            ## Cases: 
            ##    - called name : $name
            ##    - calling code: {NAME args}
            ##
            ##  a) PROC                     
            ##         ->  $name == NAME and $name is like "test" or "::ns::path::test"  
            ##  b) METHOD on unknown object ->
            ##         ->  $name == NAME  and $name is like ":test" but not like
            
           
            
            if {$procedureName=="body"} {
                
                ##
                ## - If procedureName is body, then we are just following
                ##
                
                puts "-- Just follow the call to $name on line $line from current location"
                set resolvedType FOLLOW
                set resolvedName $name
                
            } elseif {[lsearch -exact $mcall $procedureName] == 0} {
            
                ##
                ## -  If Calling code starts with function, it is a procedure if the name can match a procedure
                ##
                
                puts "-- There was probably a procedure/method call."

                ## Search as global procedure
                set searchName $procedureName
                if {![string match "::*" $searchName]} {
                       set searchName "::$searchName"
               }
               
               ## Get index in tracer data
               set search_index_name [lsearch -index 0 -exact $::odfi::errortrace::all_functions $searchName]
              
               ## If found -> happy
               ## If not found:
               ##   -> If previous entry in result list is OBJECT, then try to use its data
               if {$search_index_name>=0} {
                    
                    ## Proc Found
                    puts "--- Found "
                    set resolvedName "$searchName"
                    set resolveType  INVOKE
                    
               } elseif {[llength $output_list]>1} {
                
                    set latestError [lindex $output_list end]
                    if {[lindex $latestError 0]=="OBJECT"} {
                        
                        puts "--- We are in a method call, and previous call was in an object"
                        
                        ## OBJECt name entry has class::path::method, so split and join to get only the class path
                        set resolvedName "[join [lrange [split [lindex $latestError 1] :] 0 end-2] :]:$name"
                        set resolvedType "OBJECT"
                        puts "Target Name: $resolvedName"
                        
                    } elseif {[lindex $latestError 0]=="BUILD"} {
                    
                        puts "--- Previous Error was on error build"
                        
                        ## Get all builders
                        set buildingType [lindex $latestError 1]
                        set builders [$buildingType +builders get]
                        if {[llength $builders]==1} {
                        
                            set builderFullName "${buildingType}::builder0"
                            puts "--- There is only one builder, so pretty easy to figure out: $builderFullName"
                            
                            set resolvedName ${buildingType}::builder0
                            set resolvedType BUILD
                        
                        }
                    
                    } else {
                        
                        puts "--- Previous element in list does not help for this function "
                        
                    }
               
               } else {
               
                    puts "-- Cannot find $searchName"
                    lappend output_list [list INVOKE $searchName -1 -1]
                    
               }
               
                #puts $name
                
                # search the index within the result mres from the regexp expression
                # Get Function location from error namespace if found
                
                #puts $search_index_name
                
                
            
            } elseif {[lsearch -exact $mcall $procedureName] == 1} {
                
                ##
                ## -  If Calling code has procedure as seconde element; like: object procedureName , look for an object call
                ##
                
                puts "There was probably a method call on object."
                
                
                ## We have a method call, we should find on which object
                ##  -> Object is probably to be found in "invoked from within" calling code (mcall)
                ##  -> $mcall has the format {OBJECT METHOD ARGUMENTS} -> get index 0 which will be the variable name holding the object
                ##  -> OBJECT could be a variable if starts with "$", or it could be the name of the object if it looks like "::xxxx"
                ##  -> if OBJECT is a variable name, this error parsing should be close enough to error source to still be able to find the variable
                set objectName [lindex $mcall 0]
                if {[string match "\$*" $objectName]} {
                    
                    set objectVariableName [string range $objectName 1 end]
                       
                    puts "Object is held in variable: $objectVariableName"
                    
                    ## Looking for variable b, which should be in the level or higer
                    ## Use the closure resolver to find it 
                    ## If a value if found: check it is an object, and check it has the method we are looking for
                    ## This is a double check to make sure we are not finding something in the wrong location
                    if {[catch {::odfi::closures::value $objectVariableName} object]} {
                    
                        ## Handle constructor builder case
                        ## if call name is +build, and previous call is a method with output type, it might be the one
                        if {$procedureName=="+build"} {
                            
                            set previousCall [lindex $output_list end]
                            set outputType   [::odfi::errortrace::getOutputType [lindex $previousCall 1]]
                            puts "---Previous call is: $previousCall -> $outputType"
                            if {$outputType!=""} {
                                puts "--- In constructor and type has been found"
                                
                                ## Record something special
                                lappend output_list [list BUILD $outputType [lindex $previousCall 2] 0  ABSOLUTELINE [lindex $previousCall end]]
                                #continue
                            }
                        
                        } else {
                            puts "---Sadly, variable $objectVariableName cannot be found, cannot resolve this error"
                            continue
                        }
                    
                        
                        
                        
                    } else {
                        puts "---The object has been found: $object"
                        
                        ## Recheck object for method
                        if {[::odfi::common::objectHasMethod $object $procedureName]} {
                            puts "Object seems ok and is [$object info class]"
                            set resolvedName [$object info class]::$procedureName
                            set resolvedType  OBJECT
                        }
                        
                    }
                    
                    
                    
                } else {
                    puts "!!! in object call case resolution, method call $mcall is not recognised !!!"
                }
                               
               
                
                
              
                
            } else {
            
                puts "ERROR!"
                puts "Neither a procedure nor a method call could be matched for $procedureName"
                puts "Try a lucky find"
                set traceRes [::odfi::errortrace::getSingleTraceForMethodName $procedureName]
                if {$traceRes!=-1} {
                    puts "It seems only one entry has this method name -> $traceRes"
                    
                    set resolvedName [lindex $traceRes 0]
                    set resolvedType PROC
                    
                }
                
                
            }
            
            ## Search for location based on resolved name and type
            #################
            if {$resolvedType=="FOLLOW"} {
            
                ## Follow, just add the line to the previous one
                set actualAbsoluteLineIndex [lsearch -exact [lindex $output_list end] ABSOLUTELINE]
                if {$actualAbsoluteLineIndex>=0} {
                    set absoluteLine [lindex [lindex $output_list end] [expr $actualAbsoluteLineIndex+1]]
                } else {
                    set absoluteLine $line
                }
                
                ## Save line for next entry, add current next entry add to absolute line
                incr absoluteLine $nextEntryAdd
                set nextEntryAdd $line
                
                ## ADD Entry
                lappend output_list [list $resolvedType $resolvedName [lindex $output_list {end 2}] $line ABSOLUTELINE $absoluteLine ]
                
                
                
            
            } elseif {$resolvedName!=""} {
                
                ## Ensure fully qualified
                if {![string match "::*" $resolvedName]} {
                    set resolvedName "::$resolvedName"
                }
                
                ## Look in tracer list
                set tracerLocationIndex [lsearch -index 0  -exact $::odfi::errortrace::all_functions $resolvedName]
                if {$tracerLocationIndex>=0} {
                    
                    set traceData [lindex $::odfi::errortrace::all_functions $tracerLocationIndex]
                    
                    
                    ## Line Resolution
                    set relativeLine $line
                 
                    
                    puts "--- resolution of  [lindex $traceData 2 ]"
                    
                    ## If not invoke or else, take trace data line to calculate absolute
                    set absoluteLine [expr [lindex $traceData 2 ] + $relativeLine] 
                    if {$resolvedType=="INVOKE"} {
                        
                        set actualAbsoluteLineIndex [lsearch -exact [lindex $output_list end] ABSOLUTELINE]
                        if {$actualAbsoluteLineIndex>=0} {
                            set absoluteLine [lindex [lindex $output_list end] [expr $actualAbsoluteLineIndex+1]]
                            incr absoluteLine $relativeLine
                        }
                    } 
                    
                    ## REset next entry add
                    incr absoluteLine $nextEntryAdd
                    set nextEntryAdd 0
                    
                    ## TYPE NAME FILE LINEINFILE+ERRORLINE
                    lappend output_list [list $resolvedType $resolvedName [lindex $traceData 1 ] $relativeLine ABSOLUTELINE $absoluteLine ]
                    
                } else {
                    puts "$resolvedName cannot be found in tracer data"
                    lappend output_list [list $resolvedType $resolvedName -1 -1 ]
                }
            }
            
            
            #puts "total output_list:"   
            #puts $output_list
            incr i
            
            puts ""
            
        }
        return $output_list
   
    }   
        


    proc printErrorList {output_list} {
    
        # Output of output_list
        # the first line of the error stack will be always printed
        set errorMessage [lindex $output_list 0]
        set errorStack   [lrange $output_list 1 end]
        
        puts [lindex $errorMessage 1]
        set i 0
        foreach stackData $errorStack {
            
            ::extractVars $stackData type name file line_number kw absoluteLine
            
            if {$type!="INVOKE"} {
                #continue
            }
            
            set tab [join [lrepeat $i "  "]]
            if {$i>0} {
              set tab "$tab|"
            }
            
            puts stderr "${tab}---> on  $name $type , in (file \"$file\" line $absoluteLine)" 
            incr i
            #error "rrr"
        }
        
        ## Hints
        ::odfi::errortrace::errorHints $errorMessage $errorStack
    }
    
    ## Try to give some more error hints
    ############
    proc errorHints {message stack} {
        
        ::extractVars [lindex $stack end] type name file line_number kw absoluteLine
        
        ## Regexps
        ###############
        
        set cantReadVariable {"([\w\d\.:_-]+)"\s*:\s+no\s+such\s+variable}
        
        ## Tests
        ############
        set hint ""
        set efile [lindex [lindex $stack end] 2]
        set line  [lindex [lindex $stack end] 3]
        if {[regexp $cantReadVariable $message -> varName]} {
            
            ## Get location of error in line
            set lineInFile [string trim [::odfi::files::getFileLine $efile $absoluteLine]]
            set varNamePosInLine [string first $varName $lineInFile]
            
            ## Create String to point out error
            set showString "[string map {__ _} [join [lrepeat [expr $varNamePosInLine-1] _ ] _]]/^\\____Right there"
            
            lappend hint "You are using a variable called $varName which does not exist, maybe you have a typo?"
            lappend hint "Check:"
            lappend hint "$lineInFile"
            lappend hint "$showString"
        }
        
        ## Print
        ################
        if {$hint!=""} {
            puts ""
            ::odfi::common::println "A resolution hint was found for this error:"
            ::odfi::common::printlnIndent
            ::odfi::common::println "On (file \"$efile\" line $absoluteLine)"
            foreach h $hint {
                ::odfi::common::println $h
            }
            
            ::odfi::common::printlnOutdent
        }
        
    }
    
    proc printErrorListReverse {output_list} {
    
        set i 0
          foreach {line_number file name} [lreverse [lrange $output_list 1 end]] {
          
              set tab [join [lrepeat $i "  "]]
              if {$i>0} {
                set tab "$tab^"
              }
              puts stderr "${tab}--- on  $name , in (file \"$file\" line $line_number)" 
              incr i
              #error "rrr"
          }
    
    }

# end of namespace odfi::errortrace
}




