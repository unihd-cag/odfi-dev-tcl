Closures Documentation
==========================

A small tutorial/reference about the closures library


## Basic closure

TBD

## Embedded Parser

The closures module includes the embedded TCL parser.

### Overview

The embedded parser performs following:

- Read a character stream
- Find all "<%  ... %>" sections
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
