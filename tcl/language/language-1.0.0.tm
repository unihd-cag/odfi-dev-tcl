package provide odfi::language 1.0.0
package require odfi::closures  3.0.0
package require odfi::flist     1.0.0
package require odfi::flextree  1.0.0
package require odfi::nx::domainmixin 1.0.0

namespace eval odfi::language {

    variable debug false

    
    ## Closure Line stack to know where we are
    variable closureLines {}
    
    proc getCurrentClosureLine args {
        
        #puts "Current lines [:closureLines get]"
        set total 0 
        foreach v ${::odfi::language::closureLines} {
            incr total $v
        }
        return $total
    
    }

    ##################
    ## Real Def
    ######################
    nx::Class create Language -superclasses odfi::flextree::FlexNode {

        :variable classStack 1
        :property -accessor public {+targetNamespace ""}
        :property -accessor public {+name "default"}

        :method init args {
            set :classStack [odfi::flist::MutableList new]
            set :+targetNamespace [uplevel  namespace current]
            if {${:+targetNamespace}=="::"} {
                set :+targetNamespace ""
            }
            next
        }

        ## Util Type Resolution
        ## converts to a valid type in targetNamespace if necessary or returns an error 
        :public method resolveType base {

            ## If a Type 
            if {[::nsf::is class $base]} {
                return $base 
            } elseif {![string match "::*" $base]} {
                ## Try targetNamespace ::$targetNamespace
                ## Otherwise Error 
                set testType ${:+targetNamespace}::$base 
                if {[::nsf::is class $testType]} {
                    return $testType
                } else {
                    ##error "Type $base cannot be found as existing type or in target namespace ${:+targetNamespace}"
                    return $base
                }
            }
            return $base
        }
 

        ## Builder
        :public object method define {name closure} {

            ## Find Namespace  in name 
            set finalNS [split [string map {:: :} $name ] :]
            set name    [lindex $finalNS end]
            

            ## If fully defined, use it as is, otherwise add caller context 
            if {[llength $finalNS]==0 || [lindex $finalNS 0]!=":"} {
                set finalNS [uplevel namespace current]::[join $finalNS ::]
            } else {
                set finalNS [join $finalNS :]
            }

           # puts "Creating language $name in $finalNS"
            #namespace eval $finalNS "
          #          
            #        odfi::language::Language create $name -+name $name
           #         $name apply [list $closure]
#
#
           # "

            #return 
            uplevel odfi::language::Language create $name -+name $name
            uplevel $name apply [list $closure]
        }

        :public object method default closure {
            set l [uplevel odfi::language::Language new]
            uplevel [list variable language $l]
            uplevel [list $l apply $closure]
            uplevel [list $l produceNX]
            
        }

        ## Language Search Operation
        ################
        :public method onType {name cl}  {

            set t [:shade odfi::language::Type findChildByProperty +simpleName $name] 
            if {$t==""} {
                error "Cannot find type $name in language"

            }

            return [$t apply $cl]
        }
 
        ## Language/Types definitions
        ##############################

        :public method +type {name args} {

            ## Prepare type name
            ###############
            set splittedTypeName [:splitTypeName $name $args]
            #puts "For type $name, splitted: $splittedTypeName"

            set typeName [[:getRoot] cget -+targetNamespace]::$name

            ## Target Namspace is either in caller, or already set on top language
            set targetNamespace [[:getRoot] cget -+targetNamespace]
            if {$targetNamespace==""} {
                set targetNamespace [uplevel 2 namespace current]
            }
            set typeName [lindex $splittedTypeName 1]
            set targetType [lindex $splittedTypeName 2]
            set args [lindex $splittedTypeName end]
            
            ## If Exists, only set on current type as superclass, otherwise create
            #set searchRes [[[:getRoot] children] findOption {return [expr [$it cget -+name] == $typeName] }]
            set searchRes [[[:getRoot] children] findOption {
                
                #puts "Comparing: [$it cget -+name] with $typeName"
                if {[$it cget -+name] == $typeName} {
                    return true
                } 
                return false
            }]
            $searchRes match {
                :some val {
                    
                    #puts "Adding superclass to [:info class] -> [:cget -+name]"
                    lappend :+superclasses $typeName 
                }
                :none {
                    
                    ## Create Type definition
                    #puts "TD: [namespace current]"
                    ##puts "Target NS: [uplevel 2 namespace current]"
                    set newType [LanguageElement new -+name ${targetNamespace}::$name -+originalName $name]
        
                    ## Add Type to language
                    :addChild $newType
                    
                    ## Set super type 
                    if {[llength $targetType]>0} {
                        $newType +superclasses set [lindex $targetType 0]
                    }

                    ## Apply Closure
                    if {[llength $args] >0} {
                        $newType apply [lindex $args 0]
                    }
                    
        
                    return $newType
                    
                }
                
            }
            ##puts "Creating type: $typeName"
            #if {![::nsf::is class $typeName]} {
            #    
            #    
            #    
            #}
            
            
        }

        ## Hierarchy Stack

        :public method apply closure {
            
            set closure [regsub -line -all {(^|;)\s*\+} $closure {:+}]
            set __l [odfi::closures::buildITCLLambda $closure]
            try {
                $__l apply
            } finally {
                odfi::closures::redeemITCLLambda $__l
            }
            #puts "Replaced closure: $closure"
         #   ::odfi::closures::run $closure
            #next -cl $closure
            #next $closure
        }

        ## Return: ClassName canonicalName SuperClass args
        :method splitTypeName {input args} {

            ## Try to determine target Type in method name
            ##  1. TYPE.languagename args
            ##  2. languagename : TYPE args
            ####################
            set targetNamespace [[:getRoot] cget -+targetNamespace ]
            set args [lindex $args 0]
            set targetType ""
            set languageElementName $input
            
            ## Cover TYPE.languageName
            regexp {([\w_]+)\.(.+)} $input -> targetType languageElementName
            
            ## Cover languagename : TYPE -> Take : and TYPE out from args
            if {[llength $args] >= 2 && [lindex $args 0]==":"} {
                set targetType [lindex $args 1]
                set args [lrange $args 2 end]
            }
            
            ## Target Type might be of format:
            ##  LANGUAGEGROUP.TYPE
            # ([\w_-]+)(?:\.([\w_-]+))?
            regexp {(?:([\w_-]+)\.)?([\w_:-]+)} $targetType ->  baseLanguage targetType
            if {[catch {::set baseLanguage} res] || $baseLanguage==""} {
                set baseLanguage [:getRoot]

            } else {
                set baseLanguage ${targetNamespace}::$baseLanguage
            }

            ## Check target Type
            ## If it is not defined in absolte, look in the base language children if it is a defined type
             #puts "Calling $called_method and checking target Type: $targetType"
            if {$targetType!="" && ![string match ::* $targetType] } {
                set targetType ${targetNamespace}::$targetType
                set searchRes [[$baseLanguage children] findOption {
                                
                    #puts "Comparing: [$it cget -+name] with $typeName"
                    if {[$it cget -+name] == $targetType} {
                        return true
                    } 
                    return false
                }]
                
                $searchRes match {
                    :some val {
                    }
                    :none {
                        
                        #error "Creating Language Element $languageElementName with type $targetType, but $targetType has not been created previously"
                        
                    }
                    
                }
            } 

            ##
            
            #puts "Calling $called_method + args leads to $targetType and $languageElementName"
        
            
            

            ## Create Class Name
            ################
            set className [string toupper $languageElementName 0 0]
            set canonicalName ${targetNamespace}::$className

            return [list $className $canonicalName $targetType $args]

        }

        ## Unknown method used to create class
        #######
        
        
        ## Method
        :method unknown {called_method args} {
        
            #puts "Unknown method '$called_method' called -> [::odfi::common::findFileLocationSegments]"
            
            ## Get File Locations and closure line
            ########################
            set fileSegments [::odfi::common::findFileLocationSegments]
            
            ## First entrwy of files is this API, so take next one
            set fileAndLine [lindex $fileSegments 1] 
            
            ## Caller frame tells us where we are in the closure
            ## Look for all Unknown method calls up to sum up the final line
            set closureLine [dict get [info frame -1] line] 
            lappend ::odfi::language::closureLines $closureLine
            
            #set code    [info frame -6]
            #puts "In Closure line: [dict get $inLine line] -> [dict get $code cmd]"

            set targetNamespace [[:getRoot] cget -+targetNamespace ]
            
            ## Try to determine target Type in method name
            ##  1. TYPE.languagename args
            ##  2. languagename : TYPE args
            ####################
            set targetType ""
            set languageElementName $called_method
            
            ## Cover TYPE.languageName
            regexp {([\w_]+)\.(.+)} $called_method -> targetType languageElementName
            
            ## Cover languagename : TYPE -> Take : and TYPE out from args
            if {[llength $args] >= 2 && [lindex $args 0]==":"} {
                set targetType [lindex $args 1]
                set args [lrange $args 2 end]
            }
            
            ## Target Type might be of format:
            ##  LANGUAGEGROUP.TYPE
            # ([\w_-]+)(?:\.([\w_-]+))?
            regexp {(?:([\w_-]+)\.)?([\w_:-]+)} $targetType ->  baseLanguage targetType
            if {[catch {::set baseLanguage} res] || $baseLanguage==""} {
                set baseLanguage [:getRoot]

            } else {
                set baseLanguage ${targetNamespace}::$baseLanguage
            }

            ## Check target Type
             #puts "Calling $called_method and checking target Type: $targetType"
            if {$targetType!="" && ![string match ::* $targetType] } {
                set targetType ${targetNamespace}::$targetType
                set searchRes [[$baseLanguage children] findOption {
                                
                    #puts "Comparing: [$it cget -+name] with $typeName"
                    if {[$it cget -+name] == $targetType} {
                        return true
                    } 
                    return false
                }]
                
                $searchRes match {
                    :some val {
                    }
                    :none {
                        
                        #error "Creating Language Element $languageElementName with type $targetType, but $targetType has not been created previously"
                        
                    }
                    
                }
            } 

            ##
            
            ## Create Class Name
            ################
            set root [:getRoot]
            #puts "root $root"
            
            set className [string toupper $languageElementName 0 0]
            set canonicalName ${targetNamespace}::$className
            #set targetNamespace [uplevel 2 namespace current]

            ## Gather generic arguments
            ########################
            
            ## Last argument in args may be the configuration closure for the language element
            set configClosure ""
            if {[llength $args]>0 && [string is list [lindex $args end]]} {
                #puts "Found config closure"
                set configClosure [lindex $args end]
                set args [lrange $args 0 end-1]
            }

            set realArgs {}
            foreach arg $args {
                #puts "Arg: $arg -> [string is alnum $arg]"
                if {[string is alnum $arg]} {
                    lappend realArgs $arg
                } elseif {[llength $arg]==1} {

                    ## this is maybe redundant to first case 
                    lappend realArgs [lindex $arg 0]

                } elseif {[llength $arg]==2} {
                    lappend realArgs $arg
                }
            }

            #odfi::log::fine "Real args for $canonicalName: [list $realArgs args] // $args"



            ## Create Type for the name
            ########
            #puts "Creating Type: $canonicalName"
            set newType [LanguageElement new -+name $canonicalName -+originalName $languageElementName] 
            
            ## Record File locations
            $newType file set [lindex $fileAndLine 0] 
            $newType line set [expr [lindex $fileAndLine 1] + [::odfi::language::getCurrentClosureLine]]
            
            ## Set type: Target type and FlexNode  
            try {       
                $newType apply {
                    if {$targetType!=""} {
                        lappend :+superclasses $targetType
                    } else {
                        lappend :+superclasses ::odfi::flextree::FlexNode
                    }
                    
                    #if {$targetType=="" || [llength [ $targetType info superclasses -closure ::odfi::flextree::FlexNode]==0]} 
                       
                    #
                   
                }
            
           
         
                #$newType object mixins add LanguageElement
                
                ## Method arguments are to be type vars
                ##########
                foreach arg $realArgs {
                    if {[llength $arg]==1} {
                        $newType apply {
                            :+var $arg
                        }
                    } else {
                        puts "---> Adding parameter arg [lindex $arg 0] [lindex $arg 1]"
                        $newType apply {
                            :+var [lindex $arg 0] [lindex $arg 1]
                        }
                    }
                    
                }
                
                ## Add Type to current parent
                :addChild $newType
                
                ## Apply Configuration to current Type
                $newType apply $configClosure
            
            } finally {
                ## Remove current line for current type from stack
                set ::odfi::language::closureLines [lrange ${::odfi::language::closureLines} 0 end-1]
            }
            return 
            ## Add Type to current stack or top language
            ################
            if {[${:classStack} size] >0} {
                
                [${:classStack} peek] addChild $newType
            } else {
                
                :addChild $newType
            }

            ## Stack and Configure
            ##########
            ${:classStack} push $newType

            :apply $configClosure

            ## UnStack
            ${:classStack} pop
        }

    }

    ## Type Definition
    ###########################
    nx::Class create Type  -superclasses odfi::flextree::FlexNode {

        :property -accessor public +name:required
        :property -accessor public +simpleName
        :property -accessor public +superclasses
        :property -accessor public +mixins

        :property -accessor public +mergeWith

        :property -accessor public +builders
        
        :property -accessor public {file ""}
        :property -accessor public {line 0}

        :method init args {

            next

            set :+superclasses {}
            set :+mixins {}
            set :+simpleName [lindex [split ${:+name} :] end]
            set :+builders {}
            set :+mergeWith false

            
        }

        ## Define Builders For instances 
        ##############
        :public method +builder closure {
            #puts "Adding builder: $closure"
            
            ## Get File Locations and closure line
            ########################
            set fileSegments [::odfi::common::findFileLocationSegments]
            
            ## First entrwy of files is this API, so take next one
            set fileAndLine [lindex $fileSegments 1] 
            
            ## Caller frame tells us where we are in the closure
            ## Look for all Unknown method calls up to sum up the final line
            set closureLine [dict get [info frame -1] line] 
            
            set absoluteLine [expr [lindex $fileAndLine 1] + $closureLine - 1  + [::odfi::language::getCurrentClosureLine]]
            
            #puts "+builder at $absoluteLine ( [::odfi::language::getCurrentClosureLine]) <- $fileAndLine"
            
            lappend :+builders [list [::odfi::closures::declosure $closure]  [lindex $fileAndLine 0]  $absoluteLine  ]
        }

        ## Create a Class Field 
        ############
        :public method +var {name args} {

            ## Create Var Def
            set newVar [TypeVar new -+name $name]

            ## Add
            :addChild $newVar

            #puts "Adding var $newVar $name -> $args"

            ## Apply
            if {[llength $args]>0} {
                
                ## old regexp: {^[A-Za-z0-9_.-/\]+$}
                if {$args=="{}"|| $args=="" || [regexp {^[^\s]+$} $args]} {
                    #puts "Default for $name -> $args"
                    $newVar +default $args
                } else {
                    $newVar apply [lindex $args 0]
                    
                }
            } else {
                $newVar +required set true
            }
            

            return $newVar
        }
        
        ## Create a Class Constant (object variable) 
        ############
        :public method +constant {name value} {

            ## Create Var Def
            set newConstant [TypeConstant new -+name $name -+value $value]

            ## Add
            :addChild $newConstant

            #puts "Adding var $newVar $name -> $args"
            return $newConstant
        }
        
        ## Create a Class Method 
        ####################
        :public method +method {name args body} {

            ## Get File Locations and closure line
            ########################
            set fileSegments [::odfi::common::findFileLocationSegments]
            set fileAndLine [lindex $fileSegments 1] 
            set closureLine [dict get [info frame -1] line] 
            set absoluteLine [expr [lindex $fileAndLine 1] + $closureLine - 1  + [::odfi::language::getCurrentClosureLine]]

            set typeMethod [TypeMethod new -+name $name -+args $args -+body [::odfi::closures::declosure $body] -+file [lindex $fileAndLine 0] -+line $absoluteLine]

            :addChild $typeMethod

            return $typeMethod

        }
        
        ## Create an Object Method 
        ####################
        :public method +objectMethod {name args body} {

            set typeMethod [TypeObjectMethod new -+name $name -+args $args -+body $body]

            :addChild $typeMethod

            return $typeMethod

        }
        
        ## Create a Class Method In Target Container
        ####################
        :public method +targetMethod {name args body} {

            set typeMethod [TypeMethod new -+name $name -+args $args -+body $body -+target true]

            :addFirstChild $typeMethod

            return $typeMethod

        }

        ## Add Mixin to Class
        ## args can be:
        ##   -  only the class name 
        ##   -  prefix <- className
        ######################
        :public method +mixin args {


            set argsCount [llength $args ]
            if {$argsCount >= 1 && $argsCount < 3} {
                if {$argsCount==1} {
                    lappend :+mixins [[:getRoot] resolveType [lindex $args 0]]
                } else {
                    lappend :+mixins [list [[:getRoot] resolveType [lindex $args 0]] [lindex $args 1] ]
                }
                

            } elseif {$argsCount>=3} {
                lappend :+mixins [list [lindex $args 0] [lindex $args 2] ]
            }
            

        }

        :public method +superclass args {

            foreach cl $args {

                ## Add target namespace if class name is relative 
                if {![string match "::*"  $cl ]} {
                    set targetNamespace [[:getRoot] cget -+targetNamespace ]
                    lappend :+superclasses ${targetNamespace}::$cl
                } else {
                    lappend :+superclasses $cl
                }

                
            }

        }

        ## Add merge parameter
        ## Merge will use the provided property to find an existing similar object and configure this previously existing object instead of creating a new one
        :public method +mergeWith name {

            set :+mergeWith $name
        }

        :public method apply closure {
            
            set closure [regsub -line -all {(^|;)\s*\+} $closure {:+}]
            #puts "Replaced closure: $closure"
            #::odfi::closures::run $closure
            #next -cl $closure
            next
        }

    }

    ## Variable in Type definition
    nx::Class create TypeVar  -superclasses odfi::flextree::FlexNode {

        :property -accessor public +name
        :property -accessor public {+default ""}
        :property -accessor public {+required false}
        :property -accessor public {+multiple false}


        :method init args {
            next
            set :+superclasses {odfi::flextree::FlexNode}
            
        }


        :public method +default val {
            set :+default $val 
            set :+required false
        }

    }
    
    ## Constant in Type definition, aka Object variable
    nx::Class create TypeConstant  -superclasses odfi::flextree::FlexNode {
        
        :property -accessor public +name
        :property -accessor public +value

        :method init args {
            next
            set :+superclasses {odfi::flextree::FlexNode}
            
        }

    }
    nx::Class create TypeMethod  -superclasses odfi::flextree::FlexNode {

        :property -accessor public +name
        :property -accessor public +args
        :property -accessor public +body
        :property -accessor public {+target false}
        :property -accessor public {+file -1}
        :property -accessor public {+line 0}

    }
    
    nx::Class create TypeObjectMethod  -superclasses odfi::flextree::FlexNode {
   
           :property -accessor public +name
           :property -accessor public +args
           :property -accessor public +body
           :property -accessor public {+target false}
   
       }
    
    ## Marker for types that are part of the language
    nx::Class create LanguageElement -superclasses {Type Language} {
        

        ## The original name of the element, as stated in language definition
        :property -accessor public +originalName:required

        ## Expose property means the created language model should be set as variable in caller context
        :property -accessor public {+expose false}

        ## Expose To Object property means the created language model should be set as object variable
        :property -accessor public {+exposeToObject false}

        ## Export to parent will add a builder to the parent type
        :property -accessor public {+exportToParent false}

        ## Export to will add a builder to the target type with the set prefix
        :property -accessor public {+exportTo {}}

        ## Export to Public will force creation of a public builder
        :property -accessor public {+exportToPublic false}

        ## If unique is set to a property name, look for a child with that property before creating a new object
        :property -accessor public {+unique false}


        :method init args {
            next
            :+var +originalName ${:+originalName}
        }
        
        :public method +expose {{arg 0}} {
            set :+expose $arg
        }

        :public method +exposeToObject {{arg 0}} {
            set :+exposeToObject $arg
        }

        :public method +exportToParent args {
            set :+exportToParent true
        }

        :public method +exportToPublic args {
            set :+exportToPublic true
        }

        ## Add a new export to entry 
        :public method +exportTo {type {prefix ""}} {
            lappend :+exportTo [list $type $prefix]
        }

        :public method +unique property {
            set :+unique $property
        }
        
    }
    
    

    ###############################
    ## NX Producer
    ###############################
    nx::Class create NXProducer {

        Language mixins add NXProducer

        :public method produceNX args {

            #puts "Producing NX Class"
            :walkDepthFirstPreorder {

                #puts "Start node [$node info class]"

                if {[$node info has type ::odfi::language::Type]} {

                    ## Type
                    ##################

                    #puts "Node $node [$node cget -+name] <- $parent"

                    #### Create Class
                    #########################
                    
                    set className [$node cget -+name]
                    

                    ## Gather Superclasses

                    ## Do Create Class

                   # #puts "Superclasses are [llength [split ]]"
#                    set scs {}
#                    foreach sc  [split [$node cget -+superclasses]] {
#                        lappend scs $sc
#                    }
                    set superclasses {}
                    if {[llength [$node cget -+superclasses ]]>0} {
                        set superclasses "{[$node cget -+superclasses]}"
                    } else {
                        set superclasses odfi::flextree::FlexNode
                    }

                    #puts "Creating Class $className -superclasses $superclasses"

                    #### Builders 
                    #set buildingCode [join [$node cget -+builders] \n]
                    #$buildingCode
                    eval "nx::Class create $className -superclasses $superclasses {
                        
                        :object variable -accessor public -incremental +builders:0..n  {}

                        :public method init args {
                            next 
                            :registerEventPoint buildDone
                        }
                        :public method +build args {
                            next 
                            #puts \"inside building of \[:info class\] (for level $className): \"
                           
                            try {
                                foreach b \[$className +builders get\] {
                                    #puts \"B \$b\"
                                    try {
                                        eval \$b
                                    } on return {res resOptions} {

                                    }
                                }

                            }  finally {

                                

                                ## Builder done
                                ## Event poitn called by Builder Trait when building is really done (after builders and configuration closure)
                                #:callBuildDone

                            }
                           
                             
                        }



                        #:public method +builder code {
                        #    
                        #}
                        :public object method +builder code {
                            #puts \"Recording builder \$code\"
                            lappend :+builders \$code
                            #$className +builders add \$code
                        }

                        :public method +getClassSimpleName args {
                            return [lindex [split [$node cget -+originalName] ::] end]
                        }

                        
                    }"
                    
                    ::set i 0
                    foreach bc [$node cget -+builders] {

                        #puts "Setting BC $bc"
                        
                        ::set builder [lindex $bc 0]
                        ::set bfile   [lindex $bc 1]
                        ::set line    [lindex $bc 2]
                        $className +builder $builder
                        
                        ## Record builder in error tracer
                        ##################
                        if {![catch {package present odfi::errortracer}]} {
                            if {[file exists $bfile]} {
                                #puts "NX: Error tracer loaded and file has been recorder"
                                #puts "Outputing $methodName to [$node cget -file]:[$node cget -line] produces ${className}"
                                ::odfi::errortrace::recordProcWithOutputType ${className}::builder$i $bfile $line ${className}
                            }
                        }
                        
                        ::incr i
                        
                    }

                    #### Mixins
                    foreach mixin [$node cget -+mixins] {
                    
                       
                    
                        if {[llength $mixin]==1} {
                        
                           # puts "Adding mixin $mixin to $className"
                           
                            ## Adapt Mixin Class 
                            ## Don't touch if absolute, add target namesapce if not
                            if {[string match ::* $mixin]} {
                                $className mixins add $mixin
                            } else {
                                $className mixins add [join [lrange [split $className ::] 0 end-1] :]:$mixin
                            }
                            
                        } else {
                        
                           # puts "Adding mixin [lindex $mixin 1] to $className with prefix [lindex $mixin 0]"
                            
                            ## Import using domain mixin
                            $className domain-mixins add [lindex $mixin 0] -prefix [lindex $mixin 1]
                        }
                        
                    }

                    #### To String back as language 
                    ##################
                    #set classNameFirstLower [string tolower $className 0 0]
                    #$className public method toLanguageString args


                
                    ## If it has a Type parent, create builder in Parent
                    ## Otherwise, create top level builder
                    if {[odfi::common::isClass $node ::odfi::language::LanguageElement]} {

                        ## Create BuilderTrait
                        #############
                        
                        ## Name of method has only first character low
                        set methodName [string tolower $className]

                        ## Gather Required Type Variables
                        set realArgs {}
                        set constructorArgs {}
                        $node shade odfi::language::TypeVar eachChild {
                            #puts "Testing TypeVar $it"
                            if {[$it cget -+required]==true} {
                                lappend realArgs [$it cget -+name]
                                lappend constructorArgs -[$it cget -+name] \$[$it cget -+name]
                            }
                        }
                        set constructorArgs [join $constructorArgs]

                        ## Expose code ?
                        ## Expose argument can be :
                        ##   - false to deactivate
                        ##   - An number to indicate the input parameter to use 
                        ##   - A text string to indicate the object variable to use
                        set exposeCode ""
                        if {[$node cget -+expose]!=false} {
                            set exposeArg [$node cget -+expose]
                            if {[string is integer $exposeArg ]} {
                                if {$exposeArg>[expr [llength $realArgs]-1]} {
                                    error "Creating language element ${className}, the expose switch was set for builder argument $exposeArg, but language definition only specifies [llength $realArgs] builder arguments"
                                } else {
                                    set exposeCode "uplevel set [lindex $realArgs $exposeArg] \$inst"
                                    #odfi::log::fine "expose code: $exposeCode"
                                }
                                } else {
                                    set exposeCode "uplevel set \[\$inst cget -$exposeArg\] \$inst"
                                    #odfi::log::fine "expose code: $exposeCode"
                                }
                            
                        }

                        ## Expose to Object Code
                        ## Same as Expose Code, but on object 
                        set exposeToObjectCode ""
                        if {[$node cget -+exposeToObject]!=false} {
                            set exposeArg [$node cget -+exposeToObject]
                            if {[string is integer $exposeArg ]} {
                                if {$exposeArg>[expr [llength $realArgs]-1]} {
                                    error "Creating language element ${className}, the expose to Object switch was set for builder argument $exposeArg, but language definition only specifies [llength $realArgs] builder arguments"
                                } else {

                                    set exposeToObjectCode "\[current object\]  object variable  -accessor public [lindex $realArgs $exposeArg] \$inst"
                                    #set exposeCode "uplevel set [lindex $realArgs $exposeArg] \$inst"
                                    #odfi::log::fine "expose code: $exposeCode"
                                }
                                } else {

                                    set exposeToObjectCode "
                                    #puts \"Exposing to object using \[\$inst cget -$exposeArg\] \"
                                    \[current object\] object variable -accessor public \[\$inst cget -$exposeArg\] \$inst"
                                    #set exposeCode "uplevel set  \$inst"
                                    #odfi::log::fine "expose code: $exposeCode"
                                }
                            
                        }
                        #if {[string match "*Input*" $className]} {
                        #    puts "For input, expost to object code [$node cget -+exposeToObject] is: $exposeToObjectCode"
                        #}

                        ## Unique Code 
                        #######################
                        set uniqueCode ""
                        if {[$node cget -+unique]!=false} {
                            set uniqueArg [$node cget -+unique]

                            set uniqueCode "
                            ::set existing \[:shade [$node cget -+name] findChildByProperty $uniqueArg \$$uniqueArg \]
                            #puts \"Unique res [$node cget -+name]: \$existing looking for $uniqueArg \$$uniqueArg\"
                            if {\$existing!=\"\"} {
                                return \$existing
                            }"

                        }

                        ## Merge Code: Create instance code either just creates, or uses the provided paramter to find similar objects
                        ################
                        ::set createInstanceCode "::set inst \[[$node cget -+name] new $constructorArgs\]"
                        if {[$node cget -+mergeWith]!=false} {

                            set mergeWithParameterName [$node cget -+mergeWith]

                            ::set createInstanceCode "

                            ## Create instance, because parameter can have a default value not set in constructor args
                            ## Then search for existing
                            $createInstanceCode
                            ::set existing \[:shade [$node cget -+name] findChildByProperty $mergeWithParameterName \[\$inst $mergeWithParameterName get\] \]

                            ## If Existing has been found, replace inst with the existing one
                            if {\$existing!=\"\"} {
                                ::set inst \$existing
                            }"

                            #puts "Class [$node cget -+name] has merge with $mergeWithParameterName, creation code is: \n $createInstanceCode"
                        }

                        ## The Builder is mixed in to targets to provide element creation and retrieval
                        ::nx::Class create ${className}Builder {

                            upvar realArgs realArgs
                            upvar constructorArgs constructorArgs
                            upvar node node

                            ## Method name: Original Name from language definition
                            #set methodName [lindex [split [$node cget -+name] ::] end]
                            #if {[llength $methodName]==1 || ![string is upper $methodName]} {
                            #    set methodName [string tolower $methodName 0 0]
                            #}
                            set methodName [lindex [split [$node cget -+originalName] ::] end]
                            
                            #puts "Creating builder method $methodName -> {$realArgs args}"
                            set builderMethod "
                            :public method  $methodName {$realArgs args} {
                                
                                
                                
                                ## Get Closure and Parameters overwrite
                                ::set overwrites {}
                                ::set cl {}
                                if {\[llength \$args\] >0} {

                                    ## Closure is the last arg 
                                    ::set cl \[lindex \$args end\]
                                    ::set args \[lrange \$args 0 end-1\]  

                                    #puts \"---> CL is \$cl\"
                                    ## overwrite
                                    ::set overwrites \[split \$args\]

                                }

                                #set overwrites {-iocount 5}
                                #puts \"In [$node cget -+name] builder with $constructorArgs and overwrites \$overwrites \"

                                ## Return existing ? 
                                $uniqueCode

                                ## Create instance
                                $createInstanceCode
                                #::set inst \[[$node cget -+name] new $constructorArgs\]
                                
                                #puts \"Created instance [$node cget -+name] \$inst\"
                                
                                foreach {n v} \$overwrites {
                                    #puts \"Overwrite \$n\"
                                    \$inst \[string range \$n 1 end\] set \$v
                                }

                                ##Expose ? 
                                $exposeCode
                                $exposeToObjectCode
                                
                                :addChild \$inst

                                \$inst +build

                                #puts \" instance [$node cget -+name] after build \$inst\"


              
                                ## Apply Closure
                                ::unset args
                                \$inst apply \$cl
                                \$inst callBuildDone
                                
                                

                                return \$inst
                                
                            }"
                            eval $builderMethod
                            #puts "Created builder method: $builderMethod"
                            
                          
                            
                        }

                        #puts "For ${className}Builder to [$node cget -+exportToParent]"
                        
                        ## Inject Builder trait to parent type
                        #################
                        if {[$parent info has type ::odfi::language::Type]} {

                           
                            #puts "Exporting ${className}Builder to  [$parent cget -+name]"
                            [$parent cget -+name] mixins add ${className}Builder
                            
                            
                            ## Also Add all Methods tagged as "target"
                            ##############
                            [$node shade ::odfi::language::TypeMethod children] @> filter {return [$it +target get]} @> foreach {
                                                  
                                [$parent cget -+name] public method [$it cget -+name] [$it cget -+args] [$it cget -+body]
                            }

                        }
                        

                        ## Export to Parent Class Type
                        ###################
                        if {[$node cget -+exportToParent]==true} {

                            ## Inject trait to superclass type
                            ## If parent namespace differs from exporting, make sure namespace is added
                            #################

                            set parentNS    [string map {:: :} [join [lrange [split [$node cget -+superclasses] :] 0 end-2] :] ]
                            set localNS     [string map {:: :} [join [lrange [split $className :] 0 end-2] :] ]
                            if {$parentNS==$localNS} {
                                #puts "Exporting ${className}Builder to superclass [$node cget -+superclasses], parent NS is $parentNS local namespace is $localNS"
                                [lindex [$node cget -+superclasses] 0] mixins add ${className}Builder
                            } else {
                                
                                
                                ## Look for parent part inside local type NS 
                                set parentIndex [string first $parentNS $localNS]
                                set prefix [string range $localNS 1 end]
                                if {$parentIndex!=-1} {
                                    set prefix [string range $localNS $parentIndex end]
                                }

                                #puts "Exporting ${className}Builder to superclass [$node cget -+superclasses] with prefix $prefix, parent NS is $parentNS local namespace is $localNS"
                                [lindex [$node cget -+superclasses] 0] domain-mixins add ${className}Builder -prefix $prefix 

                            }
                            

                        } 

                        

                        if {[$node cget -+exportToPublic]!=false} { 

                            set methodName [string tolower [$node cget -+name]]
                            
                            ## Error Tracer
                            ##################
                            if {![catch {package present odfi::errortracer}]} {
                                if {[file exists [$node cget -file]]} {
                                    #puts "NX: Error tracer loaded and file has been recorder"
                                    #puts "Outputing $methodName to [$node cget -file]:[$node cget -line] produces ${className}"
                                    ::odfi::errortrace::recordProcWithOutputType $methodName [$node cget -file] [$node cget -line] ${className}
                                }
                            }


                            ## Create Public Builder 
                            ###############
                            
                            #puts "Creating public builder: $methodName -> $realArgs // [join $constructorArgs] // exp code: $exposeCode"
                            set pBuilder "proc $methodName {$realArgs args} {
                                
                                ## Get Closure and Parameters overwrite
                                set overwrites {}
                                set cl {}
                                if {\[llength \$args\] >0} {

                                    ## Closure is the last arg 
                                    set cl \[lindex \$args end\]
                                    set args \[lrange \$args 0 end-1\]  

                                    #puts \"---> CL is \$cl\"
                                    ## overwrite
                                    set overwrites \[split \$args\]

                                    ##
                                    #\$inst apply \[lindex \$args 0\] 
                                }

                                ## Create instance of class
                                set inst \[${className} new [join $constructorArgs]\]
                                foreach {n v} \$overwrites {
                                    #puts \"Overwrite \$n\"
                                    \$inst \[string range \$n 1 end\] set \$v
                                }
                                \$inst +build

                                #puts \"Created ${className} with \$name\"

                                ##Expose ? 
                                $exposeCode
                                $exposeToObjectCode

                                ## Apply Closure
                                ::unset args
                                \$inst apply \$cl
                                \$inst callBuildDone
                                
                                
                                
                                return \$inst
                            }" 
                            #puts "Created builder  $pBuilder"
                            eval $pBuilder

                        }

                        
                        
                        

                    } elseif {[odfi::common::isClass $node ::odfi::language::LanguageElement]} {
                        
                        ## Gather Required Type Variables
                        set realArgs {}
                        set constructorArgs {}
                        $node shade odfi::language::TypeVar eachChild {
                            #puts "Testing TypeVar $it"
                            if {[$it cget -+required]==true} {
                                lappend realArgs [$it cget -+name]
                                lappend constructorArgs -[$it cget -+name] \$[$it cget -+name]
                            }
                        }
                        
                        puts "Creating builder: [string tolower ${className}] -> $realArgs // [join $constructorArgs]"
                        eval "proc [string tolower ${className}] {$realArgs args} {
                            
                            ## Create instance of class
                            set inst \[${className} new [join $constructorArgs]\]
                        
                            #puts \"Created ${className} with \$name\"

                            ## Apply Closure
                            if {\[llength \$args\] >0} {
                                \$inst apply \[lindex \$args 0\] 
                            }
                            
                            
                            return \$inst
                        }"                        
                        
                    }

                    ## Common Type: 
                    ##  - Create Methods and fields, exports 
                    ##############################

                    ## Type Var
                    ##################
                    [$node shade ::odfi::language::TypeVar children] foreach {
                       
                            #puts "Doign type var [$node info class] $it"
                            #puts "Add Type parameter [$node cget -+name] to [$parent cget -+name] -> [$node cget -+required]"
                            ## FIXME improve required/multivalue ifs 
                            if {[$it cget -+required]==true} {

                                if {[$it cget -+multiple]==true} {
                                    [$node cget -+name] property -accessor public [$it cget -+name]:required,0..n  
                                } else {
                                    [$node cget -+name] property -accessor public [$it cget -+name]:required
                                }

                               

                            } else {

                                if {[$it cget -+multiple]==true} {
                                    puts "Multiple value"
                                    [$node cget -+name] property -accessor public [list [$it cget -+name]  {}]
                                } else {
                                    [$node cget -+name] property -accessor public [list [$it cget -+name] [$it cget -+default]]  
                                }
                                

                            }
                    }
                    
                    
                    ## Type Constant
                    ##################
                    [$node shade ::odfi::language::TypeConstant children] foreach {

                        #puts "Setting object variable on class: [$node cget -+name] [$it cget -+name] [$it cget -+value] "
                        [$node cget -+name] object variable -accessor public [$it cget -+name] [$it cget -+value] 
                               
                      
                    }


                    ## Type Method
                    ##################
                    [$node shade ::odfi::language::TypeMethod children] foreach {
                      
                        #puts "Add Method [$it cget -+name]  parameter to [$node cget -+name]"
                        [$node cget -+name] public method [$it cget -+name] [$it cget -+args] [$it cget -+body]
                        
                        ## Record builder in error tracer
                        ##################
                        if {![catch {package present odfi::errortracer}]} {
                            if {[file exists [$it cget -+file]]} {
                                #puts "NX: Error tracer loaded and file has been recorder"
                                #puts "Outputing $methodName to [$node cget -file]:[$node cget -line] produces ${className}"
                                ::odfi::errortrace::recordProc [$node cget -+name]::[$it cget -+name] [$it cget -+file] [$it cget -+line]
                            }
                        }
                    }
                    
                    ## Type Object Method
                    ##################
                    [$node shade ::odfi::language::TypeObjectMethod children] foreach {
                      
                        #puts "Add Method [$it cget -+name]  parameter to [$node cget -+name]"
                        [$node cget -+name] public object method [$it cget -+name] [$it cget -+args] [$it cget -+body]
                    }
                    


                    ## Export
                    #######################################
                    if {[llength [$node cget -+exportTo]]>0} {

                        ## Inject Builder to target type with prefix if necessary
                        ####################
                        foreach exportTo  [$node cget -+exportTo] {

                            set targetType   [lindex $exportTo 0]
                            set targetPrefix [lindex $exportTo 1]

                            if {![string match ::* $targetType]} {
                                set targetType [join [lrange [split [string map {:: :} $className] :] 0 end-1] ::]::$targetType
                            }

                            ## Check target type exists 
                            if {![::nsf::is class $targetType]} {

                                ## If non existen, maybe we can prepare it 
                                odfi::log::error "Cannot Export $className to $targetType if the latter is no valid class/type"
                            }

                            ## Export 
                            #odfi::log::info "Exporting $className to $targetType with prefix $targetPrefix"
                            if {$targetPrefix == ""} {
                                $targetType mixins add ${className}Builder
                            } else {
                                $targetType domain-mixins add ${className}Builder -prefix $targetPrefix 
                            }
                            
                            ## Also Add all Methods tagged as "target"
                            [$node shade ::odfi::language::TypeMethod children] @> filter {return [$it +target get]} @> foreach {
                                                  
                                $targetType public method [$it cget -+name] [$it cget -+args] [$it cget -+body]
                            }

                        }
                    
                    

                    } 


                } elseif {[$node info has type ::odfi::language::TypeVar]} {

                   
                    
                    
                    
                } elseif {[$node info has type ::odfi::language::TypeMethod]} {

                    
                    
                }
                #puts "Done node"
            }

            #puts "Done Producing NX"

        }
         

    }

}
