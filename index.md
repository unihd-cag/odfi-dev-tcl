---
layout: default
title: Welcome to TCL Common Library
---


Welcome to ODFI TCL Common library

# Installation

To install this library, you can use the ODFI modules manager for a custom command-line based installation.

## Manual install, Manual load

1. Checkout the git repository
    
    git checkout https://github.com/unihd-cag/odfi-dev-tcl.git

2. Create a TCL script and source the pkgIndex.tcl file

~~~~~~ tcl
#!/usr/bin/env tclsh

source checkout/path/tcl/pkkIndex.tcl

## Load libraries using package command
package require odfi::closures 3.0.0
~~~~~~~~~~~~~~

## Manual install, Auto load

1. Checkout the git repository
    
    $ git checkout https://github.com/unihd-cag/odfi-dev-tcl.git

2. Add the tcl/ folder to the TCLLIBPATH environement variable

    $ export TCLLIBPATH="checkout/path/tcl/ $TCLLIBPATH"

2. Create a TCL script and load libraries

~~~~~~ tcl
#!/usr/bin/env tclsh


## Load libraries using package command
package require odfi::closures 3.0.0
~~~~~~~~~~~~~~

