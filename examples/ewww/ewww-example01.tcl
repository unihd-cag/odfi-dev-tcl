#!/usr/bin/env tclsh



package require odfi::ewww 1.0.0



odfi::ewww::Httpd example_httpd 8888

example_httpd start


example_httpd addHandler  [::new odfi::ewww::APIHandler #auto "rest/*" {
    
    time {
        
        set res [list "text/html" "Time: [clock format [clock seconds]]" "Refresh: 6;URL=/\n"]
        
    }
    
}]



vwait forever
catch {odfi::common::deleteObject example_httpd}
