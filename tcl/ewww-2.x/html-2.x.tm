package provide odfi::ewww::html    2.0.0
package require odfi::language      1.0.0
package require odfi::richstream    3.0.0
package require odfi::files         2.0.0
package require http 2.8.8

namespace eval odfi::ewww::html {

    ###########################
    ## Language 
    ###########################
    odfi::language::Language define HTML {


        ## Common Types
        #####################
        +type HTMLNode {
            +var attributes {}

            +method id id {
                :attribute id $id
            }

            :attribute name value {

                +method reduceProduce args {
                    return ""  
                }

                +method setValue v {
                    set :value $v
                }

                +method addValue {v args} {
                    set :value [join [concat ${:value} $v $args] " "]
                }
            }

            ## Set an attributes value 
            +method @ {attr value args} {
                set attr [:getOrCreateAttribute $attr]
                $attr setValue [concat $value $args]
                
            }

            ## Append to an attribute's value
            +method @* args {

                foreach spec $args {
                    set pair [split $spec =]
                    foreach val [lindex $pair 1] {
                        :@ [lindex $pair 0] $val
                    }
                }
               

                #puts "Adding value to $attr -> [concat $value $args] -> [$attr value get]"
                
                
            }

            ## Set multiple attributes at once 
            ##  @* name=value name value name {value value} name value
            +method @+ {attr value args} {

                set attr [:getOrCreateAttribute $attr]
                $attr addValue [concat $value $args]

                #puts "Adding value to $attr -> [concat $value $args] -> [$attr value get]"
                
                
            }

            ## Append a CSS class 
            +method class args {
                foreach cl $args {
                    :@+ class $cl
                }
                
            }

            +method getOrCreateAttribute name {

               # puts "looking to update $name"
                set found false 
                [:noShade children] foreach {
                    if {[$it isClass odfi::ewww::html::Attribute] && [$it name get]==$name} {
                        set found $it
                        #return $it
                    }
                }
                if {$found!=false} {
                    return $found
                } else {
                    #puts "Creating"
                    :attribute $name "" {

                    }
                    return [:noShade child end]
                }
                
                

                set ac [:children shade odfi::ewww::html::Attribute children]
                if {[catch {[:children shade odfi::ewww::html::Attribute children] find { expr { [$it name get]==$name } }} res]} {
                    return [:attribute $name "" {

                    } ]
                    
                }
                return $res

            }

            +method getAttribute name {

                set found false 
                [:noShade children] foreach {
                    if {[$it isClass odfi::ewww::html::Attribute] && [$it name get]==$name} {
                        set found $it
                        #return $it
                    }
                }
                if {$found!=false} {
                    return [$found value get]
                } else {
                   return ""
                }
            }
            +method hasAttribute name {
                set found false 
                [:noShade children] foreach {
                    if {[$it isClass odfi::ewww::html::Attribute] && [$it name get]==$name} {
                        set found $it
                        break
                        #return $it
                    }
                }
                if {$found!=false} {
                    return true 
                } else {
                    return false
                }
                #return false

            }




            :textContent : HTMLNode text {
                +method reduceProduce args {
                    return ${:text}  
                }
            }
        }

        +type HTMLTransparentNode {
            +superclasses set odfi::ewww::html::HTMLNode

            +method reduceProduce args {
                return [reduceJoin $args]

            }
        }

        ## Main Structure
        #######################
        :html : HTMLNode {
            
            +exportToPublic

            :head : HTMLNode {

                

                :stylesheet : HTMLNode location {
                    #+builder {
                    #    :link {
                    #        :@ rel "css"
                    #    }
                    #}

                    +method reduceProduce args {
                        return "<link rel='stylesheet' href='${:location}'/>\n"  
                    }
                }

                :javascript : HTMLTransparentNode location {

                    +builder {
                        :script {
                            :@ src ${:location}
                        }
                    }

                }

                :link : HTMLNode {
                    +exportTo Stylesheet
                }

                :script : HTMLNode {
                    +exportTo Javascript
                }
                

            }

            :body : HTMLNode {

                ## Normal Blocks 
                ##################

                :div : HTMLNode {
                    +exportTo ::odfi::ewww::html::HTMLNode
                    +exportToPublic
                }
                :span : HTMLNode {
                    +exportTo HTMLNode
                }
                :i : HTMLNode {
                    +exportToParent
                }

                ## H titles 
                ###############
                ::repeat 6 {
                    :h[expr $i +1] : HTMLNode title {
                        +exportTo HTMLNode
                        +builder {
                            :textContent ${:title} {

                            }
                        }
                    }
                }
                
                ## Lists 
                ##############
                :ul : HTMLNode {
                    +exportTo HTMLNode

                    :li : HTMLNode  {
                        
                    }
                }

                :ol : HTMLNode {
                    :li : HTMLNode {

                    }
                }

                ## Links 
                #######################
                :a : HTMLNode text destination {
                    +exportTo HTMLNode
                    +builder {
                        :textContent ${:text} {

                        }
                        :@ href ${:destination}
                    }
                } 


                ## Table 
                ###############

                :table : HTMLNode {
                    +exportTo HTMLNode

                    ## HTML 
                    :thead : HTMLNode {
                        :tr : HTMLNode {

                            :th : HTMLNode {

                            }
                        }
                    }

                    :tbody : HTMLNode {
                        
                    }

                    :tr : HTMLNode {
                        +exportToParent
                        :th : HTMLNode {

                        }

                        :td : HTMLNode {

                        }
                    }
                    
                    ## Utils 
                    +method onTBody cl {

                        set tbody [:child 1]
                        $tbody apply $cl
                        
                    }

                    ## Build: add a tr for header automatically 
                    +var headerRow ""
                    +builder {

                        ## Added header 
                        :thead {
                            :tr {

                             } 
                        }
                       


                        ## Redirect all rest tr to tbody 
                        :tbody {

                        }
                        :onChildAdded {

                            set child [:noShade child end]
                            #puts "Added child $child"
                             
                            #return
                            if {[$child isClass odfi::ewww::html::Tr]} {
                                
                                #set child [:noShade child end]

                                #set tbody [:shade odfi::ewww::html::Tbody child 0]
                                set tbody [:noShade child 1]

                                #puts "IN TABLE ADD CHILD tbody [$tbody info class]"
                                #set child [:noShade child end]
                                $child detach 

                                ## Index 1 is the tbody
                                $tbody addChild $child

                           

                            }
                            
                        }
                       # puts "*** Done preparing html table"
                    }

                    ## API 
                    :column : HTMLTransparentNode  name {
                        +var cell ""

                        +builder {

                            ## Add cell for column in header
                            #puts "Column buildier, parent: [[:parent] info class] , [[[:parent] child 0] info class]  "
                            set headerRow [[[:parent] child 0] child 0]
                            set :cell [$headerRow th {
                                    :textContent ${:name}
                            } ]

                            #${:columnHtml} detach

                            #[[[:parent] children] findOption {$it isClass odfi::ewww::html::Tr} ] match {
                            #    :none {
#
                              #      [:parent] tr  {
                             #           :addChild ${:columnHtml}
                             #       }
#
                              #  }

                               # :some tr {
                               #     $tr addChild ${:columnHtml}
                               # }
                            #} 
                        }

                        +method reduceProduce args {
                            next
                            return " "
                        }
                    }


                }

                ## Form 
                ################
                :form : HTMLNode {
                    +exportToParent
                }
                :input : HTMLNode {
                    +exportToParent
                }

            }
        }

        ## Language 
        #####################
        #:div {
        #    +recursive
        #}
        #:span {
        #    +recursive
        #}



    }

    HTML produceNX



    ##########################
    ## String Producer 
    ##########################
    nx::Class create HTMLStringProducer {

        HTMLNode mixins add HTMLStringProducer

        :public method reduceProduce args {

            set nextRes [next]
            if {$nextRes!=""} {
                return $nextRes
            }
            ## Prepare Attributes 
            ############################
            set attrs [[[:shade odfi::ewww::html:::Attribute children] map { return "[$it name get]=\"[$it value get]\""}] mkString [list " " " " " "]]

            set res [odfi::richstream::template::stringToString {
                <<% return ${:+originalName} %> <% return $attrs %>>

                    <% return [string map {\{ "" \} ""} [reduceJoin0 $args \n]] %>
                </<% return ${:+originalName} %>>
            }]

            #puts "Reducing to ${:+originalName} -> $res"

            return $res
        }

        ## Create String and Return, and write to file if args is a file 
        :public method toString args {

            #puts "Inside HTML TOString $args"
            ## Create String and 
            set str [:reduce]

            ## File write?
            if {[llength $args]>0} {
                set f [lindex $args 0]
                odfi::files::writeToFile $f $str
            }

        }

    }

}


namespace eval odfi::ewww::html::bootstrap {

    ## From TCL Documentation
    proc httpcopy { url file {chunk 4096} } {
        set out [open $file w]
        set token [::http::geturl $url -channel $out \
               -blocksize $chunk]
        close $out

        # -progress httpCopyProgress 

        # This ends the line started by httpCopyProgress
        #puts stderr ""

        return $token
        upvar #0 $token state
        set max 0
        foreach {name value} $state(meta) {
            if {[string length $name] > $max} {
                set max [string length $name]
            }
            if {[regexp -nocase ^location$ $name]} {
                # Handle URL redirects
                puts stderr "Location:$value"
                return [httpcopy [string trim $value] $file $chunk]
            }
        }
        incr max
        foreach {name value} $state(meta) {
            puts [format "%-*s %s" $max $name: $value]
        }

        return $token
    }
    proc httpCopyProgress {args} {
        puts -nonewline stdout .
        flush stdout
    }

    odfi::language::Language define BOOTSTRAP {

        ## Download Utility
        ################
        +type BootstrapGetter {
            #+exportTo ::odfi::ewww::html::Head

            +method use args {
                puts "In USE bootstrapr"
                :javascript http://code.jquery.com/jquery-2.1.4.min.js {

                }

                :javascript https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js {

                }
                :stylesheet https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css {

                }
                :stylesheet https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap-theme.min.css {

                }
            }

            +method localUse folder {

                ## Download 
                odfi::ewww::html::bootstrap::httpcopy http://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js $folder/bootstrap.min.js
                odfi::ewww::html::bootstrap::httpcopy http://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css $folder/bootstrap.min.css
                odfi::ewww::html::bootstrap::httpcopy http://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap-theme.min.css $folder/bootstrap-theme.min.css
                odfi::ewww::html::bootstrap::httpcopy http://code.jquery.com/jquery-2.1.4.min.js $folder/jquery-2.1.4.min.js

                ## 
                :javascript jquery-2.1.4.min.js {
                    
                }
                :javascript bootstrap.min.js {

                }
                :stylesheet bootstrap.min.css {

                }
                :stylesheet bootstrap-theme.min.css {

                }
            }
        }

        ## Structuring/Styling 
        #####################
        :pageHeader : ::odfi::ewww::html::HTMLTransparentNode text {
            +exportTo ::odfi::ewww::html::HTMLNode bootstrap

            +builder {
                :div {
                    :@ class page-header
                    :h1 ${:text} {

                    }
                }
            }
        }


        ## Tabs 
        ##################
        :tabs : ::odfi::ewww::html::HTMLTransparentNode {
            +exportTo ::odfi::ewww::html::HTMLNode bootstrap
            +var contentDiv ""
            +var menuList   ""
            +builder {
                :div {
                    :ul {
                       :@ class nav nav-tabs
                       :@ role  tablist
                    }
                    [:parent] menuList set [:child end]

                    :div {
                        :@ class tab-content
                    }
                    [:parent] contentDiv set [:child end]
                }
            }

            :tab : ::odfi::ewww::html::HTMLTransparentNode name {
                
                +var contentDiv ""

                +builder {

                    set isActive false
                    if {[[[:parent] children] size] == 2} {
                        set isActive true
                    }

                    ## Menu 
                    [[:parent] menuList get] li {
                        :@ role presentation

                         if {$isActive} {
                            :@ class active
                        }

                        :a ${:name} #${:name} {
                            :@ aria-controls ${:name}
                            :@ role tab 
                            :@ data-toggle tab 
                            
                        }
                    }

                    ## Content
                    
                    set :contentDiv [[[:parent] contentDiv get] div {
                        :@ role  tabpanel

                        if {$isActive} {
                            :@ class tab-pane active
                        } else {
                            :@ class tab-pane
                        }
                        
                        :@ id    ${:name}
                    } ]

                    ## When Content Is added to the tab object, redirect it to the content div 
                    :onChildAdded {
                        set child [:child end]
                        if {[$child isClass ::odfi::ewww::html::HTMLNode]} {

                            $child detach
                            [:contentDiv get] addChild $child
                        }
                    }
                }
            }
        }

        ## Table 
        ###################
        :table : ::odfi::ewww::html::Table {
            +exportTo ::odfi::ewww::html::HTMLNode bootstrap

            +builder {
                :@ class table
            }

            +method striped  args {
                :@+ class table-striped
            }

            +method bordered  args {
                :@+ class table-bordered
            }

            +method condensed args {
                :@+ class table-condensed
            }
            +method hover args {
                :@+ class table-hover
            }

        }
        

    }
    BOOTSTRAP produceNX


    ::odfi::ewww::html::Head domain-mixins add [namespace current]::BootstrapGetter -prefix bootstrap
}
