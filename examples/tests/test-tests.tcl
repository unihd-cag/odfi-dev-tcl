package require odfi::tests 1.0.0

## buggy function
proc intAdd {a b} {
    if {![string is integer $a]} {
        return fasle
    }
    if {![string is integer $b]} {
        return false
    }
    return [expr $a + $b]
}

odfi::tests::suite Suite1 {
    test positiveNumbers {
        ::puts "This is a test"
        expect "2+2" 4 [intAdd 2 2]
        expect "2+3" 5 [intAdd 2 3]
        expect "0+0" 0 [intAdd 0 0] 
    }

    test negativeNumbers {
        expect "2-3" -1 [intAdd 2 -3]
        expect "2-5" -3 [intAdd 2 -5]
        expect "10-20" -10 [intAdd 10 -20] 
    }

    test strings {
        expect "a+5" false [intAdd a 5]
        expect "5+b" false [intAdd 5 b]
        expect "a+b" false [intAdd a b]
    }
}
