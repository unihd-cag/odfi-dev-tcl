Common Utilities for TCL
=============================

The common utilities contain various useful functions, which are not precisely sorted.
Just browse the list to see if something can be helpful

## Objects

Objects Related functions for Itcl

## Stream

Some Streams functions

### Create a Memory String Stream

This function creates a standard stream, with an in-memory string buffer as data backend

- Calling prototype

~~~~~~~~
odfi::common::newStringChannel [initial Content]?
~~~~~~~~

The initial content first argument can be provided to init the stream with a string

- Return value

A stream identifier that can be used by puts,close,read standard functions

- Example

~~~~~~~~
## Create Stream
set stringStream [odfi::common::newStringChannel]

## Write to it
puts $stringStream "Hello World!"

## Read and close
flush $stringStream
set streamContent [read $stringStream]
close $stringStream
~~~~~~~~


