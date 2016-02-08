package provide odfi::nx::domainmixin 1.0.0
package require nx 2.0.0
package require odfi::common

namespace eval odfi::nx {



    ## Utilities
    ###################

    proc getAllNXObjectsOfType type {

        set res {}
        foreach object [info commands ::nsf::*] {
            if {[odfi::common::isClass $object $type]} {
                lappend res $object
            }
        }
        #puts "Commands: [info commands ::nsf::*]"
        #set nxObjects [info commands "#_*"]
        return $res
    }

    ## Class/Object  Improvements for Domain mixins 
    ########################

    nx::Class create Object -superclasses nx::Object {
        
    }
    
    
    nx::Class create CommonTrait {
        
        ## Object mixins import
        ###
        :public method "object mixins" {method args} {
            if {$method=="add"} {
             
                ## Call normal next
                next
                
                ## Make sure variables are initialised
                foreach m $args {
                    
                    foreach var [$m info variables] {
                        
                        ## Get Definition of variable/Property
                        set varDef [$m info variable definition $var]
                        
                        ## Property/Variable: element 2 of definition list
                        ## If property: Default value is in the last element, if it is a list
                        ## If variable: Default value is the last element if size of definition is 6
                        switch [lindex $varDef 1] {
                         
                            "property" {
                                if {[llength [lindex $varDef end]]==2} {
                                    set def [lindex $varDef end]
                                    set :[lindex $def end-1] [lindex $def end]
                                }
                            }
                            
                            "variable" {
                                if {[llength $varDef]==6} {
                                    set :[lindex $varDef end-1] [lindex $varDef end]
                                }
                            }
                        }
                        #puts "From mixin $m, variable $varDef"
                        ## if 6 elements, a default value if provided 
                        ## If default value provided, then set it on object
                        
                    }
                    #puts "Adding mixin $m"
                    #set v1 [lindex [$m info variables] 0]
                    #puts "[$m info variables]"
                    
                    #puts "[$m info variable definition $v1]"
                }
                
            } else {
                next
            }
        }
        
        
    }

    nx::Class create Class -superclasses nx::Class {
        
        :method init {} {
          ##
          ## Rewire the default superclass
          ##
          #if {[:info superclasses] eq "::nx::Object"} {
          # :configure -superclasses [namespace current]::Object
          #}
            :configure -mixins [concat [:info mixins] odfi::nx::CommonTrait]
            #namespace import -force ::odfi::nx::* 
        
            #puts "In class init [current object] "
        }
        
       #:public object method create args {
        #   puts "In create for [lindex $args 0]"
        #   ::nsf::methods::class::create $args
        #   
       #}
        
        #:public method var {name {value}} {
        #   :property
        #}
        
        
      }

    
    
    
    ## Field definitions
    
    proc var {name value} {
        
    }
    
    
    namespace export Object Class var

}

namespace eval odfi::nx::domainmixin {

    ### Dynamic Mixin add to current object
    ### If in init, recall init
    proc addMixinsFor {test mixinslist} {

        set foundIndex [lsearch -glob $mixinslist $test]
        if {$foundIndex!=-1} {
            set mixins [lindex $mixinslist [expr $foundIndex+1]]
            set added false
            foreach mixin $mixins {
                ## Add mixin only if not there
                #odfi::log::info "Mixin to add $mixin , available [uplevel :info object mixins]"
                if {[lsearch -glob [uplevel :info object mixins] "*${mixin}*"]==-1} {
                    uplevel :object mixins add $mixin
                    set added true
                }
            }

            ## If added and in init -> recall init
            if {$added} {
                uplevel :init
            }
            #uplevel next
        }

    }

    ## Add Trait slot interface to class
    #::nx::MetaSlot create DomainMixinSlot
    #::nsf::relation DomainMixinSlot superclass ::nx::ObjectParameterSlot
    ::nx::MetaSlot create DomainMixinSlot
    ::nsf::relation::set DomainMixinSlot superclass ::nx::ObjectParameterSlot

    DomainMixinSlot eval  {



      ## Values save
      :variable values {}


      :protected method init {} {
        ::nsf::next
        if {${:accessor} ne ""} {
          :makeForwarder
        }
      }

      :public method value=add {obj prop value {-prefix ""}} {

        #puts "In Add: $obj -> $prop -> $value $prefix "
        set value [string trimleft $value ::]

        ## If No prefix is defined, just add as a mixin
        if {$prefix == ""} {
            $obj mixins add $value
        } else {

            ## Domainise the Mixin path
            set currentClass $value

            #

            ## Get Superclass chain
            set superclasses [list $value]
            while {$currentClass!=""} {


                set currentsuperclass [string trimleft [lindex [$currentClass info superclasses] 0] ::]

                #puts "CurrentClass $currentClass is  [$currentClass info class] -> $currentsuperclass "

                if {$currentsuperclass!="" &&  [$currentsuperclass info class] =="::nx::Trait"  } {
                    lappend superclasses $currentsuperclass
                    set currentClass $currentsuperclass
                } else {
                    set currentClass ""
                    break
                }

            }

            ## Reverse to create parent classes before children
            set superclasses [lreverse $superclasses]

            ## Loop on Classes to create. Those already existing are ignored
            ###########################
            #puts "Superclass chain: $superclasses"
            set nextSuperclass ""
            foreach currentClass $superclasses {

                ## Prepare target name and others
                set superclassCommand ""
                #set classTargetName ::odfi::nx::domainmixin::${prefix}::$currentClass
                set classTargetName ::${currentClass}_$prefix

                ## If existing -> continue
                if {[::nsf::is class $classTargetName]} {
                    continue
                }

                ## Superclass of current is the previous in list
                if {$nextSuperclass!=""} {
                    set superclassCommand "-superclasses ::${nextSuperclass}_$prefix"
                }

                ## Create
                #puts "Domain $prefix: recreating ::$currentClass as $classTargetName in NS [namespace current], methos: [::$currentClass info methods -callprotection all]"

                #namespace eval $prefix {


                    eval "::nx::Class create $classTargetName $superclassCommand"

                    ## Gather Local Methods
                    set localMethods [::$currentClass info methods -callprotection all]
                    #puts "Local methods $localMethods"

                    foreach imethod [::$currentClass info methods -callprotection all] {
                            #puts "importing method $imethod from $currentClass -> "
                            #puts "-> [lrange  [::$currentClass info method definition $imethod]  1 end ]"

                            ## Get Definition 
                            set mdef [lrange  [::$currentClass info method definition $imethod]  1 end]

                            ## Replace Name with prefix
                            set mdef [lreplace $mdef 2 2 "${prefix}:[lindex $mdef 2]"]

                            ## Search for local method calls 
                            set basecode  [lindex $mdef 4]
                            set code $basecode

                            set localCalls [regexp -inline -indices -all {(?:\s+|\[):([\w_.-]+)} $code]
                            #puts "calls of locals for [lindex $mdef 2]: $localCalls"

                            ## Gather all local calls, and filter out non local calls
                            set localCallsToReplace {}

                            foreach {matchIndices matchedCallIndices} $localCalls {
                                #set matchedCallIndices   [lindex $localCall 1]
                                #puts "Called indices: $matchedCallIndices"
                                set matchedCall          [string range $basecode [lindex $matchedCallIndices 0] [lindex $matchedCallIndices 1]]
                                #puts "Called $matchedCall //$localMethods // [lsearch $localMethods $matchedCall]"
                                if {[lsearch $localMethods $matchedCall]>=0} {
                                  #  puts "Replacing $matchedCall"
                                    #set code [string replace $code [lindex $matchedCallIndices 0] [lindex $matchedCallIndices 1] ${prefix}:$matchedCall]
                                    lappend  localCallsToReplace :$matchedCall :${prefix}:$matchedCall
                                    
                                }
                            }

                            ## Replae Code 
                            set code [string map $localCallsToReplace $code]
                            set mdef [lreplace $mdef 4 4 $code]
                            #puts "code after: $code"
                            
                            #puts "importing method $imethod from $currentClass as $mdef "
                            eval "$classTargetName $mdef"
                    }


                #}

                ## Current class is the next superclass
                set nextSuperclass $currentClass
            }

            ## Add The newly recreated domain mixin as standard mixin
            #puts "Finally adding as normal mixin ::${value}_$prefix "
            $obj mixins add ::${value}_$prefix

        }

        ## Add Trait
        #nx::trait::require    $value
        #nx::trait::checkClass $obj $value
        #nx::trait::add        $obj $value -prefix $prefix

        ## Set Relation
        #lappend :values $value
        #::nsf::relation $obj class $value
      }

    }

    DomainMixinSlot create ::nx::Class::slot::domain-mixins \
        -multiplicity 0..n \
        -elementtype class


    ## Add Extra stuff for objects 
    ##################################### 
    ::nx::Object public method isClass test {

        return [odfi::common::isClass [current object] $test]

    }

    ::nx::Object public method notClass test {

        return [expr ! [:isClass $test]]

    }
    
    #### Method chaning 
    ####  - Call a method with args, and the next one on the result of the previous
    ####  Format: > method args > method args 
    ::nx::Object public method @> args {

   
     
        if {[llength $args]==1} {
            set args [lindex $args 0]
        }

        set current [current object]
        while {[llength $args]>0} {

            ## If Index 0 is >, remove it 
            if {[lindex $args 0]=="@>"} {
                set args   [lreplace $args 0 0]
                if {[llength $args]==0} {
                    break
                }
            } 


            ## Get Method
            set method [lindex $args 0]
            set args   [lreplace $args 0 0]

            ## Get Method args, if it is ">", the method has no args so args stays the same for the next iteration
            set methodArgs [lindex $args 0]
            if {$methodArgs== "@>"} {
                set methodArgs {}
            } else {
                set args   [lreplace $args 0 0]
            }

            #puts "Calling $method"

            #puts "Calling $method , with arg $methodArgs , and next is $args"

            ## Call 
            #set result [:$method $methodArgs]
            #::set current [eval "$current $method {$methodArgs}"]
            ::set current [$current $method $methodArgs]

            ## Call next, or return 
            if {[llength $args]>0 && ($current=="" || ![::odfi::common::isClass $current ::nx::Object])} {
                error "Cannot continue call chain $args on non Object result: $current"
            } else {
                ## Keep going 
                #return $result
            }

            #exit 0
        }


        return $current

        

    }
}
