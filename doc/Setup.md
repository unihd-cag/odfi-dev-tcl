Setting Up TCL library
===========================

## Required System libraries

The TCL library required following standard TCL libs:
    - itcl
    - tclxml

On Ubuntu/Debian systems:

    aptitude install itcl3 tclxml

## Setup

Only make sure you have sourced the global ODFI setup script:

    echo "source /home/rleys/git/odfi/modules/global/scripts-manager/setup.bash" >> ~/.bashrc

## Verify setup

To check if everything is working, yould be able to run this tool:

    odfi_dev_tcl_check

The output should be friendly :)


## TCL Library Versions

Here are the recommended versions of the various library:



    ## Common Tools
    package require odfi::common 1.0.0

    ## List utils
    package require odfi::list 2.0.0

    ## Closures package
    package require odfi::closures 2.0.0


