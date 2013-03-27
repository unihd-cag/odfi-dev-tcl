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
        
        ## \brief Started or not started
        public variable started false
           
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
                set started true
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
            } msg resOptions]} {
                puts "Error: $msg [dict get $resOptions -errorinfo]"

		#close $sock
		#error $msg
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
            
            set handler ""
            switch -glob "/$request(path)" $handlers
            
            if {$handler!=""} {
                
                puts "Found handler for $request(path): $handler"
                $handler serve $this $sock $ip $uri $auth
                
            } else {
                
            puts "No handler found for $request(path)"
	    }
            
            #set handler [switch -glob $request(path) $handlers]
            #eval $handler
        }

        public method respond {sock code contentType body {head ""}} {
                puts -nonewline $sock "HTTP/1.0 $code ???\nContent-Type: $contentType; \
                    charset=Big-5\nConnection: close\nContent-length: [string length $body]\n$head\n$body"
        }
        
        ##################
        ## Getter Setters
        ##################
        
        ## \brief Returns true if started, false otherwise
        public method isStarted args {
            return $started
        }
        
        
        ##################
        ## Handling
        ##################
        
        public method addHandler  handler {

            set handlerPath /[$handler getPath]
            set handlerPath [regsub -all {/+} $handlerPath /]
    		lappend handlers $handlerPath
    		lappend handlers [list set handler $handler]
                #set handlers [concat [$handler getPath] [list set handler $handler" $handlers]
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
        
	   ## \brief Return path this handler
	   public method getPath args {
	        return $path
	        }
        
        ##\brief Common Method not designed for overwritting
        public method serve {httpd sock ip uri auth} {
            odfi::closures::evalClosure $closure
        }
    
        
    }
 
    
    ##\brief Handles a request, user code must return HTML
    ###################################
    itcl::class HtmlHandler {
            inherit AbstractHandler
        
        constructor {cPath cClosure} {AbstractHandler::constructor $cPath $cClosure} {
                 
          
        }
            
            
        ##\brief Serves on doServe
        public method serve {httpd sock ip uri auth} {
            
            ## Eval Closure, must evaluate to an HTML string
            set html [eval $closure]
            
            $httpd respond $sock 200 "text/html" $html
            
        }
            
            
            
    }
    
    ##\brief Handles a request, and tries to map to some user provided closures
    ###################################
    itcl::class APIHandler {
            inherit AbstractHandler
        
        public variable closures {}
        
	## \brief base constructor
        constructor {cPath closuresMap} {AbstractHandler::constructor $cPath {}} {
           
            ## Add Each subpath <-> closure entry to the closures list
           foreach {subpath functionClosure} $closuresMap {
            
               lappend closures "*/$subpath"
               lappend closures [list set functionClosure $functionClosure]
               
           }   
            
        }

	##\brief Common Method not designed for overwritting
        public method serve {httpd sock ip uri auth} {
		## Find Maping between request path and functions
	      	array set request [uri::split $uri]
		set functionClosure ""
              	switch -glob $request(path) $closures

		puts "Looking for closure in APIHandler for function $request(path)"
		foreach {subpath closure} $closures {
            		puts "-- available: $subpath"
               		
               
           	}   

              	if {$functionClosure!=""} {
               
                  	## Evaluate Closure
			puts "Found closure in APIHandler for function $request(path)"
                   	
			set res [eval $functionClosure]
                  
			## Result must be type + content
			set contentType [lindex $res 0]
			set content [lindex $res 1]

			$httpd respond $sock 200 $contentType $content

              	}
        }
     
    }
	
    
    
    
}
