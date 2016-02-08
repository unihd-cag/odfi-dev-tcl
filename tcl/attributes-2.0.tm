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
                    
                    #puts "Set attribute $name to $attr"
                   
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
                    
                    if {$attr==""} {
                        return false
                    }
                    ## Get value 
                    return true
                }
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

           
        }

    }

}
