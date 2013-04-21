#!/usr/bin/env tclsh

package require odfi::ewww::webdata 1.0.0




## Create App Server
#############################
new odfi::ewww::webdata::WebdataServer my_server 8888


## Create App
##################################
new odfi::ewww::webdata::WebdataApplication my_application "/example" {
    
    
    ## View Is supposed to be an HTML or nice faces GUI
    view "welcome" {
     
        html "webdata_index.html"
        
        
    }
    
    ## Data is supposed to be some kind of pure data output, like JSON objects
    data "stat/students" {
        
        
        
        
    }
    
}



## Deploy
#######################
my_server deploy my_application
my_server start



vwait forever
catch {odfi::common::deleteObject example_httpd}