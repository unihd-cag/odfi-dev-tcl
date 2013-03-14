#!/usr/bin/env tclsh



package require odfi::ewww 1.0.0



odfi::ewww::Httpd example_httpd 8888

example_httpd start


example_httpd addHandler "/rest/*" [::new odfi::ewww::APIHandler #auto {
    
    time {
        
        set res {"text/html" "Hello world!"}
        
    }
    
}]


example_httpd addHandler "/time" {
    
    respond $sock 200 "Time: [clock format [clock seconds]]" "Refresh: 6;URL=/\n"
    
}

vwait forever
catch {odfi::common::deleteObject example_httpd}
