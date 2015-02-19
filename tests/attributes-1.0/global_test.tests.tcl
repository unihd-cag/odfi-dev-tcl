package require odfi::tests
package require odfi::attributes

#####
##### Repeat the same test with standard and FlexNode Container

set testContainers [list [odfi::flextree::FlexNode new -object-mixin odfi::attributes::AttributesFlexNodeContainer] [odfi::attributes::AttributesStandaloneContainer new]]

foreach container $testContainers {

    odfi::tests::msg "Running test with container [$container info class]"

    ## Add some attributes 
    ###########

    ## (default group)
    $container addAttribute def::a::a
    $container addAttribute def::b
    $container addAttribute test

    $container addAttribute g1.a::a::a
    $container addAttribute g1.a::a::b

    $container addAttribute g2.b::a::a
    $container addAttribute {g2.b::a::b 30}
    $container addAttribute {g2.b::a::c 60}

    ## Retrieve correct attributes count 
    ############
    odfi::tests::expect "8 attributes" 8 [[$container attributes] size]

    ## Retrieve correct groups count 
    #################
    odfi::tests::expect "3 groups" 3 [[$container getGroupNames] size]
    odfi::tests::expect "3 groups as TCL list" 3 [llength [$container getGroupNames -tcl true]]

    ## Retrieve attributes by Groups 
    ##################
    odfi::tests::expect "2 attributes in g1" 2 [[$container getGroupAttributes g1] size]
    odfi::tests::expect "3 attributes in g2" 3 [[$container getGroupAttributes g2] size]
   

    ## Test Attributes Presence
    ###########
    odfi::tests::expect "Default Attribute presence" true [$container hasAttribute test]
    odfi::tests::expect "Default Attribute presence with default group name" true [$container hasAttribute default.test]

    odfi::tests::expect "Attribute presence" true [$container hasAttribute g1.a::a::a]
    odfi::tests::expect "Attribute presence" true [$container hasAttribute g1.a::a::b]
    odfi::tests::expect "Attribute non-presence" false [$container hasAttribute g1.a::a::c]

    odfi::tests::expect "Attribute presence" true [$container hasAttribute g2.b::a::a]
    odfi::tests::expect "Attribute presence" true [$container hasAttribute g2.b::a::b]
    odfi::tests::expect "Attribute presence" true [$container hasAttribute g2.b::a::c]

    ## Retrieve attribute value
    ######################
    odfi::tests::expect "Attribute value" 30 [$container getAttributeValue g2.b::a::b]
    odfi::tests::expect "Attribute value" 60 [$container getAttributeValue g2.b::a::c]



}

odfi::tests::msg "Testing attribute functions"

## Attribute functions
################################
set dummyContainer [odfi::flextree::FlexNode new -object-mixin odfi::attributes::AttributesFlexNodeContainer]

## Function: ::tattribute , group: none
odfi::attributes::declareAttribute ::tattribute
odfi::tests::expect "Attribute function name" 1 [llength [info commands ::tattribute]]
$dummyContainer apply {
    ::tattribute
    odfi::tests::expect "Attribute tattribute presence" true [$dummyContainer hasAttribute tattribute]
}

#dummyContainer $group

## Function: ::tattribute2 , group: g2
odfi::attributes::declareAttribute g2.::tattribute2
$dummyContainer apply {
    ::tattribute2
    odfi::tests::expect "Attribute g2.tattribute2 presence" true [$dummyContainer hasAttribute g2.tattribute2]
}



## Function: ::my::attribute , group: none
odfi::attributes::declareAttribute ::my::attribute
$dummyContainer apply {
    ::my::attribute
    odfi::tests::expect "Attribute my::attribute presence" true [$dummyContainer hasAttribute my::attribute]
}

## Function: ::my::attribute2 , group: g1
odfi::attributes::declareAttribute g1.::my::attribute2
$dummyContainer apply {
    ::my::attribute2
    odfi::tests::expect "Attribute g1.my::attribute2 presence" true [$dummyContainer hasAttribute g1.my::attribute2]
}


## Function: ::g1::my::attribute2 , group: g1
odfi::attributes::declareAttribute ::g1.my::attribute3
odfi::tests::expect "Attribute function name" 1 [llength [info commands ::g1::my::attribute3]]
$dummyContainer apply {
    ::g1::my::attribute3
    odfi::tests::expect "Attribute g1.my::attribute3 presence" true [$dummyContainer hasAttribute g1.my::attribute3]
}

## Attribute Functions in namespace context for automatic grouping
####################
namespace eval attr_test_ns::a {

    odfi::attributes::declareAttribute attr1
    odfi::attributes::declareAttribute attr2
}
odfi::tests::expect "Attribute function name" 1 [llength [info commands ::attr_test_ns::a::attr1]]
$dummyContainer apply {
    ::attr_test_ns::a::attr1
    odfi::tests::expect "Attribute attr_test_ns_a.attr1 presence" true [$dummyContainer hasAttribute attr_test_ns_a.attr1]
}
