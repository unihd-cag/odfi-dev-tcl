package provide odfi::attributes 2.0.0
package require odfi::language 1.0.0 

package require odfi::flist 1.0.0


namespace eval odfi::attributes {

    odfi::language::Language default {

        :attributesContainer {

            :attributeGroup name  {
                :attribute name {
                    +var value ""
                }
                +method copy args {
                    set newGroup [next]

                    ## Copy Attributes 
                    :shade odfi::attributes::Attribute eachChild {
                        $newGroup addChild [$it copy]
                    }

                    return $newGroup
                }
                +method setAttribute {name value} {

                    ## Find Attribute 
                    set attr [:shade odfi::attributes::Attribute findChildByProperty name $name]
                    if {$attr==""} {
                        set attr [:attribute $name]
                    }
                    
                    #puts "Set attribute $name to [llength $value]"
                   
                    ## Set value 
                    $attr value set $value
                }

                +method getAttribute {name {default ""}} {
                    ## Find Attribute 
                    set attr [:shade odfi::attributes::Attribute findChildByProperty name $name]

                    #puts "Searching attribute $name found $attr"
                    
                    if {$attr==""} {
                        return $default
                    }
                    ## Get value 
                    return [$attr value get]
                }

                +method hasAttribute {name } {
                    ## Find Attribute 
                    set attr [:shade odfi::attributes::Attribute findChildByProperty name $name]

                    #puts "Searching attribute $name found $attr"
                    #
                    if {$attr==""} {
                        return false
                    } else {
                        return true
                    }
                   
                }
            }

            +method attributeAppend {groupN name value} {

                ## Update actual
                #puts "********* Attribute append $groupN $name [llength $value]"
                set actual [:getAttribute $groupN $name ""]
                if {$actual!=""} {
                    lappend actual $value
                } else {
                    set actual $value
                }

                

                ## Save
                :attribute $groupN $name $actual

                #puts "********* Attribute append done [llength [:getAttribute $groupN $name ""]]"

            }

            +method attribute {groupN name {value ""}} {

                ## Find Group 
                set group [:shade odfi::attributes::AttributeGroup findChildByProperty name $groupN]
                if {$group==""} {
                    set group [:attributeGroup $groupN ]
                }
                
                ## Set  Attribute Value 
                if {$value!=""} {
                    $group setAttribute $name $value
                    #puts "Set $groupN $name -> $value"
                    return $value 
                } else {
                    return [$group getAttribute $name]
                }
                
            }

            +method getAttribute {groupN name {default ""}} {

                ## Find Group 
                set group [:shade odfi::attributes::AttributeGroup findChildByProperty name $groupN]
                
                #puts "Searching attribute group $groupN found $group"
                
                if {$group==""} {
                    #set group [:attributeGroup $group ]
                    return $default
                }
                
                ## Set  Attribute Value 
                return [$group getAttribute $name $default] 
                
                
            }

            +method hasAttribute {groupN name} {
                ## Find Group 
                set group [:shade odfi::attributes::AttributeGroup findChildByProperty name $groupN]
                if {$group==""} {
                    #set group [:attributeGroup $group ]
                    return false 
                }

                return [$group hasAttribute $name] 
            }
            
            +method attributeMatch {groupN name pattern} {
            
                    ## Find Group 
                    set group [:shade odfi::attributes::AttributeGroup findChildByProperty name $groupN]
                    if {$group==""} {
                        #set group [:attributeGroup $group ]
                        return false 
                    }
                    
                    ## Get Attribute
                    if {[$group hasAttribute $name]} {
                        #puts " Checking $pattern against [$group getAttribute $name]"
                        return [string match $pattern [$group getAttribute $name]]
                      
                    } else {
                        #puts "Group has no attr $name"
                           
                        return false
                    }
                    
            }
            
            ## Returns found object or empty string if none
            +method findChildByAttribute {group name match} {
                [:shade ::odfi::attributes::AttributesContainer children] @> findOption {$it attributeMatch $group $name $match} @> match {
                    :none {
                        return ""
                    } 
                    
                    :some v {
                        return $v
                    }
                }
            }
            
            +method findChildrenByAttribute {group name match} {
                return [[:shade ::odfi::attributes::AttributesContainer children] filter {$it attributeMatch $group $name $match}]
            }
            
            +method findChildrenByAttributeNot {group name match} {
                return [[:shade ::odfi::attributes::AttributesContainer children] filterNot {$it attributeMatch $group $name $match}]
            }


           
        }

    }

}
