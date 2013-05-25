TCL Tutorial
=============================


This tutorial tries to bring focus on often used constructs in this TCL library


## References and Manuals


- [Reference Manual](http://tmml.sourceforge.net/doc/tcl/)
- [Itcl Reference](http://www.tcl.tk/man/itcl3.1/index.html)


## Script Template

Here is a small script template that you can copy paste to quick start
Some basic syntax definitions are included.

Before trying this script, make sure you have read the [Setup](Setup.md) document




    #!/usr/bin/env tclsh8.5

    ## Requires last versions of library
    package require odfi::common
    package require odfi::list
    package require odfi::closures

    ## Variable definition: only use variable name to change a variable
    set myVar "Jim"

    ## Variable usage: use $myVar ( $ prefix) to get the value of a variable
    puts "Hello $myVar"


## Errors: Creating and catching

- Use the [error]('http://tmml.sourceforge.net/doc/tcl/error.html') command to throw an error, and



        ## Throw an error
            proc killJim args {
            error "He's dead, Jim"
        }


- Use the [catch](http://tmml.sourceforge.net/doc/tcl/catch.html)



        ## Catch an error, this syntax is ugly:
        ## here we only catch an error, and fill it to res, but we don't know if it succeeded
        ## catch returns 1 if something was catched (an error happened)
        catch {[killJim]} res


- Use catch in a condition

        if {[catch {[killJim]} res]} {

            puts "What happened?"

            ## He's dead Jim
            puts $res

        } else {

            puts "He's Alive!"

        }


## TCL Lists

In TCL, everything is a list, but lists basic syntax is not intuitive.
Here is a MUST KNOW:

- If you have a list called "myList"
- To read from a list (in a foreach for example), always use the variable value like this: $myList
- To modify a list directly, using "lappend" for example, always use the variable name like this: myList


    ~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## Create a list
    set myList {a b c d}

    ## Read the list, note the $myList syntax
    foreach element $myList {
        puts "Element is: $element"]
    }

    puts "The list has [llength $myList] elements"

    ## Modify the list: DON'T USE THE $ SYMBOL HERE
    lappend myList e
    lappend myList f

    puts "The list has now [llength $myList] elements"
    ~~~~~~~~~~~~~~~~~~~~~~~~~~



## TCL Array (or Map)

Things to know:

- A TCL Array is a MAP!
- The [array command](http://tmml.sourceforge.net/doc/tcl/array.html) is used to create an array
- When accessing an Array using the "array" command, ALWAYS use the variable name only, never use "$"
- If you use a variable with $ for an array command, the content of the specified variable will be used as array name

Howtos:

- Create a TCL array

    ~~~~~~~~~~~~~~~~~~~~~
    ## Empty Array
    array set myarray {}

    ## Initialised array
    array set myarray {

        hello 0

        world {here the value is a list, could be anything}

    }

    ## Use a variable for array name
    set arrayName "myarray"
    array set $arrayName {
        "key" "value"
    }

    ~~~~~~~~~~~~~~~~~~~~~

- Access a key:

    ~~~~~~~~~~~~~~~~~~~~~

    ## This is a special syntax, if the key is not defined, an error is generated
    set extractedValue $myarray(hello)

    ## Displays: {here the value is a list, could be anything}
    puts $extractedValue

    ~~~~~~~~~~~~~~~~~~~~~

- Loop on values

    You can loop on the {key value} pairs, using foreach:

    ~~~~~~~~~~~~~~~~~~~~~

    foreach {key value} [array get myarray] {

        ## Do Something fun

    }

    ~~~~~~~~~~~~~~~~~~~~~

## Namespaces

Just like in C++, namespaces are used to scope variables and methods.
When no namespace is specified, the context is the top namespace, also called "::"

- Top namespace example:


    ~~~~~~~~~~~~~~~~~~~~~~~~~~
    ### Top variable
    set topVariable "Hello"

    # Note the $:: means an explicit reference to the top namespace
    puts "This is a top variable: $::topVariable"

    # Not specifyin any "::" in the variable name means a reference from the current context, which is "::" right now
    puts "The same variable again: $topVariable"
    ~~~~~~~~~~~~~~~~~~~~~~~~~~


- Sub namespaces


    ~~~~~~~~~~~~~~~~~~~~~~~~~~
    ### Create namespaces
    namespace eval my::namespace1 {

        proc sayHello args {
            puts "Hello!"
        }

        variable var1

    }

    namespace eval my::namespace2 {

        variable var2

    }

    puts "This is invalid: $var1"
    puts "This is invalid: $var2"
    puts "This is valid from here: $my::namespace1::var1"
    puts "This is valid from anywhere: $my::namespace1::var1"

    namespace eval my::namespace2 {



        puts "We are now in my::namespace2 context, proof here: [namespace current]"

        puts "This is invalid: $var1"

        puts "This is valid this time: $var2"
        puts "This is valid from anywhere: $my::namespace1::var1"

        puts "A function in a namespace: [my::namespace1::sayHello]"
    }
    ~~~~~~~~~~~~~~~~~~~~~~~~~~


## Objects with Itcl

Objects can be used in TCL using the Itcl library.
To use Itcl in a script, make sure the Itcl package has been loaded:

    package require Itcl

### Definition

Technically, a class behaves like a namespace:

    ~~~~~~~~~~~~~~~~~~~~~~~~~~
    itcl::class MyObject {

        public method sayHello args {

            puts "We are here in a ::MyObject namespace: [namespace current]"
        }

    }
    ~~~~~~~~~~~~~~~~~~~~~~~~~~

Instanciating a new object basically creates a new command having the object name:


    ~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## Instanciate an object
    ::MyObject myinstance1

    ## Now mwinstance1 is a command:
    myinstance1 sayHello

    ## ...thus it is impossible to instanciate two objects with the same name.
    ## This fails:
    ::MyObject myinstance1
    ~~~~~~~~~~~~~~~~~~~~~~~~~~



If you can't name your objects yourself, Itcl can handle that:


    ~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## That Auto keyword indicates a generated name...which better be saved
    set objectName [::MyObject #auto]

    ## Now we need to use the $objectName variable as container for the new command name:
    puts "Our created object is named: $objectName"

    ## In most script languages, you can embed code in a variable's content
    $objectName sayHello
    ~~~~~~~~~~~~~~~~~~~~~~~~~~



# TCL common pitfalls

TCL is flexible and powerful, but a very few pitfalls can make life hard:

## Everything is a list !

In TCL, Everything is a list.
So no matter what you code, your are always writing lists, in the form:

    listelement[SPACE]listelement[SPACE]listelement[SPACE]

... and the interpreter matches the lists you write, against the expected number of elements in a list

This is very important to remember, because if you omit one space in the previous example, your list is one element shorter

### The command + list requirement

Based on this model, the TCL interpreter always performs somehow the following when running your code:

- First found list element (or word) is a command name
- look for command definition, determine is required number of following list elements
- parse the next found list elements
- try to interpret
- loop

For example, to write a function or procedure, you use the "proc" command, defined as following:

    proc name listOfArguments body

Which gives us:
    - "proc" is the command name
    - Followed by 3 lists elements:
        - name of the new command to register in the interpreter
        - listOfArguments: a list with the required arguments. The special "args" value allow any number
        - A list contaning the script to execute when the command is called

Examples:



    proc myFunction args {
        puts "Hello world"
    }

    # Valid
    myFunction

    # Valid
    myFunction lala -lali -didou da



    proc myFunction name {
        puts "Hello $name!"
    }
    # Not valid
    myFunction

    # Valid
    myFunction John

    # Not valid
    myFunction John The Red



    proc myFunction {surname familyname} {
        puts "Hello $name $familyname!"
    }
    # Not valid
    myFunction
    myFunction John

    # Not valid
    myFunction John TheRed



### Wrong procedure definition

A very command pitfall when defining a procedure, is to forget a space between two list elements:


    proc myFunction {arg1 arg2}{
        puts "Hello"
    }

Here a space is missing between the arguments and the body, which makes both be one list element, thus a wrong arguments count for the proc definition


### Wrong IF ELSE

The same applies to the if else syntax.
Example:

    if {$var=="test"} {

    } elseif {$var=="test2"} {

    } else {

    }

The correct format described here is:

COMMAND | condition     |  body | COMMAND  |    condition    |  body | COMMAND | body
--------|------------   |-------|----------|--------------   |-------|---------|-------
   if   | {$var=="test"}|   {}  | elseif   | {$var=="test2"} |  {}   |   else  | {}

That is why the "elseif" can't be written "else if", otherwise you would have this wrong match:

COMMAND | condition     |  body | COMMAND  |    condition    |  body            | COMMAND | body
--------|------------   |-------|----------|--------------   |-------------     |---------|-------
   if   | {$var=="test"}|   {}  | elseif   |      if         | {$var=="test2"}  |  {}     | else

Also, the spaces are very important, this example is invalid;

    if {$var=="test"}{
        ## Missing space here
    } elseif {$var=="test2"} {

    } else {

    }



This is a very common source for errors



## Brackets and braces in comments



# Write a simple script

To write a simple script with the TCL libraries, just do so:

- Check your system install:

    You must have tcl 8.5 at least, and itcl installed:

    aptitude install tcl8.5 itcl3

- Check your user environment:

    You must source a script to have the TCl interpreter found our utils packages:

    echo "source /home/rleys/git/odfi/modules/global/scripts-manager/setup.bash" >> ~/.bashrc

- Open a File, make it executable, and start coding using this template:


    ~~~~~~~~~~~~~~~~~~~~~~~~~~
    #!/usr/bin/env tclsh8.5

    ## This is a small template with a list and a closure transforming it
    package require odfi::common
    package require odfi::list

    set myList {a b c d e}

    set transformed [odfi::list::transform $myList {

        ## $it is the pointer to iterated element
        return "/$it/"

    }]

    puts "Transformed list: $transformed"
    ~~~~~~~~~~~~~~~~~~~~~~~~~~



# Utility functions

Here is just an overview of interesting utility functions that are interesting, but might be lost in the mass of the functions:

## Encounter: Object (re)-creation with "::new" command

Old way to create an object:


    MyObject my_name constructor arguments

    ## This fails
    MyObject my_name constructor arguments


This deletes the named


    ::new MyObject my_name constructor arguments

    ## This works now
    ::new MyObject my_name constructor arguments



Or to make an explicit reference to the utility library:

    ::odfi::common::newObject MyObject my_name constructor arguments





