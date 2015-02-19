package provide odfi::nx::domainmixin 1.0.0
package require nx 2.0.0
package require nx::trait
package require nsf


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
      
        puts "In Add: $obj -> $prop -> $value "
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

                puts "CurrentClass $currentClass is  [$currentClass info class] -> $currentsuperclass "

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
            puts "Superclass chain: $superclasses"
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
                #puts "Domain $prefix: recreating ::$currentClass in NS [namespace current]"

                #namespace eval $prefix {


                    eval "::nx::Class create $classTargetName $superclassCommand"
                    foreach imethod [::$currentClass info methods -callprotection all] {
                            #puts "importing method $imethod from $currentClass -> "
                            #puts "-> [lrange  [::$currentClass info method definition $imethod]  1 end ]"
                            set mdef [lrange  [::$currentClass info method definition $imethod]  1 end]
                            set mdef [lreplace $mdef 2 2 "${prefix}:[lindex $mdef 2]"]
                            #puts "importing method $imethod from $currentClass as $mdef "
                            eval "$classTargetName $mdef"
                    }
                   

                #}

                ## Current class is the next superclass 
                set nextSuperclass $currentClass
            }

            ## Add The newly recreated domain mixin as standard mixin 
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

}
