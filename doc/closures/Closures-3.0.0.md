Closures v3
==========================

The last version of the closures module provides support for evaluating scripts with runtime variable resolution over multiple levels,
to approach the behavior of Functional Programming High order functions / Closures behavior


# Concept 

[TBD]

# Running a closure

    package require odfi::closures 3.0.0

    odfi::closures::run {
        # Code here
    }

# Special Control Structures


## ::repeat

The repeat control is a shortcut for a loop that should be run x times
The current loop count is provided through the implicit "i" interator variable

Example:

    ::repeat 10 {

        puts "Hello world $i !"
    }
