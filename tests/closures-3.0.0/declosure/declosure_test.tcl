
#package require closures 3.0.0

source  [file dirname [info script]]/../../../tcl/pkgIndex.tcl
package require odfi::closures 3.0.0

set test hi
set test2 hi
set :test2 hi

set cl {

    set value "$test"
    set value2 "${test2}"
    set value2 "${:test2}"

}

set closure [::odfi::closures::newITCLLambda $cl]

#set preparedClosure [regsub -all {([^\\])\$(?:(:?[a-zA-Z0-9][a-zA-Z0-9:_\$-]*)|(?:\{(:?[a-zA-Z0-9][a-zA-Z0-9:_\$-]*)\}))} ${cl} "\\1\[odfi::closures::value \\2\\3 \]"]

#set preparedClosure [regsub -all {([^\\])\$(?:\{?(:?[a-zA-Z0-9][a-zA-Z0-9:_\$-]*)\}?)} ${cl} "\\1\[odfi::closures::value {\\2\\3} \]"]

set preparedClosure [$closure cget -preparedClosure]
puts "Prepared: $preparedClosure"



puts "Declosured: [odfi::closures::declosure $preparedClosure] "