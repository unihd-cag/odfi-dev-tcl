
## This package is a set of utility to be used when writting tools, like command line base utility
## It offers some verbose factories to describe a tool, and define things like command line arguments
package provide odfi::tool 1.0.0

package require odfi::list 2.0.0



namespace eval odfi::tool {


    ## This entry point will create a metadata object called ::tool
    #  It is designed for a fast user usage
    # @param closure A closure to be executed in context of created Metadata Object
    proc describe closure {

        ## Create Object
        #################
        ::new [namespace current]::Metadata ::tool $closure

    }


    #######################################
    ## Classes
    ##########################################


    ## Metadata object
    ########################
    itcl::class Metadata {

        ## Description of the tool
        public variable description ""

        ## Arguments Map
        public variable arguments

        ## Constructor takes a closure to be executed in this object's context
        constructor closure {

            array set arguments {}

            odfi::closures::doClosure $closure

        }

        ## Metadata Methods
        #########################

        ## Sets the description of this tool
        public method description desc {
            set description $desc
        }


        ## Displays usage informations
        public method usage args {

            ## Description
            ##############
            puts "Description:
            $description"


            ## Arguments
            ##################
            if {[array size arguments]>0} {

                puts "Available arguments: \n"
                foreach {argName argDesc} [array get arguments] {

                    odfi::common::printlnIndent

                    odfi::common::println "-> --$argName"

                    ## Description
                    if {[odfi::list::arrayContains $argDesc description]} {

                        odfi::common::printlnIndent

                        odfi::common::println "- Description: [string trim [odfi::list::arrayGet $argDesc description]]"

                        odfi::common::printlnOutdent
                    }

                    ## Type
                    if {[odfi::list::arrayContains $argDesc type]} {

                        odfi::common::printlnIndent

                        set type [odfi::list::arrayGet $argDesc type]
                        switch -exact -- $type {
                            file {
                                odfi::common::println "- Type: $type (Must be a valid path to a file)"
                            }
                            string {
                                odfi::common::println "- Type: $type (just a string)"
                            }
                            list {
                                odfi::common::println "- Type: $type (a list of size [odfi::list::arrayGet $argDesc size])"
                            }
                            producer {
                                odfi::common::println "- Type: $type (Must be a Producer)"
                            }
                            default {
                                odfi::common::println "- Type (unknown): $type"
                            }
                        }



                        odfi::common::printlnOutdent
                    }



                    odfi::common::printlnOutdent

                }

            }


        }

        ## Command line arguments methods
        ###################

        ## Defines a new argument for command line $::args
        # @param argName Command line argument name, without "-"
        public method argument {argName args} {

            #puts "Adding new argument $argName with $args"

            ## Prepare
            ###############
            #set required false
            #if {$optionalOrRequired=="required"} {
            #    set required false
            #}

            ## Gather extra stuff from args
            ##################

            ## Default
            #set defaultDefined false
            #catch {
            #    set default [odfi::list::arrayGet $args default]
            #    set defaultDefined true
            #}


            ## Checks
            #################

            ##  Record
            ###############
            set arguments($argName) $args

        }

        ## This method parses $::args and tries to match the ones defined
        #
        public method parseArguments args  {

            ## Handle special -help
            ###############
            if {[lsearch -exact $::argv --help]!=-1} {
                usage
                exit 1
            }

            ## Search in defined arguments
            ######################
            foreach {argName argDesc} [array get arguments] {

                ## Get Arguments Parameters
                #############

                ## Optional/Required
                set optional [odfi::list::arrayContains $argDesc optional]

                ## Type
                set type bool
                if {[odfi::list::arrayContains $argDesc type]} {
                    set type [odfi::list::arrayGet $argDesc type]
                }

                ## Look into argv
                ############
                set argIndex [lsearch -exact $::argv --$argName]

                ## Resolve
                ################

                if {$argIndex==-1} {

                    #### Nothing found
                    ###############################################
                    if {$optional} {

                        #### Optional  -> set to false
                        set ::$argName false
                        continue

                    } else {

                        #### Non Optional  -> error
                        odfi::common::logError "Could not find argument $argName on command line, this argument is required"
                        return
                    }

                } else {


                    #### Found -> Do stuff depending on type
                    ###############################################
                    switch -exact -- $type {

                        string {

                            ##### string
                            ############################################################

                            if {[odfi::list::arrayContains $::argv --$argName]} {

                                set str [odfi::list::arrayGet $::argv --$argName]

                                ## Set value
                                set ::$argName $str

                            } else {

                                error "Argument --$argName must be provided a value"
                            }


                        }

                        producer {
                            #to be a producer it must inherit from odfi::dev::hw::package::BaseOutputGenerator
                            odfi::dev::hw::package::Footprint foot 
                            set prod "[odfi::list::arrayGet $::argv --$argName]"
                            set obj [::new $prod #auto ::foot]
                        
                            if {[$obj info inherit] != "::odfi::dev::hw::package::BaseOutputGenerator"} {
                                puts "start if"
                                error "$argName should be a producer but it doesn't inherit from ::odfi::dev::hw::package::BaseOutputGenerator"
                            }
                            set ::$argName $prod
                        }

                        list {

                            ## Get expected list size
                            set size [odfi::list::arrayGet $argDesc size]

                            ## Get Args
                            set values [odfi::list::arrayFromKey $::argv --$argName $size]

                            ## Set
                            set ::$argName $values

                        }

                        file {

                            #### File -> check the file is real
                            ############################################################

                            set file [odfi::list::arrayGet $::argv --$argName]

                            ## Check the file presence
                            if {![file isfile $file]} {

                                odfi::common::logError "$argName should be a file, but the value $file does not seem to point to a file"
                                return

                            }

                            ## Set value
                            set ::$argName $file
                        }

                        ## Default -> just arg presence
                        default {
                            set ::$argName true
                        }
                    }

                }





            }



        }


    }

}
