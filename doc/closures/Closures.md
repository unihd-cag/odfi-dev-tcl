Closures Documentation
==========================

A small tutorial/reference about the closures library


## Basic closure


Closures is a design pattern that is coming back in trend.
It is easy to understand, but may be confusing at the beginning.

### Definition

A closure is a variable that embeds code to be executed somewhere else.
As an interpreted language, TCL can interpret the content of a variable as a script, making it compatible with the closure concept.



    ~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## Put some code in a variable
    set scriptVariable "puts \"Hello World!\""

    ## Execute the code
    eval $scriptVariable

    ## In TCL, Everything is a list, so this is valid too:
    set scriptVariable {

        set var 42
        puts "what is the answer to life the universe and everything?"
        puts "1+1=$var"
    }
    eval $scriptVariable

    ## .... The variable can also be passed to procedures
    proc broadcastAnswer answer {

        eval $answer
    }
    broadcastAnswer $scriptVariable
    ~~~~~~~~~~~~~~~~~~~~~~~~~~

### Example: Closure over a list

A typical usage of closures, is to apply a script to each element of a list:


    ~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## This procedure can be used to execute a closure over all elements of a list
    proc foreachOverList {list closure} {

        ## This code works this way:
        ##   - "set elt $elt" is translated as a string with $elt beeing replaced with the list element value
        ##   - "set elt $elt" and $closure are evaluated as one script together
        ## -> The closure gets a variable named "it" (short for iterator) in which it can find back the actual processed element
        foreach it $list {
            eval "set it $it;" $closure
        }

    }

    set mylist {a b c d}
    foreachOverList $mylist {
        ## This code is executed by foreachOverList procedure
        ## The "it" implicit variable references the element of the list that is processed
        puts "Over element: $it"
    }
    ~~~~~~~~~~~~~~~~~~~~~~~~~~

Typical closure based designs make use of this concept over lists to offer convenient utilities like:

- Foreach : Applies closure on each element of a list
- filter :  Applies closure on each element of a list, returns a list with only the elements for which the closure evaluated to "true"
- collect:  Applies closure on each element of a list, returns a new list, with each element replaced by the result of the closure
- ...

Some of these methods are provided by the odfi::list package:

    ~~~~~~~~~~~~~~~~~~~~~~~~~~
    package require odfi::list

    set mylist {a b c d}
    odfi::list::each $mylist {
        ## This code is executed by foreachOverList procedure
        ## The "it" implicit variable references the element of the list that is processed
        puts "Over element: $it"
    }
    ~~~~~~~~~~~~~~~~~~~~~~~~~~

## Tree Programming with closures

Tree Programming consists in using objects and closure together, to allow the user to program structured data types in an intuitive way.


    root {

        addChild "child1" {

            addChild "child1.child1" {

            }

            addChild "child1.sibling" {

            }

        }

        addChild "child1-sibling" {

            ## You can use normal code
            ::repeat 20 {

                addChild "child1-sibling.child$i" {

                }

            }



        }

    }



###  Create and Apply: Closure as object constructor

To write a tree like compatible Programming interface, the basic programming unit is:

- Create a new child object
    - The constructor takes a closure as parameter
    - Execute the closure on this object to configure it
- Add it to current node

Example:


    ## Object definition
    itcl::class MyObject {

        ## List of children objects
        public variable children {}

        constructor closure {
            ## The closure is evaluated as if we were in the object instance
            odfi::closures::doClosure $closure
        }

        ## Adds a child to this object
        public method addChild object {
            lappend children $object
        }

    }

    # number of childre we want to add in closure
    set childrenCount 5

    ## Object create
    ::MyObject myinstance1 {

        ## ! Remember: The closure is evaluated as if we were in the object instance
        ## ... so this is valid
        addChild "Hi!"

        ## (Remember the namespace and objects chapter)
        puts "INVALID: number of children to create: $childrenCount"
        puts "VALID: number of children to create: $::childrenCount"

        ## The evalClosure method performs the black magic allowing this:
        ##  - Use childrenCount as a local variable, which is intuitive
        puts "VALID: number of children to create: $childrenCount"

    }





## Embedded Parser

The closures module includes the embedded TCL parser.

### Overview

The embedded parser performs following:

- Read a character stream
- Find all <%  ... %> sections
    - For each section: Execute section content as a TCL closure
- Write an output stream:
    - with the original stream characters
    - Except for the <% %> sections, which are replaced with the evaluation result

Example:

- File: /home/rleys/git/odfi/modules/dev/tcl/examples/embeddedtcl/embedded-simple-1.tcl
- Content:

    <includeFile path="/nfs/home/rleys/git/odfi/modules/dev/tcl/examples/embeddedtcl/embedded-simple-1.tcl" />

### Using the parser interpreter

The parser interpreter is a special sheebang interpreter that will:

- Use the complete file as parser source
- Output the result to a new file, named like the input file, with a "generated" marker added to the name

Example:

- Input file: embedded-interpreter.tcl

     <includeFile path="/nfs/home/rleys/git/odfi/modules/dev/tcl/examples/embeddedtcl/embedded-interpreter-notstdalone.tcl" />

- Output file: embedded-interpreter.generated.tcl
- Calling:

    ~~~~~~~~~~~~~~
    (from console)$ odfi_dev_tcl_embedded embedded-interpreter.tcl
    Output written to embedded-interpreter.generated.tcl
    ~~~~~~~~~~~~~~

### Calling the parser

To use the parser, you can use various utility methods:

#### The basic stream parser

- Input:  Stream channel
- Output: Result String

    ~~~~~~~~~~~~~~
    odfi::closures::embeddedTclStream streamId
    ~~~~~~~~~~~~~~

#### File to File

- Input: Path to file
- Output: Path to another file where the result will be written

    ~~~~~~~~~~~~~~
    odfi::closures::embeddedTclFromFileToFile inputFile outputFile
    ~~~~~~~~~~~~~~


#### Files to File

- Input: A list of Paths to files
- Output: Path to another file where the result will be written

    ~~~~~~~~~~~~~~
    odfi::closures::embeddedTclFromFilesToFile inputFiles outputFile
    ~~~~~~~~~~~~~~

#### String to String

- Input: String with text to parse
- Output: Result string

    ~~~~~~~~~~~~~~
    odfi::closures::embeddedTclStringToString inputString
    ~~~~~~~~~~~~~~


#### File to String

- Input: Path to file
- Output: Result string

    ~~~~~~~~~~~~~~
    odfi::closures::embeddedTclFileToString inputString
    ~~~~~~~~~~~~~~
