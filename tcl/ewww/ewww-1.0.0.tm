package provide odfi::ewww 1.0.0
package require odfi::common

### CODE Based on JohnBuckman http://wiki.tcl.tk/15244
###############################################################

package require uri
package require base64
package require ncgi
package require snit

namespace eval odfi::ewww {

    ################################################################################
    ## Classes
    ################################################################################
    odfi::common::resetNamespaceClasses [namespace current]
    
    lappend auto_path ./tls

    proc bgerror {msg} {
            odfi::common::logError "bgerror: $::errorInfo"
        
    }
    
    
    
    itcl::class Httpd {
        
        ## Base configs
        public variable port "80"
        public variable pki {}
        public variable userpwds {}
        public variable realm {Trivial Tcl Web V2.0}
        public variable handlers {}
       
        ## List of authorized users from userpwds
        variable authList {}
        
        variable listeningSocket
           
        constructor {cPort args} {
            
            ## Default Configure
            ###############################
            if {[llength $args]>0} {
                configure $args
            }
            
            set port $cPort
            
            ## Process User passwords
            ###################
            foreach up $userpwds {
                lappend authList [base64::encode $up]
            }

            
        }
        
        destructor {
            catch {close $listeningSocket}   
        }
        
        ## \brief Starts the Socket
        public method start args {
            
            ## If PKI Provided, try to start TLS
            #########################
            if {$pki ne {}} {
                
                ## Require TLS pckage and init certificates
                package require tls
                foreach {certfile keyfile} $pki {break}
                
                ## Init TLS and start socket
                tls::init -certfile $certfile -keyfile  $keyfile \
                    -ssl2 1 -ssl3 1 -tls1 0 -require 0 -request 0
                set listeningSocket [tls::socket -server [mymethod accept] $port]
                
            } else {
                
                ## No PKI provided, normal socket
                set listeningSocket [socket -server "${this} accept" $port]
            }
            odfi::common::logInfo "Listening socket: $listeningSocket started on port $port ..."
            
        }
        
        ## \brief Closes the socket
        public method stop args {
                    
            catch {close $listeningSocket}   
            
            
        }
        
        ## \brief Accept connection for a client
        public method accept {sock ip port} {
            
            puts "Accepted connection from $ip"
            
            if {[catch {
                
                ## Parse HTTP
                ##############
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
                    GET {$this serve $sock $ip $uri $auth}
                    default {error "Unsupported method '$method' from $ip"}
                }
            } msg]} {
                puts "Error: $msg"
            }
            close $sock
        }
        
        public method authenticate {sock ip auth} {
            if {[lsearch -exact $authList $auth]==-1} {
                respond $sock 401 Unauthorized "WWW-Authenticate: Basic realm=\"$realm\"\n"
                puts "Unauthorized from $ip"
                return 0
            } else {return 1}
        }
        
        
        ## \brief Serves a request by using handler list
        public method serve {sock ip uri auth} {
            
            ## Check authentication
            ##########
            if {[llength $authList] ne 0 && [$self authenticate $sock $ip $auth] ne 1} return
            
            ## Split request path
            array set request [uri::split $uri]
            
            ## Look for a handler for given path
            #############################
            
            ## Search for handler
            #set handler [lsearch -glob $handlers $request(path)]
            
            switch -glob $request(path) $handlers
            
            if {$handler!=""} {
                
                puts "Found handler: $handler"
                $handler serve $this $ip $request $auth
                
            }
            
            #set handler [switch -glob $request(path) $handlers]
            #eval $handler
        }

        public method respond {sock code contentType body {head ""}} {
                puts -nonewline $sock "HTTP/1.0 $code ???\nContent-Type: $contentType; \
                    charset=Big-5\nConnection: close\nContent-length: [string length $body]\n$head\n$body"
        }
        
        
        ##################
        ## Handling
        ##################
        
        public method addHandler {uri handler} {
            set handlers [concat $uri "set handler $handler" $handlers]
           # lappend handlers $uri
           # lappend handlers $script
            
        }
        
    }; 
    # end of snit::type HTTPD

    
    ##########################
    ## Handlers
    ############################
    
    ## \brief Base Class Handler
    itcl::class AbstractHandler {
     
        ##\brief Base path against which this handler is matching
        public variable path
        
        ## \brief User provided closure
        public variable closure
        
        constructor {cPath cClosure} {
         
            set path    $cPath
            set closure $cClosure
        }
        
        
        ##\brief Common Method not designed for overwritting
        public method serve {httpd ip request auth} {
            eval $closure
        }
    
        
    }
 
    
    ##\brief Handles a request, user code must return HTML
    ###################################
    itcl::class HtmlHandler {
            inherit AbstractHandler
        
        constructor {cPath cClosure} {AbstractHandler::constructor $cClosure} {
                 
          
        }
            
            
        ##\brief Serves on doServe
        public method serve {httpd ip request auth} {
            
            ## Eval Closure, must evaluate to an HTML string
            set html [eval $closure]
            
            $httpd respond 200 "text/html" $html
            
        }
            
            
            
    }
    
    ##\brief Handles a request, and tries to map to some user provided closures
    ###################################
    itcl::class APIHandler {
            inherit AbstractHandler
        
        public variable closures
        
        constructor {cPath closuresMap} {
           
            ## Add Each subpath <-> closure entry to the closures list
           foreach {subpath closure} $closuresMap {
            
               lappend closures "$cPath/$subpath"
               lappend closures "set closure $closure"
               
           }
            
          AbstractHandler::constructor $cPath {
              
              ## Find Maping between request path and functions
              switch -glob $request(path) $closures
              if {$closure!=""} {
               
                  ## Evaluate Closure
                   
                  
              }
              
          }
            
            
        }
            
            
        ##\brief Serves on doServe
        public method serve {httpd ip request auth} {
            
            ## Eval Closure, must evaluate to an HTML string
            set html [eval $closure]
            
            $httpd respond 200 "text/html" $html
            
        }
            
            
            
    }
    
    
    
}