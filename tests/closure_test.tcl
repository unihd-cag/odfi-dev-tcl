package require odfi::closures 2.0.0
namespace eval test1 {
set input "<% puts foo %>"
set reference1 "foo"

set testFileName "closureInputTestFile"
set fileChannel [open $testFileName "w+"]
puts $fileChannel $input
close $fileChannel

  puts "testing odfi closures string to string"
  set output [odfi::closures::embeddedTclFromStringToString $input]
  if {[string trim $output]==$reference1} {
    puts "working"
} else {
  error "not working, output: $output"
}


puts "testing odfi closure file to string"

set output [odfi::closures::embeddedTclFromFileToString $testFileName $input]

if {[string trim $output]==$reference1} {
  puts "working"
} else {
  error "not working, output:t diff $output"
}
}
