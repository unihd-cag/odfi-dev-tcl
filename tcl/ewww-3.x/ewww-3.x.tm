package provide odfi::ewww 3.0.0
package require odfi::nx::domainmixin 1.0.0
package require odfi::language::nx 1.0.0
package require odfi::log 1.0.0
package require odfi::files 2.0.0
package require http 2.8.8
 package require odfi::ewww::html    2.0.0

### CODE Based on JohnBuckman http://wiki.tcl.tk/15244
###############################################################

package require uri
package require base64
package require ncgi
#package require snit

namespace eval ::odfi::ewww {


    odfi::language::nx::new [namespace current] {

        :server  port {
            +exportToPublic
            +mixin ::odfi::log::Logger log

            +builder {
                :log:setPrefix "ewww.server(${:port})"
            }

            ## The Socket which is listening
            +var socket ""
            +var authList {}
            +var started false 

            ## Utilities, Start/Stop
            ###############

            +method start args {

                ## IF TLS Provided, used TLS, otherwhise use normal
                set tls [:shade ::odfi::ewww::Tls firstChild]
                set tlsMode false
                if {$tls!=""} {
                    :log:raw "TLS information provided"
                    if {[catch {package require tls} res]} {
                        :log:warning "Cannot load tls package, falling back to non TLS"
                    } else {
                        set tlsMode true

                        ## FIXME Init TLS and start socket
                        tls::init -certfile $certfile -keyfile  $keyfile \
                            -ssl2 1 -ssl3 1 -tls1 0 -require 0 -request 0
                        set :socket [tls::socket -server [mymethod accept] $port]
                    }
                }

                ## Normal mode 
                if {!$tlsMode} {

                    set :socket  [socket -server "[current object] accept" ${:port}]
                    set :started true
                }

            }

            +method stop args {

                catch {close ${:socket}}

            }

            +objectMethod noDoubleSlash in {
                return [regsub -all {//+} $in "/"]
            }

            ## Main Handling
            #####################
            +type Handler {
                +mixin ::odfi::log::Logger log

                +var path ""
                +var name ""

                +method init args {
                    next
                    :log:setPrefix "handler ${:path}"
                }

                +method serve {path sock ip request auth} {
                    next

                }

                ## Response handling
                #########
                +method respond {sock code contentType body {head ""}} {


                    #foreach enc [encoding names] {
                    #    puts "Encoding: $enc"
                    #}

                        #set realBody [join $body]
                        set encoded [encoding convertto utf-8 $body]
        #
                        #odfi::common::logFine "--- Responding with content: $body , length [string length $body]"

                        #; charset=UTF-8

                        puts $sock "HTTP/1.1 $code"
                        puts $sock "Content-Type: $contentType"
                        puts $sock "Connection: close"

                        puts $sock "Content-length: [string length $encoded]"
                        #puts $sock "Content-length: [string length $body]"

                        puts $sock ""

                        #puts $sock "$head"
                        puts $sock "$encoded"
                        #puts -nonewline $sock "HTTP/1.0 $code\nContent-Type: $contentType; \
                            charset=UTF-8\nConnection: keep-alive\nContent-length: [string bytelength $body]\n$head\n$encoded"
                        flush $sock

                }

                ## Standard handlers
                ###################
                :fileHandler : Handler path baseFolder {


                    +method accept path {

                        if {[file exists $baseFolder/$path]} {
                            return true 
                        } else {
                            return false
                        }
                    }

                    ## return {contentType length data}
                    +method render path {
                        return [next]

                    }

                }


                ## HTML Views
                #######################
                :htmlViewTemplate : ::odfi::ewww::html::HTMLNode name templateScript {

                  

                    +builder {
                        if {[file exists ${:templateScript}]} {
                            set :templateScript [file normalize ${:templateScript}]
                            puts "template script at: ${:templateScript}"
                        }

                        
                    }

                    ## Return first html node or use script
                    +method build args {

                        set node [:shade ::odfi::ewww::html::HMLNode firstChild]
                        if {$node!=""} {
                            return $node 
                        } else {
                            if {[file exists ${:templateScript}]} {
                                source ${:templateScript}
                            } else {
                                :apply ${:templateScript}
                            }
                        }
                    }
                }

                :htmlView : Handler name path buildScript {


                    +method getTemplate name {

                        set template [[:parent] shade ::odfi::ewww::HtmlViewTemplate findChildByProperty name $name]
                        if {$template==""} {
                            error "Cannot find template $name while building html view ${:path}"
                        } else {
                            set res [$template build]
                            if {$res==""} {
                                error "template building for $name returned nothing, should return an HTML node"
                            } else {
                                return $res
                            }
                            
                        }
                    }
                    +method accept path {

                        if {$path==${:path}} {
                            return true 
                        } else {
                            return false
                        }
                    }

                    +method render path {

                        #puts "Inside render "
                        set res [:apply ${:buildScript}]
                        if {$res==""} {
                            error "Building HTML View $path should return an HTML node, nothing returned"
                        } else {

                            #puts "Render result: [$res info class]"
                            set resString [$res toString]
                            return [list [string length $resString] text/html $resString]

                        }

                    }

                }


            }
            ## EOF Handler Definition

            +method accept {sock ip port}  {

                :log:fine "Accepted connection from $ip"

                ## Configure  socket
                #chan configure $sock -encoding utf-8
                #chan configure $sock -encoding utf-8 -translation crlf -blocking 1
                chan configure $sock -encoding utf-8 -translation binary -blocking 1
                #chan configure $sock -blocking 1

                ## FIXME? Save to sockets being listened to and set event
                ##fileevent $sock readable "[current object]"

                ## Parse HTTP
                ##############
                try {
                    gets $sock line
                    set auth ""
                    for {set c 0} {[gets $sock temp]>=0 && $temp ne "\r" && $temp ne ""} {incr c} {
                        regexp {Authorization: Basic ([^\r\n]+)} $temp -- auth
                        if {$c == 30} {error "Too many lines from $ip"}
                    }
                    if {[eof $sock]} {error "Connection closed from $ip"}

                    ## Split HTTP line argument
                    ################
                    foreach {method uri version} $line {break}
                    switch -exact $method {
                        GET {:serve  $sock $ip $uri $auth}
                        POST {:serve $sock $ip $uri $auth}
                        default {error "Unsupported method '$method' from $ip"}
                    }

                } finally {
                    close $sock
                }
            }

            +method authenticate {sock ip auth} {
                if {[lsearch -exact ${:authList} $auth]==-1} {
                    respond $sock 401 Unauthorized "WWW-Authenticate: Basic realm=\"$realm\"\n"
                    odfi::log::warn "Unauthorized from $ip"
                    return 0
                } else {return 1}
            }   

            +method serve {sock ip uri auth} {

                ## Check authentication
                ##########
                #if {[llength ${:authList}] ne 0 && [$self authenticate $sock $ip $auth] ne 1} return


                ## Split Request URI to easily access the components
                ###############
                array set request [uri::split $uri]

                ## Create request path
                ###########
                set requestPath [::odfi::ewww::Server::noDoubleSlash "/[lindex [array get request path] 1]"]

                :log:raw "Serving Request for $requestPath"

                ## Modify URI array
                array set request [list path $requestPath]


                ## Search for Handler
                ############################
                set server [current object]
                [:shade ::odfi::ewww::Handler children] @> findOption { string match [$it path get]* $requestPath} @> match {


                    :some handler {

                        set localRequestPath [::odfi::ewww::Server::noDoubleSlash /[string map [list [$handler cget -path] "/" // /] "$requestPath"] ]
                        
                        $server log:raw "Found handler for $requestPath -> $localRequestPath" 
                        

                        $handler serve $localRequestPath $sock $ip [array get request] $auth

                    }

                    :none {
                        $server log:warning "Cannot find handler for requested $requestPath"
                    }
                }


            }

            ## TLS
            #############
            :tls certfile keyfile {

            }

            ## Application
            #######################
            :application : Handler name path {

                +method serve {path sock ip request auth} {
                    next

                    :log:raw "Serving $path"

                    ## Look for Handlers which would accept the path 
                    set handlers [[:shade ::odfi::ewww::Handler children] filter { $it accept $path}]
                    $handlers isEmpty {

                        :log:warning "No Handler found to serve path $path"
                        :respond $sock 404 text/plain "Not Found"

                    } else {

                        if {[$handlers size]>1} {
                            :log:warning "Multiple Handlers found to serve path $path , using first one [[$handlers at 0] info class]"
                        }

                        ## Serve
                        :log:raw "Using Handler [[$handlers at 0]  info class] "
                        set res [[$handlers at 0] render $path]

                        ## Respond
                        :respond $sock 200 [lindex $res 1] [lindex $res end]

                    }

                    

                }


            }

        }


    }


}
