package provide odfi::richstream 3.0.0
package require odfi::closures 3.0.0


namespace eval odfi::richstream {

    
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

        ## With no new line 
        set ::eout "$::eout[join [lrange $args 1 end]]"

      } else {

        ## With newline 
        set ::eout "$::eout[join $args]\n"

      }
      
    }

    ## Same as puts above, but with non standard TCL method name
    proc streamOut args {
      #::puts $::eout args
      if {[lindex $args 0] == "-nonewline"} {

        ## With no new line 
        set ::eout "$::eout$args"

      } else {

        ## With newline 
        set ::eout "$::eout$args\n"

      }
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
            set execLevel [lindex $args [expr [lsearch -exact $args "-execLevel"]+1]]
        }

        set caller ""
        if {[lsearch -exact $args "-caller"]>-1} {
                    set caller [lindex $args [expr [lsearch -exact $args "-caller"]+1]]
            }

        set tag "<%%>"
        if {[lsearch -exact $args "-tag"]>-1} {
                set tag [lindex $args [expr [lsearch -exact $args "-tag"]+1]]
        }

        #set resultChannel [chan create "write read" [::new odfi::common::StringChannel #auto]]
        set resultChannel ""

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
                    #::puts -nonewline $resultChannel $token
                    set resultChannel "$resultChannel$token"
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
                    set ::eout ""
                    set eout $::eout
                    
                    #set ::eout [chan create "write read" [::new odfi::common::StringChannel #auto]]
                    #set eout $::eout
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
                    if {[catch {set evaled [string trim [odfi::closures::doClosureToString $script $execLevel]]} res]} {

                        ## This may be a variable, just output the content to eout
                        #::puts "Invalid command ($res), doing error"

                        ## Get Error Line 
                        #set errorLine [dict get $resOptions -errorline]
                        #set errorLineContent [lindex [split $resolvedClosure "\n"] $errorLine]

                        #::puts "(ETCL) Detected ERROR at line $errorLine:"
                        #::puts " Line: $errorLineContent / $lineStateBeforeClosure"
                        #::puts " Closure: $script"
                        #::puts "[dict get $resOptions -errorinfo]"

                        error "Embedded TCL error in $script"
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
                    #flush $eout
                    set output $::eout
                    #close $eout

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
                    set resultChannel "$resultChannel$evalResult"
                    #::puts -nonewline $resultChannel $evalResult

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
                set resultChannel "$resultChannel$token"
                #::puts -nonewline $resultChannel $token
            }

            ## Read next token
            #############
            set token [read $dataStream 1]
        }

        ## Output result
        #######################
        #flush $resultChannel
        #set result [read $resultChannel]
        #close $resultChannel
        set result $resultChannel

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
    
}
