#!/usr/bin/env tclsh8.5

package require odfi::closures 2.0.0


set firstName "John"
set lastName  "Doe"
set embeddedString {

    This is a very normal text, writen for guy named <% $firstName %> (last name: <% $lastName %>)

    You can output code in sections:
    <%
        puts $eout "I have been written"
        puts $eout "Through puts !"
    %>

}

puts "Result: [odfi::closures::embeddedTclFromStringToString $embeddedString]"
