package provide odfi::ewww::webdata 2.0.0
package require odfi::ewww 2.0.0


## Other files to source for this module
set otherFiles {
    json.tm
}

namespace eval odfi::ewww::webdata {



    ################################################################################
    ## Classes
    ################################################################################
    odfi::common::resetNamespaceClasses [namespace current]

    ###################################
    ## Main Server interface to add applications
    ##########################
    itcl::class WebdataServer {

        ## \brief the underlying HTTPD server
        protected variable httpd

        ## \brief list of all the applications
        protected variable applications {}


        constructor port {

            ## Default
            ####################
            set httpd [::new odfi::ewww::Httpd #auto $port]
        }

        destructor {
            stop
        }

        ## \brief starts the Httpd server and the applications
        public method start args {

            if {[$httpd isStarted]} {
                return
            }

            ## Start HTTP
            #################
            $httpd start

            odfi::common::logInfo "Started HTTP Server, now starting applications"

            ## Start Applications
            ##########################
            odfi::list::each $applications {

                $it start

            }



        }


        ## \brief Stop this data server
        #############
        public method stop args {

            ## Stop HTTP
            #################
            $httpd stop

        }

        ## \brief Deploy an application. Will be started if server is started
        public method deploy application {

            ## Register handler
            ########################
            $httpd addHandler $application
            lappend applications $application

            odfi::common::logInfo "Deployed application $application on path [$application getPath]"

            ## If Server is started, start
            #################
            if {[$httpd isStarted]} {


                $application start
            }





        }


        ## \brief Deply a new application to the server. The provided closure is used a constructor to application
        public method application {path closure} {

            ## Create app
            ####################
            set app [::new [namespace parent]::WebdataApplication #auto $path $closure]

            ## Deploy
            ####################
            deploy $app

        }


    }


    ###################################
    ## Web application interface
    ##################################
    itcl::class WebdataApplication {
        inherit odfi::ewww::AbstractHandler

        ## \brief Source file where this application is sourced
        protected variable sourceFile

        ## \brief Closure executed on start
        protected variable startClosure {}
        protected variable stopClosure {}

        protected variable errorView ""


        ##\brief Viewhandlers
        protected variable handlers {
        }

        ## \brief The folder where the application can be located
        ## Used for resources auto-find
        protected variable applicationFolder ""
        
        protected variable filesystemPath ""

        protected variable applicationPath

        ## \brief Build the Application
        constructor {cPath cBasePath cClosure} {odfi::ewww::AbstractHandler::constructor "$cPath/*" {}} {

            ## Init
            ###############
            set sourceFile [file normalize [info script]]
            set applicationPath $cPath
            set filesystemPath $cBasePath
            
            ## Set FS Handler
            ##############
            set fsH [::new odfi::ewww::FSHandler $cPath
            
            ## Set default handler
            #################
            #view / {
            #    html {
            #        set content "You reached the application $application"
            #   }
            #}


            ## Closure
            ################
            if {[llength $cClosure]>0} {
                odfi::closures::doClosure $cClosure
            }

        }


        ## \brief Executes the startClosure
        ###################
        public method start args {

            odfi::common::logInfo "Starting application $this"

            if {[llength $startClosure]>0} {
                odfi::closures::doClosure $startClosure
            }

        }

        public method addHandler {path object} {

            ## Replace if existing
            #########
            set existing [lsearch -exact $handlers $path]
            if {$existing!=-1} {

                set handlers  [lreplace $handlers [expr $existing+1] [expr $existing+1] $object]
                odfi::common::logInfo "Replacing handler for $path with $object"

            } else {

                ## Add
                lappend handlers $path
                lappend handlers $object
            }

        }

        ## \brief Add a new view to the handler
        # @param Name of the view like my.view, translated to /view/my/view
        # @param closure Code applied to the newly created WebdataView
        ################
        public method view {name closure} {

            ## Prepare path
            ####################
            #set viewPath [join [list /view /[regsub {\.} $name /]] /]
            set viewPath "/view/$name"
            set viewPath [regsub -all {/+} $viewPath /]

            ## Path must not end with /
            set viewPath [regsub -line {/$} $viewPath ""]

            ## Prepare View Object
            ###################
            ::new [namespace parent]::WebdataView $this.view.$name $viewPath $closure


            ## Add to handlers
            #################
            addHandler $viewPath $this.view.$name



            #odfi::common::logInfo "Added view to path $viewPath"

        }

        ## \brief Add a new Data source to the application
        #  @param Name of the data source like my.data.source, translated to /data/my/data/source
        #  @param Closure Implementation of the data source. The return type will be used by the framework.
        #                  The closure can just set the data variable as result
        ###############################
        public method data {name closure} {

            ## Prepare path
            ####################
            set dataPath "/data/$name"
            set dataPath [regsub -all {/+} $dataPath /]

            ## Path must not end with /
            set dataPath [regsub -line {/$} $dataPath ""]

            ## Prepare View Object
            ###################
            ::new [namespace parent]::WebdataData $this.data.$name $dataPath $closure


            ## Add to handlers
            #################
            lappend handlers $dataPath
            lappend handlers $this.data.$name


            #odfi::common::logInfo "Added data to path $dataPath"

        }

        ## \brief Add a new Action to the application
        #  @param Name of the action like my.action, translated to /actions/my/action
        #  @param Closure Implementation of the action. The return type will be used by the framework.
        #                  The closure can just set the data variable as result
        ###############################
        public method action {name closure} {

            ## Prepare path
            ####################
            set actionPath "/action/$name"
            set actionPath [regsub -all {/+} $actionPath /]

            ## Path must not end with /
            set actionPath [regsub -line {/$} $actionPath ""]

            ## Prepare View Object
            ###################
            ::new [namespace parent]::WebdataAction $this.action.$name $actionPath $closure


            ## Add to handlers
            #################
            lappend handlers $actionPath
            lappend handlers $this.action.$name


            #odfi::common::logInfo "Added action to path $actionPath"

        }

        ## Getters Setters
        ########################
        public method getApplicationFolder args {
            return $applicationFolder
        }

        ## \brief Returns the Application#s web path "/whatever"
        public method getApplicationPath args {
            return "/$applicationPath"
        }

        ## \brief Serving
        ################################

        public method serve {httpd sock ip requestArray auth} {

            ## Reload application
            ########################
            #set objectType [namespace which -variable $this]
            #set objectType [info object class $this]
            #puts "Object type to reload: $objectType"
            array set request $requestArray

            ## Remove application path from request path
            set requestPath $request(path)
            set applicationPathPart [join [lrange [split $path /] 0 end-1] /]
            set inAppUri [string replace $requestPath 0 [string length $applicationPathPart]]
            #array set request [uri::split $inAppUri]

            ## Make sure search path starts with an /
            set searchPath $inAppUri
            if {[string index $searchPath 0]!="/"} {
                set searchPath /$searchPath
            }

            ## Update request array with inApp URI
            set request(path) $searchPath

            #set searchPath /$searchPath
            odfi::common::logInfo "Serving application for '$searchPath' // $applicationPathPart // complete: [array get request]"

            ## Look into handlers list, if one path matches our path
            #################
            set entry [lsearch -glob $handlers $searchPath]
            if {$entry!=-1} {

                #odfi::common::logInfo "---Found entry at $entry"

                ## Take handler
                set applicationHandler [lindex $handlers [expr $entry+1]]

                ## Execute:
                ##  - Return 500 if an error was thrown
                ##  - Return content otherwise
                if {[catch {set result [$applicationHandler serve $this $sock $ip [array get request] $auth]} res resOptions]} {


                    ## Error, if webdata is configured with a 500 view, then use it
                    ###########
                    if {$errorView!="" && [file isfile $errorView]} {

                        ## Read Definition
                        set f [open $errorView]
                        set content [read $f]
                        close $f
                        ::new [namespace parent]::TViewContentProducer tviewTransformer $content ""

                        ## Transform
                        if {[catch {set result [tviewTransformer transform [concat err "{$res}" errorOptions "{$resOptions}"]]}]} {

                        } else {

                            $httpd respond $sock 500 "text/html" $result ""
                            return
                        }

                    }

                    ## Fallback
                    $httpd respond $sock 500 "text/plain" "An error occured: $res" ""

                    odfi::common::logError "Error while serving request: [dict get $resOptions -errorinfo]"
                    #error $res

                } else {

                    set contentType [lindex $result 0]
                    set content [lindex $result 1]

                    $httpd respond $sock 200 $contentType "$content"
                }
            } else {

                ## Default handler for views: Normal Files // if {[string match "/view/*" $searchPath]}
                ##################

                set filePath [regsub {/view/} $searchPath ""]
                odfi::common::logInfo "Looking for $searchPath, file $filePath into $applicationFolder"
                if {[file isfile $applicationFolder/$filePath] && [file exists $applicationFolder/$filePath]} {

                    ## Get content type
                    set contentType "text/plain"
                    switch -glob -- [file tail $filePath] {
                        *.js    {set contentType application/javascript}
                        *.css   {set contentType text/css}
                        default {set contentType text/plain}
                    }

                    ## Get content
                    set f [open $applicationFolder/$filePath]
                    set content [read $f]
                    close $f
                    #odfi::common::readFileContent $filePath content

                    ## Respond
                    $httpd respond $sock 200 $contentType "$content"


                }

            }
        }

    }



    ###################################
    ## Web application interface
    ##################################
    itcl::class WebdataView {
        inherit odfi::ewww::AbstractHandler

        ## \brief Path to a possible html file to serve
        public variable html ""

        ## \brief Path to a possible TCL view file to serve
        public variable tview ""

        ## \brief List of {varName Value} pairs to hold model for a certain view
        public variable model {}

        ## \brief list of point + closure pairs to add implementatino of injection points in a view
        public variable injectionPoints {}

        ## \brief Builds the View
        constructor {cPath cClosure} {odfi::ewww::AbstractHandler::constructor "$cPath" {}} {

            ## Closure
            ################
            if {[llength $cClosure]>0} {
                odfi::closures::doClosure $cClosure 0 2
            }

        }

        ## Content Handlers
        ###########################


        ## \brief Add an HTML handler to serve a request
        public method html filePath {

            set html $filePath


        }

        ## \brief Add a TCL view file as path (a file with embedded plain Text Variables and commands)
        public method tview filePath {

            set tview $filePath


        }

        ## Injection points
        ###############
        public method getInjectionPoint name {

            set index [lsearch -exact $injectionPoints $name]
            if {$index>-1} {
                return [lindex $injectionPoints [expr $index+1]]
            }
            return {}

        }

        ## Model for the view
        ###########################

        ## \brief Added a variable with a value to the model of this view
        # Before serving content, the variables defined here will be set in the parsing TCL context
        public method model {varName value} {
            lappend model $varName $value
        }

        ## \brief Serve content
        ##################
        public method serve {application sock ip requestArray auth} {

            array set request $requestArray

            ## Serve TCL View
            ######################

            ## Fix File name
            if {[file pathtype $tview]=="relative"} {
                set tview "[$application getApplicationFolder]/$tview"
            }

           # puts "Trying to serve tview @ $tview, is file: [file isfile $tview] "

            if {[file isfile $tview]} {



                ## Read
                set f [open $tview]
                set content [read $f]
                close $f

                ## Parse
                ::new [namespace parent]::TViewContentProducer tviewTransformer $content $this
                set result [tviewTransformer transform [concat application $application requestArray [list [array get request]] $model]]


                #odfi::common::logFine "Serving tview, with result: $result"

                ## Return
                return [list "text/html" $result]
            }


            ## Serve HTML
            ##  - File if file
            ##  - Closure is closure
            ##########################
            if {[file isfile $html]} {


                ## Read File
                set f [open $html]
                set content [read $f]
                close $f

                ## Return
                return [list "text/html" $content]

            } elseif {[llength $html]>0} {

                ##
                eval $html
                return [list "text/html" $content]

            }

        }


    }

    ###################################
    ## Web application Data source
    ##################################
    itcl::class WebdataData {
        inherit odfi::ewww::AbstractHandler

        ## Implementation can be provided to provide custom results
        public variable implementation ""

        public variable contentType "application/json"

        ## \brief Turn result of this data to the provided view type
        public variable dataView ""

        ## \brief Object on which to get specific dataView
        public variable dataSource ""

        ## \brief List of {varName Value} pairs to hold model for a certain view
        public variable model {}

        ## \brief Builds the Data Source
        constructor {cPath cClosure} {odfi::ewww::AbstractHandler::constructor "$cPath" {}} {

            ## Constructor Closure
            ###################
            #puts "Created Webdatadata, and starting closure: $cClosure"
            odfi::closures::doClosure $cClosure
            #set implClosure $cClosure


        }

        ## \brief Added a variable with a value to the model of this view
        # Before serving content, the variables defined here will be set in the parsing TCL context
        public method model {varName value} {
            lappend model $varName $value
        }

        ## Set implementation closure
        public method implementation closure {

            set implementation $closure

        }

        ## \brief Serve content
        ##################
        public method serve {application sock ip requestArray auth} {

            ## parsed URI
            array set request $requestArray

            ## Data View, either default, or one in URI
            #########
            set selectedDataView $dataView
            puts "Data query part: $request(query)"
            regexp {view=([\w_-]+)} $request(query) -> selectedDataView

            puts "Data query view: $selectedDataView"
             puts "Data source: $dataSource"

            ## Call Data source
            ########

            ## Set Model variables
            foreach {varName value} $model {
                #puts "Transforming with variable: $varName"
                set $varName $value
            }

            ## Use :
            ##    - Data Source
            ## or - Implementation
            ##################
            if {$dataSource!="" && $selectedDataView!=""} {

                set contentType [$dataSource viewContentType $selectedDataView]
                set data        [$dataSource view $selectedDataView]

            } else {
                set data [eval $implementation]

                puts "Data implementation eval gives: $data"
                if {[odfi::common::isClass $data odfi::ewww::webdata::json::Json]} {

                    set data [$data toString]
                    puts "Json result: $data"
                }

            }

            if {[llength $data]>1} {
                set contentType [lindex $data 0]
                set data        [lindex $data 1]
            }


            #puts "Final content: $data"
            return [list $contentType $data]


        }

        ## Creates a JSON object with a closure to be executed on it
        public method json closure {

            ## Create JSon 
            set jsonObject [::new odfi::ewww::webdata::json::Json #auto $closure]
            return $jsonObject

        }

    }

    ###################################
    ## Web application Action
    ##################################
    itcl::class WebdataAction {
        inherit odfi::ewww::AbstractHandler

        public variable implementation

        ## \brief List of {varName Value} pairs to hold model for a certain view
        public variable model {}

        ## \brief Builds the Data Source
        constructor {cPath cClosure} {odfi::ewww::AbstractHandler::constructor "$cPath" {}} {

            ## Constructor Closure
            ###################
            odfi::closures::doClosure $cClosure


        }

        ## \brief Added a variable with a value to the model of this view
        # Before serving content, the variables defined here will be set in the parsing TCL context
        public method model {varName value} {
            lappend model $varName $value
        }

        ## \brief Serve content
        ##################
        public method serve {application sock ip requestArray auth} {


            ## Evaluate implementation
            ##############
            ## Set Model variables
            foreach {varName value} $model {
                #puts "Transforming with variable: $varName"
                set $varName $value
            }

            set result [eval $implementation]

            return [$result , "text/plain"]

        }

        ## \brief Just set the implementation of this action
        public method run closure {
            set implementation $closure
        }

    }


    ###################################
    ## View Content Producer
    ##################################
    itcl::class ViewContentProducer {

    }

    ###################################
    ## TVIEW Content Producer
    ##################################
    itcl::class TViewContentProducer {

        ## The application for which we are rolling
        #public variable application

        public variable sourceString

        ## \brief The view we are linekd to
        public variable view

        constructor {cSourceString cView} {
            set sourceString $cSourceString
            set view $cView
        }

        public method transform model {

            ## Set Model variables
            foreach {varName value} $model {
                #puts "Transforming with variable: $varName"
                set $varName $value
            }


            ## transform
            return [odfi::closures::embeddedTclStream [odfi::common::newStringChannel $sourceString]]

        }

        public method view-inject point {

            set pointClosure [$view getInjectionPoint $point]
            if {[llength $pointClosure]>0} {
                return [odfi::closures::doClosureToString $pointClosure]
            } else {
                return ""
            }

        }

        ## HTML Content Methods
        ###########################

        public method ul closure {

            return "<ul>[odfi::closures::doClosureToString $closure]</ul>"

            set resunJoined [odfi::closures::doClosure $closure]
            #puts "Should be end of closure before this line, with res: $resunJoined"
            #set res [odfi::closures::doClosureToString $closure]
            #puts "UL joining: [join $resunJoined \n]"

            set res "<ul>[join $resunJoined]</ul>"


            return $res



        }

        public method li closure {


            return "<li>[odfi::closures::doClosureToString $closure]</li>"
        }

        public method span closure {


            return "<span>[odfi::closures::doClosureToString $closure]</span>"
        }

        public method div closure {


            return "<div>[odfi::closures::doClosureToString $closure]</div>"
        }
        public method div-id {id closure} {


            return "<div id=\"$id\">[odfi::closures::doClosureToString $closure]</div>"
        }

        ## Titling
        #################
        public method h1 closure {

            return "<h1>[odfi::closures::doClosureToString $closure]</h1>"
        }
        public method h2 closure {

            return "<h2>[odfi::closures::doClosureToString $closure]</h2>"
        }
        public method h3 closure {

            return "<h3>[odfi::closures::doClosureToString $closure]</h3>"
        }
        public method h4 closure {

            return "<h4>[odfi::closures::doClosureToString $closure]</h4>"
        }
        public method h5 closure {

            return "<h5>[odfi::closures::doClosureToString $closure]</h5>"
        }
        public method h6 closure {

            return "<h6>[odfi::closures::doClosureToString $closure]</h6>"
        }


        ## Table
        ###########################

        public method table closure {

            ## Create table
            ::new [namespace parent]::html::Table webdata.html.table
            webdata.html.table apply $closure
            return [webdata.html.table toHTML]

            #return "<table>
            #    [odfi::closures::doClosureToString $closure]
            #</table>"

        }


        #### Linking
        ##################

        ## \brief Creates a simple link to a view
        #  Example: link "This is a link" to /path/to/view
        #           <a href="appPath/view//path/to/view">This is a link</a>
        public method link {linkText word viewId} {

            set linkOutput  [odfi::closures::doClosure {

                    return "<a href='$viewId'>
                                    $linkText
                            </a>"

                    return "<a href='[$application getApplicationPath]/view/$viewId'>
                                    $linkText
                            </a>"
            }]

            #puts "Link Result: $linkOutput"

            return $linkOutput
        }

        ## Special Methods
        ###########################

        public method breadCrumbs {lst transformClosure} {

            return [div {
                join [odfi::list::transform $lst {
                    span $transformClosure
                }] " - "

            }]

        }

    }

}

## Additional files
##############################
foreach sourceFile $otherFiles {
   source [file dirname [file normalize [info script]]]/$sourceFile
}


