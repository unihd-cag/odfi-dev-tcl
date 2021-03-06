package provide odfi::language::nx 1.0.0
package require odfi::language 1.0.0
package require odfi::nx::domainmixin 1.0.0

namespace eval odfi::language::nx {
    
    ## Create new NX based language
    proc new {namespacename script} {
        
        set targetScript  " odfi::language::Language default { $script }"       
        #puts "Target SCript: $targetScript"
        
        namespace eval $namespacename $targetScript
    }

}