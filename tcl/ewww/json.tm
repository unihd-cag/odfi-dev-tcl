package provide odfi::ewww::webdata::json 1.0.0
package require odfi::closures 2.0.0

namespace eval odfi::ewww::webdata::json {

    itcl::class Json {

     

        public variable content {}

        constructor closure {

            odfi::closures::doClosure $closure
        }

        ## add a new content
        ###############
        public method - {fieldName languageWord value} {

            lappend content "\"$fieldName\" : \"$value\""

        }


        public method toString args {
            return "{\n [join $content ,] \n}"
        }


    }

}
