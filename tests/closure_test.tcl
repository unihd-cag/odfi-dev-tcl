package require odfi::closures

set input "<% puts foo %>"
set reference1 "foo"

set testFileName "closureInputTestFile"
set fileChannel [open $testFileName "w+"]
puts $fileChannel $input
close $fileChannel

puts "testing odfi closures string to string"
set output [odfi::closures::embeddedTclFromStringToString $input]
if {$output==$reference1} {
  puts "working"
} else {
  puts "not working, output: $output"
}

puts "testing odfi closure file to string"

set output [odfi::closures::embeddedTclFromFileToString $testFileName $input]

if {$output==$reference1} {
  puts "working"
} else {
  puts "not working, output: $output"
}
