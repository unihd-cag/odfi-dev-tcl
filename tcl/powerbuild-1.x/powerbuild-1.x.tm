package provide odfi::powerbuild 1.0.0
package require odfi::language 1.0.0
package require odfi::log 1.0.0
package require odfi::os 

namespace eval odfi::powerbuild {


    odfi::language::Language default {

        :config name {
            +exportTo Config
            +exportToPublic
            +expose name

            +var ignore false

            +method getFullName args {
                if {[:isRoot]} {
                    return [:name get]
                } else {
                    return [:formatHierarchyString {$it name get} -]-[:name get]
                }
            
            
            }
            


            :task name {
                +expose name
            }

            :phase name {
                +expose name

                :requirements {
                    :package name {
                        +var version ""
                    }
                }

                :do script {

                }

                ## Run 
                +method run directory {

                    odfi::log::info "Running Phase from [pwd]"
                    ## Do Requirements 
                    :shade odfi::powerbuild::Requirements eachChild {

                        ## Package 
                        $it shade odfi::powerbuild::Package eachChild {
                            {package i} => 

                                switch -glob -- "[odfi::os::getOs]" {

                                    linux.debian {
                                        odfi::log::info "Package requirement [$package name get]"
                                        set res [exec aptitude show [$package name get]]

                                        ## Look for state 
                                        #puts "res $res"
                                        regexp -line {^State:\s+(.+)$} $res -> state
                                        odfi::log::info "State $state"

                                        ## test 
                                        if {$state=="not installed"} {
                                            if {[catch {exec sudo aptitude -y install [$package name get]}]} {
                                                error "Could not install package [$package name get]"
                                            }
                                        } else {
                                            odfi::log::info "Package present"
                                        }
                                    }

                                    linux.arch {
                                        #::odfi::powerbuild::exec sudo pacman -S [$package name get]
                                        
                                    }
                                }

                                

                        }
                    }

                    ## Run scripts 
                    :shade odfi::powerbuild::Do eachChild {
                        eval [$it script get]
                    }
                      

                }
            }


            ## Building 
            ##################
            +method runPhase {name directory} {

                ## Ignore if requested
                if {${:ignore}} {
                    return
                }

                :shade odfi::powerbuild::Phase eachChild {
                  
                    if {[$it name get]==$name} {
                       
                        $it run $directory
                    }
                }
                

            }
            +method build {targetMatch phase {buildDirectory build} } {


                set availablePhases {
                    init 
                    generate-sources
                    compile 
                    package
                    deploy
                }
                if {$phase==""} {
                    set phase deploy

                }
                set targetPhaseIndex [lsearch -exact $availablePhases $phase]

                ## prepare build folder 
                set buildDirectory [pwd]/$buildDirectory

                odfi::log::info "Build Directory is $buildDirectory , with filter $targetMatch and phase $phase"

                :shade odfi::powerbuild::Config walkDepthFirstPreorder {

                    odfi::log::info "Testing node [$node getFullName]"
                    if {[string match *$targetMatch [$node getFullName]]} {
                        

                        ## Set Build Folder 
                        set buildFolder $buildDirectory/[$node getFullName]
                        file mkdir $buildFolder

                        odfi::log::info "Building [$node name get] in $buildFolder"

                        set __current [pwd]
                        cd $buildFolder
                        try {
                            ## Run Phases and requirements
                            set allNodes [[$node getPrimaryParents]  += $node]

                            
                            foreach currentPhase $availablePhases {

                                ## stop if too far 
                                if {[lsearch -exact $availablePhases $currentPhase]>$targetPhaseIndex} {
                                    break
                                }

                                ## Otherwise run
                                odfi::log::info "*** Entering Phase $phase ***"
                                $allNodes foreach {
                                    $it runPhase "$currentPhase" $buildFolder
                                }
                            }
                        } finally {
                            cd ${__current}
                        }
                        

                    }
                }
            }
        }
    }
    ## EOF Language 


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
                set odfi::powerbuild::eofexec true
               # puts "In Exec eof channel "
            }
        }
        

    }

    ##
    proc exec args {


        set monitorProcess [open "|$args 2>@1" r]
        fconfigure $monitorProcess -blocking 0

        puts "Setup file event"
        fileevent $monitorProcess readable  [list odfi::powerbuild::execRead $monitorProcess]
        vwait odfi::powerbuild::eofexec

        catch {close $monitorProcess}
        return 0

##############################
        ## Open file using pipe
        set f [open ptmp {RDWR CREAT}]
        fconfigure $f  -blocking 0 -buffering line
        #fconfigure $f  -blocking 0
        puts "Setup file event $args"
        fileevent $f readable  [list odfi::powerbuild::execRead $f]

        #catch {::exec $args >@$f 2>@$f & }
        #vwait forever

        catch {puts [::exec [split $args]] }

        close $f

        return 
##############################


        


##############################
        ## exec 
        catch {exec $args >@$monitorfile}

        close $monitorfile

    }


}
