## \file Contains HTML library for webdataand TView
###################

## @warning Not so well documented here
namespace eval odfi::ewww::webdata::html {

    itcl::class HtmlComponent {

        ## \brief id attribute
        protected variable id ""

        protected variable class {}
    }


    proc putsHTML closure {

        set ct [::new [namespace current]::HTMLContent #auto $closure]
        puts [$ct cget -res]

    }

    proc stringHTML closure {

        set ct [::new [namespace current]::HTMLContent #auto $closure]
        set res [$ct cget -res]

        ##::puts "Result: $res"
        return $res

    }

    itcl::class HTMLContent {

        public variable res ""



        constructor cl {
           [odfi::closures::doClosureToString $cl]
        }

        public method stack str {
            set res "$res$str"
        }

        ## HTML Content Methods
        ###########################

        public method ul closure {

            return "<ul>[odfi::closures::doClosureToString $closure]</ul>"

            set resunJoined [odfi::closures::doClosure $closure]
            #puts "Should be end of closure before this line, with res: $resunJoined"
            #set res [odfi::closures::doClosureToString $closure]
            #puts "UL joining: [join $resunJoined \n]"

            set res "<ul>[join $resunJoined]</ul>"


            return $res



        }

        public method li closure {


            return "<li>[odfi::closures::doClosureToString $closure]</li>"
        }

        public method span closure {


            return "<span>[odfi::closures::doClosureToString $closure]</span>"
        }

        public method div closure {

            stack "<div>"
            stack [odfi::closures::doClosureToString $closure]
            stack "</div>"

            #return "<div>[odfi::closures::doClosureToString $closure]</div>"
        }
        public method div-id {id closure} {


            return "<div id=\"$id\">[odfi::closures::doClosureToString $closure]</div>"
        }

        ## Titling
        #################
        public method h1 closure {

            return "<h1>[odfi::closures::doClosureToString $closure]</h1>"
        }
        public method h2 closure {

            return "<h2>[odfi::closures::doClosureToString $closure]</h2>"
        }
        public method h3 closure {

            ::puts "H3 tile: $closure"

            stack "<h3>"
            stack "[odfi::closures::doClosureToString $closure]"
            stack "</h3>"

            #return "<h3>[odfi::closures::doClosureToString $closure]</h3>"
        }
        public method h4 closure {

            return "<h4>[odfi::closures::doClosureToString $closure]</h4>"
        }
        public method h5 closure {

            return "<h5>[odfi::closures::doClosureToString $closure]</h5>"
        }
        public method h6 closure {

            return "<h6>[odfi::closures::doClosureToString $closure]</h6>"
        }


        ## Table
        ###########################

        public method table closure {

            ## Create table
            set tbl [::new [namespace parent]::Table #auto]
            $tbl apply $closure

            stack [$tbl toHTML]

            #return [$tbl toHTML]

            #return "<table>
            #    [odfi::closures::doClosureToString $closure]
            #</table>"

        }


        #### Linking
        ##################

        ## \brief Creates a simple link to a view
        #  Example: link "This is a link" to /path/to/view
        #           <a href="appPath/view//path/to/view">This is a link</a>
        public method link {linkText word viewId} {

            set linkOutput  [odfi::closures::doClosure {

                    return "<a href='$viewId'>
                                    $linkText
                            </a>"

                    return "<a href='[$application getApplicationPath]/view/$viewId'>
                                    $linkText
                            </a>"
            }]

            #puts "Link Result: $linkOutput"

            return $linkOutput
        }

        ## Special Methods
        ###########################

        public method breadCrumbs {lst transformClosure} {

            return [div {
                join [odfi::list::transform $lst {
                    span $transformClosure
                }] " - "

            }]

        }


    }

    itcl::class Table {
        inherit HtmlComponent

        protected variable header

        protected variable body

        constructor args {

            ## Init
            #################
            set header  [::new [namespace parent]::TableHeader #auto]
            set body    [::new [namespace parent]::TableBody #auto]
        }

        destructor {
            catch {itcl::delete objects $header $body}
        }

        ##  \brief Apply a closure on this object
        public method apply closure {
            odfi::closures::doClosure $closure
        }

        ##  \brief define header
        public method header closure {

           $header apply  $closure
        }

        ##  \brief define body
        public method body closure {

           $body apply $closure
        }

        ## \brief Produce HTML
        # @return An HTML string
        public method toHTML args {

            ## Attributes
            ####################
            set attributes {}
            if {$id!=""} {
                lappend attributes "id=\"$id\""
            }
            if {[llength $class]>0} {
                lappend attributes "class=\"[join $class]\""
            }

            set attributes [join $attributes]
            return "
                <table ${attributes}>
                    [$header toHTML]
                    [$body toHTML]
                </table>
            "

        }
    }

    itcl::class TableHeader {
        inherit HtmlComponent

        protected variable columns {}

        ##  \brief Apply a closure on this object
        public method apply closure {
            odfi::closures::doClosure $closure
        }

        ## \brief Add a column definition to the table
        public method column {name {closure {}}} {
            lappend columns $name
        }

        ## \brief Produce HTML
        # @return An HTML string
        public method toHTML args {


            set cols {}
            foreach colname $columns {
                lappend cols "<th>$colname</th>"
            }

            

            set r  "
                <thead>
                    <tr>
                    [odfi::list::transform $columns {
                       "<th>$it</th>"
                    }]
                    </tr>
                </thead>

            "

            #::puts "Result should be: $res"

            return "
                <thead>
                    <tr>
                    [concat $cols]
                    </tr>
                </thead>

            "


        }

    }

    itcl::class TableBody {

        protected variable rows {}



        ##  \brief Apply a closure on this object
        public method apply closure {
            odfi::closures::doClosure $closure
        }

        ## \brief Add a row of datas to the table body.
        # The data list can contain special parameters like "class=className for the roz"
        public method row dataList {

            #puts "Appending row with elements: $dataList ([llength $dataList])"
            #foreach data $dataList {



             #   lappend rows $data
            #}

            lappend rows $dataList

        }


        ## \brief Produce HTML
        # @return An HTML string
        public method toHTML args {

            ## Rows
            set rowsResult {}
            foreach row $rows {
                #puts "In Row with: $row"

                ## Defined Class ?
                ###################
                set classIndex [lsearch -glob $row "class=*"]
                set class ""
                if {$classIndex!=-1} {
                    regexp {class=(.+)} [lindex $row $classIndex] -> class
                    set class " class=$class"
                    set row [lreplace $row $classIndex $classIndex]
                }

                ## Convert Data elements to Cells td
                set rowCells [odfi::list::transform $row {
                    #puts "Row: $it"
                    return "{<td>$it</td>}"
                }]
                if {[llength $rowCells]>0} {
                    lappend rowsResult "<tr${class}>[join $rowCells]</tr>"
                }
            }
            return "
                <tbody>
                    [join $rowsResult]
                </tbody>

            "


        }

    }

}
