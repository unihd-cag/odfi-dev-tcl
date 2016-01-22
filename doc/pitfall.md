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



