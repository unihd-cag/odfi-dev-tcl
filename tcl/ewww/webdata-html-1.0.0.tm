## \file Contains HTML library for webdataand TView
###################

## @warning Not so well documented here
namespace eval odfi::ewww::webdata::html {

    itcl::class HtmlComponent {

        ## \brief id attribute
        protected variable id ""

        protected variable class {}
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

            

            #set r  "
             #   <thead>
             #       <tr>
             #       [odfi::list::transform $columns {
             #           return <th>$it</th>
             #       }]
             #       </tr>
             #   </thead>

            #"

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
                set rowCells {}
                foreach it $row {
                    #puts "Row: $it"
                    lappend rowCells "{<td>$it</td>}"
                }
               
                #puts "rowCells: $rowCells"
                if {[llength $rowCells]>0} {
                    set rowCells [join [join $rowCells]]
                    #puts "joined rC: $rowCells"
                    lappend rowsResult "<tr${class}>$rowCells</tr>"
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
