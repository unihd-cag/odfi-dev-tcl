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

package provide odfi::closures 2.0.0
package require odfi::common


## \brief Closures utilities namespace
namespace eval odfi::closures {

    ## \brief Executes command in args, into +1 exec level, and add result  as string  to eRes variable available in the +1 exec also
    proc push args {

        set tRes "[uplevel 1 $args]"

        #puts "Will push on result list: $tRes"

        uplevel 1 "lappend eRes {$tRes}"
        set newLength [uplevel {llength $eRes}]
        set upns [uplevel {namespace current}]
        #lappend eRes {$tRes}

        #puts "Pushed on result list,which is now: $newLength , and in ns: $upns, frame: [uplevel info frame]"

    }

    ## \brief Executes command in args, into +1 exec level, and add result  as string  to eRes variable available in the +1 exec also
    proc + args {

       
        uplevel 1 "lappend eRes $args"
        

    }

    # Enable simple puts in TclStreams
    ########
    proc puts args {
      #::puts $::eout args
      if {[lindex $args 0] == "-nonewline"} {
        set NNL "-nonewline"
        set args [lreplace $args 0 0]
      } else {
        set NNL ""
      }
      uplevel ::puts $NNL $::eout $args
    }

    ## Same as puts above, but with non standard TCL method name
    proc streamOut args {
      #::puts $::eout args
      if {[lindex $args 0] == "-nonewline"} {
        set NNL "-nonewline"
        set args [lreplace $args 0 0]
      } else {
        set NNL ""
      }
      uplevel ::puts $NNL $::eout $args
    }


    ## Replace embbeded TCL between <% %> markors in data with evaluated tcl
    # <% standard eval %>
    # <%= evaluation result not outputed %>
    # @warning Closure base execution level is 1, not 0 (so not this function's level)
    # @return resulting stream
    proc embeddedTclStream {dataStream args} {

        ## Extract Parameters
        ########################################

    	set execLevel 1
    	if {[lsearch -exact $args "-execLevel"]>-1} {
    		set execLevel [lindex $args [lsearch -exact $args "-execLevel"]+1]
    	}

    	set caller ""
    	if {[lsearch -exact $args "-caller"]>-1} {
                    set caller [lindex $args [lsearch -exact $args "-caller"]+1]
            }

    	set tag "<%%>"
    	if {[lsearch -exact $args "-tag"]>-1} {
                set tag [lindex $args [lsearch -exact $args "-tag"]+1]
        }

        set resultChannel [chan create "write read" [::new odfi::common::StringChannel #auto]]

        #::puts "##################################################In Closure embedded stream: $dataStream: [read $dataStream]"

        ## Stream in the data, and gather everything between <% ... %> an eval
        ################

        set token [read $dataStream 1]
        set gather false
        set script ""
        while {[string length $token]==1} {

            #puts "Doing token : $token"
            ## Gather / Eval
            ########################

            #### If <%, gather
            if {$gather == false && $token==[string index $tag 0]} {

                ## If % -> We can start
                set nextChar [read $dataStream 1]
                if {$nextChar== [string index $tag 1]} {
                    set gather true
                    #::puts "gathering"

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
                    ::puts -nonewline $resultChannel $token
                    #puts -nonewline $resultChannel $nextChar
                    set token $nextChar
                    continue
                }

            } elseif {$gather==true && $token == [string index $tag 2] } {

                #### If %>, eval
                set nextChar [read $dataStream 1]
                if {$nextChar==[string index $tag 3]} {

                    set gather false
                    #::puts "stopped gathering"

                    ## Prepare a Channel
                    ############################
                    set ::eout [chan create "write read" [::new odfi::common::StringChannel #auto]]
                    set eout $::eout
                    #::puts "Eval closure: $script "

                    ## Export :
                    ##   - puts if not in toplevel namespace
                    ##   - streamOut
                    if {[uplevel $execLevel "namespace current"]!="::"} {
                        namespace   export puts
                        uplevel $execLevel "namespace import -force [namespace current]::puts"
                    }
                    namespace  export streamOut
                    uplevel $execLevel "namespace import -force [namespace current]::streamOut"

                    ## Eval Script
                    ###########################
                    set script [string trim $script]

                   # puts "Calling closure"
                    if {[catch {set evaled [string trim [odfi::closures::doClosureToString $script $execLevel]]} res resOptions]} {

                        ## This may be a variable, just output the content to eout
                        #::puts "Invalid command ($res), doing error"

                        ## Get Error Line 
                        set errorLine [dict get $resOptions -errorline]
                        #set errorLineContent [lindex [split $resolvedClosure "\n"] $errorLine]

                        #::puts "(ETCL) Detected ERROR at line $errorLine:"
                        #::puts " Line: $errorLineContent / $lineStateBeforeClosure"
                        #::puts " Closure: $script"
                        #::puts "[dict get $resOptions -errorinfo]"

                        error "Embedded TCL error" [dict get $resOptions -errorinfo]
                        #$res [dict get $resOptions -errorinfo]

                        #puts "- Error While evaluating script $script. $res"

                    }

                    ## Restore original puts command if needed
                    ## Deexport streamOut
                    #########
                    if {[uplevel $execLevel "namespace current"]!="::"} {
                        uplevel $execLevel "rename puts \"\""
                    }
                    uplevel $execLevel "rename streamOut \"\""

                    ## If evaluation output is to be ignored, set to ""
                    ########
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

                    #puts "Closure result: $evalResult"

                    ## Output to result string
                    ::puts -nonewline $resultChannel $evalResult

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
                ::puts -nonewline $resultChannel $token
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

    ## Replace embbeded TCL between <% %> markors in source string with evaluated tcl, and returns the result as a string
    ## <% standard eval %>
    ## <%= evaluation result not outputed %>
    proc embeddedTclFromStringToString {inputString {caller ""}} {

        ## Open source file
        set inChannel  [odfi::common::newStringChannel $inputString]

        ## Replace and store result
        set res [embeddedTclStream $inChannel -execLevel 2 -caller $caller]

        ## Close
        close $inChannel

        return $res
    }

    ## Replace embbeded TCL between <% %> markors in source file with evaluated tcl, and returns the result as a string
    ## <% standard eval %>
    ## <%= evaluation result not outputed %>
    proc embeddedTclFromFileToString {inputFile {caller ""}} {

        ## Open source file
        set inChannel  [open $inputFile "r"]

        ## Replace and store result
        set res [embeddedTclStream $inChannel -execLevel 2 -caller $caller]

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

            ::puts -nonewline $outChannel [embeddedTclStream $inChannel -execLevel 2 -caller $caller]


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
            ::puts -nonewline $outChannel [embeddedTclStream $inChannel -execLevel 2]
            close $inChannel

        }

        ## Close Target File
        ###########################
        close $outChannel

    }


    ## \brief Evaluates a closure and make magic for variables to be resolvable
    # Returns the result of the closure
    # The executed closure can call the special "push" method to add result to a result list.
    # If the result list is not empty after evaluation, its content is returned as result
    # @return The last executed command in the closure, or the result list if the push command has been used
    proc doClosure {closure {execLevel 0} {resolveLevel 0}} {

        #puts "Evaluating closure $closure"



        set closureString "$closure"

        ## Level:
        ## - This is a utility proc, so level 1 is the caller.
        ## - So call level provided by caller must then be +1 to hide this procedure level
        ###################
        set execLevel [expr $execLevel+1]

        ## Resolution:
        ##  - Resolve variables in caller asked level +1
        ##  - Execute in caller asked level
        ###################
        set resolveLevel [expr $execLevel+1]

        ## list of all upvaring to prepend to closure
        set requiredUpvars {}

        ## After closure code to be evaluated, used to unlink variables and so on 
        set afterClosure {}


        ## Iterators variable "it" management
        ## Before closure -> save if exists in execlevel
        #######################
        set savedIterator ""
        if {![catch [list uplevel $execLevel set it] res]} {
            ## Found
            #::puts "Saved iterator with value $res"
            set savedIterator $res
            #catch [list uplevel $execLevel [list unset -nocomplain it]]
        }
  

        #puts "Search into [llength $closure]"

        #puts "Exploring closure **************************"

        #foreach scriptElement [split $closureString { }] {

            ## Search for all variables
            ## Search for special alls, like "incr"
            ############
            #puts "**** Exploring $scriptElement"
            set vars [regexp -all -inline {(?:\$[a-zA-Z0-9:\{_]+\}?)|(?:incr [a-zA-Z0-9:_]+)} $closureString]

            
            #set incr [regexp -all -inline {\$[a-zA-Z0-9:\{_]+\}?} $closureString]

            ## Clean var names
            set cleanedVars {}
            set vars [lsort -unique $vars]
            foreach var $vars {
                set var [string trim $var]

                ## Clean var name 
                if {[string match "incr*" $var]} {
                    set var [regsub -all {.*incr\s+(.+)} $var "\\1"]
                } else {
                    set var [string trim [string range $var 1 end]]
                    set var [regsub -all {\{|\}} $var ""] 
                }

                ## Store without duplicates
                lappend cleanedVars $var
            }

            ## Remove duplicate
            set cleanedVars [lsort -unique $cleanedVars]

            foreach var $cleanedVars {

                #::puts "(CL) Found variable : $var"

                ## Ignore variables that are an explicit namespaced reference
                ##############

                ### Ignore certain patterns
                ## Why it was there ? "it" {continue}
                set ignores {

                    "::*" {continue}
                    "this" {continue}


                }
                switch -- $var $ignores
                #if {[string match "::*" $var] || $var=="this"} {
                #    continue
                #}

                #puts "Not ignored variable : $var"

                ### If variable is global, also ignore
                #if {[catch [list set ::$var] res]==0} {
                #    continue
                #}


                ## Search for variable in:
                #############
                set local               false
                set callerExec          false
                set callerExecUp        false
                set searchResolveLevel  $resolveLevel
                #set searchResolveLevel  1

                ### 1: Closure level -> Do nothing
                set exp "set $var .+\$"
                set localSearchResults [regexp -all -inline -line $exp $closureString]
                if {[llength $localSearchResults]>0} {

                    ## This is only true, if in none of the set expressions, the variable is used right
                    ## Ex: set var "${var}_var" should lead to an upvar
                    set validLocal true
                    foreach localResult $localSearchResults {

                        #::puts "Checking local variable $var validity against set expression: $localResult"

                        if {[regexp "set $var .*\\\$$var.*" $localResult]>0} {

                           # ::puts "Variable should be upvared"
                            set validLocal false
                            break
                        }

                    }


                    #puts "-- Variable $var is defined in local"
                    if {$validLocal==true} {
                        set local true
                        continue
                    } else {
                        set local false
                    }


                } else {

                    #puts "Explored /$exp/ in closure string /$closureString/"

                }

                ##### 2: Caller Level -> Do nothing
                #if {$var!="it" && [catch [list uplevel $execLevel set $var] res]} {

                    #puts "-- Variable $var not found in execlevel upvar ($execLevel)"

                #} elseif {$var!="it"} {

                   # ::puts "-- Variable $var was found in execlevel upvar ($execLevel)"

                #    set callerExec true
                    #set requiredUpvars [concat upvar [expr $execLevel] $var $var $requiredUpvars]
                    #lappend requiredUpvars "upvar $execLevel $var $var"
               # }

                ### 3: Caller +1 level -> upvar
                 if {$callerExec==false} {

                    ##::puts "**** Start Search at uplevel [uplevel $resolveLevel info level]"

                    ## Start Searching at 1, meaning where the doClosure call is located, to allow resolution of local variables
                    set searchResolveLevel 1
                    while {[catch "uplevel $searchResolveLevel info level"]>=0} {

                        #::puts "**** Search $var at uplevel $searchResolveLevel [uplevel $searchResolveLevel namespace current]"

                        ## Test
                        if {[catch [list uplevel $searchResolveLevel set $var] res]} {
                            ## not found
                        } else {
                            ## Found
                            #puts "********* Found $var at $searchResolveLevel"
                            set callerExecUp true

                            ## If Resolve level is < execution level, just get variable value, because upvar won't work (down var is not possible)
                            ## After Closure execution, unlink to variable to ensure it won't be seen as already resolved for a subsequent call
                            if {$searchResolveLevel<$execLevel} {
                                ##set requiredUpvars [concat set $var $var ";" $requiredUpvars]
                                
                                #::puts "Resolved var $var at lower exec level as requested one, setting to $res"
                                
                                if {[llength $res]>1} {
                                   # ::puts "-- Setting as string because length > 1 "
                                   uplevel $execLevel "set $var \"$res\""
                                    #::puts "-- Done"
                                } else {
                                   # ::puts "-- Setting value as it is"
                                    uplevel $execLevel "set $var $res"
                                    #::puts "-- Done"
                                }
                                
                                #set afterClosure [concat uplevel $execLevel unset -nocomplain $var ";" $afterClosure]
                            } else {
                                #::puts "(CL) Found var $var at level [expr $searchResolveLevel-$execLevel]"
                                set requiredUpvars [concat [list catch [list upvar [expr $searchResolveLevel-$execLevel] $var $var]] ";" $requiredUpvars]
                            }

                            
                            break
                        }

                        incr searchResolveLevel

                        ## Breaking because can'T search anywhere else
                        if {[expr [info level]-$searchResolveLevel]<0} {
                            break
                        }

                    }

                 }
                 ## EOF uplevels search


                ## Verify Compatibilities
                ##########################

                ## If More than one level has true defined, there is a conflict
                if {$local==true && [llength [lsearch -all -exact [list $callerExec $callerExecUp] true]]>1} {

                    error "Variable $var has been found defined in some up level, and local closure, there will probably be some conflicts:
                            - Found in closure $local
                            - Found in Closure Caller execution level $callerExec
                            - Found in Closure Caller execution level +1 $callerExecUp
                    "

                } elseif {[lsearch -exact [list $local $callerExec $callerExecUp] true]==-1} {
                    #odfi::common::logWarn "Variable $var seems not to be resolvable:
                    #        - Found in closure $local
                    #        - Found in Closure Caller execution level $callerExec
                    #        - Found in Closure Caller execution level +1 $callerExecUp
                    #"
                }

            }
        #}




        

        ## Evaluate closure
        #########################
        #::puts "Going to evaluate"

        ## Prepare result creation
        ###########
        namespace   export push
        namespace   export +
        uplevel     $execLevel "set eRes {}"

        ## (imports are forced, because if doClosure is in a loop, push and + may be imported multiple times, causin and error)
        uplevel     $execLevel "namespace import -force [namespace current]::push"
        uplevel     $execLevel "namespace import -force [namespace current]::+"


        ## Try to detect possible errors in closure
        ###############

        ## If starts with a " or a $ , add a return because it is only a string
        set firstChar [string index [string trim "$closure"] 0]
        if {$firstChar=="\"" || ($firstChar=="\$" && ![string match "* *" $closure])} {

            #puts "use subst to resolve closure as string"
            set closure [concat return $closure]
        }

        ## Run And catch error
        ##########
        set error ""
        #puts "eval from do closure"
        set evaledRes ""

        #::puts "Evauating closure  [concat $requiredUpvars $closure ]"
        set resolvedClosure [concat $requiredUpvars $closure]
        set lineStateBeforeClosure [dict get [info frame -$execLevel] line] 

        ::puts "Evauating closure $resolvedClosure"

       # set resolvedClosure "set scriptToRun \"[concat $requiredUpvars $closure]\"
       #     if {\[catch {$requiredUpvars  $closure} cRes cResOptions\]} {
#
        #         set errorLine \[dict get \$cResOptions -errorline\]
       #          set errorLineContent \[lindex \[split \$scriptToRun \"\n\"\] \[expr \$errorLine-2\]\]
        #        ::puts \"Embedded Detected ERROR at line: \$errorLine\"
        #        ::puts \"Embedded Location: \$errorLineContent\"
        #        ::puts \"Complete closure: \$scriptToRun\"
         #   }
        #"


        catch {set evaledRes [uplevel $execLevel $resolvedClosure]} res resOptions

        #::puts "Done closure evaluation"
        set returnCode [dict get $resOptions -code]
        #::puts "Error code: $returnCode (res: $evaledRes)"
        if {$returnCode==2} {

            ## TCL_RETURN is ok
            #eval $afterClosure
            #::puts "Detected TCL return code:"
            set evaledRes $res 
            

            ## Propagate error 
            ##::puts "Propagate error for closure $closure ($evaledRes)"
            ##error $res   
        } elseif {$returnCode!=0} {

            ## Get Error Line 
            #set errorLine [dict get $resOptions -errorline]
            #set errorLineContent [lindex [split $resolvedClosure "\n"] $errorLine]

            ## ERROR 
            eval $afterClosure
            #::puts "Detected ERROR at line $errorLine:"
            #::puts " Line: $errorLineContent / $lineStateBeforeClosure"
            #::puts " Closure: $resolvedClosure"
            #::puts "[dict get $resOptions -errorinfo]"

            ## Save normal error 
            set error $res  

            ## Save improved error
        }


        ## After Closure code
        ##############
       # ::puts "Done error checking"

        ## After Closure -> Restore iterator variable if necessary, or delete
        ##################
        if {$savedIterator!=""} {

            #::puts "Restoring iterator to $savedIterator"
            if {[llength $res]>1} {

                uplevel $execLevel "set it \"$savedIterator\""

            } else {

                uplevel $execLevel "set it $savedIterator"
            }
            
        } else {
            catch [list uplevel $execLevel [list catch {unset -nocomplain it}]]
        }
       
        #::puts "Doing afterClosure: $afterClosure"
        eval $afterClosure

        ## Report Error 
        #########################
        if {$error != ""} {
            error $error
        }

        #if {[catch {set evaledRes [uplevel $execLevel [concat $requiredUpvars $closure ]]} res resOptions]} {

         #   if {$firstChar=="\"" || $firstChar=="$"} {

                #puts "use subst to resolve closure as string"
         #       set closure [concat return $closure]
         #       set evaledRes [uplevel $execLevel [concat $requiredUpvars $closure ]]
         #   } else {
               #error $res [dict get $resOptions -errorinfo]
         #      error $res
         #   }

       # }





        ## If eRes list is not empty, used it as result
        #############
        set upns [uplevel $execLevel {namespace current}]
        set eResLength [uplevel $execLevel {llength $eRes}]
        #puts "Closure evaluated, eRes is in namespace $upns, has length: $eResLength , frame: [uplevel $execLevel info frame] "
        #upvar $execLevel eRes eRes
        if {$eResLength>0} {
           # puts "Result for closure: $eRes"
            set evaledRes [uplevel $execLevel {concat $eRes}]
            #puts "Result for closure: $evaledRes"
        }

        #::puts "Done $evaledRes"
        return $evaledRes


    }

    ## \brief Calls doClosure, and join result using a character. " " per default
    proc doClosureToString {closure {execLevel 0} {resolveLevel 0}} {

        set result [odfi::closures::doClosure $closure [expr $execLevel+1] [expr $resolveLevel+1]]

        ## Take First result of list, if only one
        if {[llength $result]==0} {
            set result [lindex $result 0]
        }

        #return [join $result " "]

        return [regsub -all "(\}|\{)" $result ""]

    }

    ## \brief Calls doClosure, and join result using a character. " " per default
    proc doFile {closureFile {execLevel 0} {resolveLevel 0}} {

        if {[file exists $closureFile]} {

            ## Read
            set closure [odfi::common::readFileContent $closureFile]
            return [odfi::closures::doClosure $closure [expr $execLevel+1] [expr $resolveLevel+1]]
        } else {
            return ""
        }

    }

    ######################################
    ## Closure Preparation without execution ?? 
    #######################################

    


    #####################################
    ## New Control Structures
    #####################################

    ## Executes the closure count times, with $i variable updated
    proc ::repeat {count closure} {

        ## Preserve existing i variable
        uplevel {
            unset -nocomplain i_backup
            if {[info exists i]} {
                set i_backup $i
            }
        }

        for {set i 0} {$i<$count} {incr i} {

            uplevel "set i $i"
            odfi::closures::doClosure $closure 1

        }

        ## Restore i if necessary
        uplevel {
            if {[info exists i_backup]} {
                set i $i_backup
            }
        }

    }

}
