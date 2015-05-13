package require odfi::tests 1.0.0

proc add {a b} {
    return [expr $a + $b]
}

odfi::tests::suite Suite1 {
    test positiveNumbers {
        ::puts "This is a test"
        expect "2+2" 4 [add 2 2]
        expect "2+3" 5 [add 2 3]
        expect "0+0" 0 [add 0 0] 
    }

    test negativeNumbers {
        expect "2-3" -1 [add 2 -3]
        expect "2-5" -3 [add 2 -5]
        expect "10-20" -10 [add 10 -20] 
    }

    test strings {
        #expect "a+b" [add a b]
    }
}
