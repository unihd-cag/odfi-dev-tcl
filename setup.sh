#!/bin/bash

loc="$(dirname "$(readlink -f ${BASH_SOURCE[0]})")"


## If the TCL interpreter has beem compiled in the external folder, add it to path
if [[ -d $loc/external/tcl/bin ]] 
then
	#echo "Adding Manually setup
	export PATH=$loc/external/tcl/bin/:$PATH
	export LD_LIBRARY_PATH=$loc/external/tcl/lib/$LD_LIBRARY_PATH
fi