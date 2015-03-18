## Just a simple Package to provide attributes mixin classes to add generic attribute descriptions for objects
## The Attributes Definitions provide generic string based attributes to add to objects
## Attributes are named in the form "group.attribute::name::whatever"
## There is no group object, only the names define the grouping
## The attributes themselves are Objects
package provide odfi::attributes 1.0.0
package require odfi::flist 1.0.0
package require odfi::flextree 1.0.0

namespace eval odfi::attributes {



    ###################################
    ## Classes 
    #######################################

    nx::Class create Attribute -superclass odfi::flextree::FlexNode {

        :property -accessor public name:required
        :variable -accessor public value ""
        
        ## Group 
        ################

        ## @return the group name of "default" if no group name
        :public method groupName args {

            set splitted [split ${:name} .]
            #puts "-> Splited name for group name ${:name} -> $splitted"
            if {[llength $splitted]>1} {
                return [lindex $splitted 0]
            } else {
                return "default"
            }
            
        }

        ## Attribute itself
        #################

        ## @return The attribute name, without group name
        :public method simpleName args {

            set splitted [split ${:name} .]
            #puts "-> Splited name for group name ${:name} -> $splitted"
            if {[llength $splitted]>1} {
                return [lindex $splitted 1]
            } else {
                return ${:name}
            }
            
        }


        ## Factory 
        ######################

        :public object method fromQName arg {

            ## Create 
            set obj [Attribute new -name $arg]

            ## Return

        }

    }

    ## NX Attributes Container trait with utilities only (no attributes storage)
    ###################
    nx::Class create AttributesContainerTrait {
        
        ## Interface 
        ###################
        
        ## @return an FList with the defined attributes
        :public method attributes args {
            error "@method not defined" 
        }

        ## Add the provided attribute Object to the object list
        :public method addAttributeObject obj {
            error "@method not defined" 
        }



        ## Add 
        ###############
        
        ## Add attribute(s) to the attributes list.
        ## @args can be: name {name value} attributeObject
        :public method addAttribute args {

            foreach arg $args {
  
                if {[odfi::common::isClass $arg [namespace current]::Attribute]} {
                    :addAttributeObject $arg 
                } elseif {[::nsf::is class $arg]} {
                    error "Cannot add an attribute object which is not of type [namespace current]::Attribute"
                } else {

                    ## Arg: name -> just create 
                    ## Arg: {name value} -> create and add value
                    set attribute [Attribute::fromQName [lindex $arg 0]]
                    :addAttribute $attribute

                    ## Set value?
                    if {[llength $arg]>1} {
                        $attribute value [lindex $arg 1]
                    }
                }
            }
        }

        ## Retrieve Groups 
        #####################
        
        ## Retrieve all the group names as FList 
        ## @args: -tcl true Returns a standard TCL String list
        :public method getGroupNames {-tcl:boolean,0..1} {

            ## Get names and remove duplicates
            set groups [[:attributes] map { $it groupName}]

            #puts "Group names: [$groups content]"

            ## Filter duplicates 
            set res [$groups compact]

            ## Return as FList or TCL list 
            if {[info exists tcl] && $tcl} {
                return [$res asTCLList]
            } else {
                return $res
            }
        }

        ## @return The Attributes of a specific group as an FList
        ## @args: -tcl true Returns a standard TCL String list
        :public method getGroupAttributes {gname -tcl:boolean,0..1} {

            set res [[:attributes] filter { string equal [$it groupName] $gname } ]

            ## Return as FList or TCL list 
            if {[info exists tcl] && $tcl} {
                return [$res asTCLList]
            } else {
                return $res
            }

        }

        ## Retrieve Attributes 
        #################
        
        ## name format: attributeGroupName.attributeQualified name 
        ## Example: hardware.rw
        ## @return true/false
        :public method hasAttribute qname {

            try {
                [:getAttribute $qname]
                return true
            } on error {res resOptions} {
                return false
            }
            

        }

        :public method onAttributes {attributeList closure1 {keyword ""} {closure2 ""}} {
            set scoreList {}

            foreach element $attributeList {
                if {[hasAttribute $element]} {
                    lappend scoreList "true"
                } else {
                    lappend scoreList "false"
                } 
            }
            if {[lsearch -exact $scoreList "false"] == -1} {
                odfi::closures::doClosure $closure1 1
            } else {
                if {$closure2 != ""} {
                    odfi::closures::doClosure $closure2 1
                }
            }
        }

        ## name format: attributeGroupName.attributeQualified name 
        ## Example: hardaware.software_written
        :public method getAttributeValue qname {
            
            [[:attributes] findOption {string equal [$it name] $qname}] match {
                :some attr {
                    return [$attr value]
                }
                :none {
                    error "Attribute qname does not exist"
                }
            }

        }

        ## name format: attributeGroupName.attributeQualified name 
        ## Example: hardaware.software_written
        :public method getAttribute qname {
            
            ## Determine search group name 
            set splitted [split $qname .]
            set group "default"
            set name $qname
            if {[llength $splitted]>1} {
                set group [lindex $splitted 0]
                set name [lindex $splitted 1]
            } 

            [[:attributes] findOption {string equal [$it groupName].[$it simpleName] $group.$name } ] match {
                :some attr {
                    return $attr
                }
                :none {
                    error "Attribute qname does not exist"
                }
            }

        }

        :public method attributes {groupName closure} {

            ## Create if not existing already 
            #############
            set foundAttributes [lsearch -glob -inline $attributes *$groupName]

            if {$foundAttributes!=""} {
               
               ## Apply Closure 
               $foundAttributes apply $closure

            } else {
                set foundAttributes [::new [namespace parent]::Attributes [lindex [split $this ::] end].$groupName $groupName $closure]

                ## Add to list
                lappend attributes $foundAttributes 

        
            }

            ## Return 
            return $foundAttributes
        }  

        ## Execute closure on each Attributes, with variable name: $attrs
        :public method onEachAttributes closure {

            foreach attrs $attributes {
                odfi::closures::doClosure $closure 1
            }
        }


    }

    ## NX Attributes Container interface for a FlexNode (Storage in tree)
    ################
    nx::Class create AttributesFlexNodeContainer -superclass {AttributesContainerTrait} {

        :public method attributes args {
            return [:shade [namespace current]::Attribute children]
        }

        ## Add the provided attribute Object to the object list
        :public method addAttributeObject obj {
            :addChild $obj
        }
    }

    ## NX Attributes Container for a standalone object 
    ####################
    nx::Class create AttributesStandaloneContainer -superclass AttributesContainerTrait {
        
        :property -accessor public attributes
        
        :method init {} {

            set :attributes [odfi::flist::MutableList new]
            next
        }

        ## Add the provided attribute Object to the object list
        :public method addAttributeObject obj {
            ${:attributes} += $obj
        }
    }


    ## Utilities For attribute functions
    ##############################

    ## The declare attribute procesure allows creating a function to be called sowhere in an attribute container, to add the pseicifed attribute
    proc declareAttribute {fname} {
  
        set attributeName [string trimleft $fname ::]
        set splittedName [split $fname .]

        #puts "base name: $fname"

        ## Get Group part with no ::
        ## Get Function part with no ::
        if {[llength $splittedName]>1} {
            set groupPart [string trimleft [lindex $splittedName 0] ::]
            set functionPart [lindex $splittedName 1]
        } else {
            set groupPart ""
            set functionPart [lindex $splittedName 0]
        }

        #puts "-> Group part $groupPart"
        #puts "-> Function part $functionPart"
        
        ## Check if function name is absolute 
        if {[string match "::*" $functionPart]} {
            set functionAbsolute true
        } else {
            set functionAbsolute false
        }
        set functionPart [string trimleft $functionPart ::]

        ## Check if global absolute name (:: on the left)
        if {[string match "::*" $fname]} {
            set absolute true
        } else {
            set absolute false
        }

        #puts "-> Absolute: $absolute"
        #puts "-> Function Absolute part $functionAbsolute"

        ## Absolute -> function name is group::function 
        ## ! Absolute -> function name is function function 
        if {$absolute} {
            set finalFunctionName [string trimleft "${groupPart}::$functionPart" ::]
        } else {
            set finalFunctionName "$functionPart"
        }
        
        ## Split Function name in Namespace and Name 
        set splittedFinalFunctionName [split [string map {:: :} $finalFunctionName] : ]
        set functionEndName [lindex $splittedFinalFunctionName end]
        set functionNSPartlist [lrange $splittedFinalFunctionName 0 end-1 ]

        ## Namespace Check
        ##  a. If function name is not absolute -> add namespace 
        ##  b. target namespace is the fule path until final function name 

        # a.
        set targetNamespace ""
        if {!$functionAbsolute} {
            set targetNamespace [string trimleft [uplevel namespace current] ::]
            #set finalFunctionName "[string trimleft [uplevel namespace current] ::]::$finalFunctionName"
        }
        # b. add target namespace components to NSpart list 
        set functionNSPartlist [concat [split [string map {:: :} $targetNamespace] ::] $functionNSPartlist]
        #set targetNamespace "$targetNamespace::[join [lrange [split $functionPart $finalFunctionName ] start end-1] ::]"

        #puts "-> Final function end name: $functionEndName"
        #puts "-> Final function NS: ::[join $functionNSPartlist ::] ($functionNSPartlist)"

        ## Fix Group name 
        ## If no group part, and function is not absolute, try to set group to namespace with _
        if {$groupPart=="" && !$functionAbsolute} {
            set groupPart [string map {:: _} [string trimleft [uplevel namespace current] ::]]
        }    

        ## Set group name to group part 
        set groupName ""
        if {$groupPart!=""} {
            set groupName "$groupPart."
        }

        ## Create Function
        set res "namespace eval ::[join $functionNSPartlist ::] {
            proc $functionEndName args {
                
                uplevel 1 :addAttribute $groupName$functionPart \$args 
            }
        }"
        uplevel 1 $res
    
         
 
    } 

}

