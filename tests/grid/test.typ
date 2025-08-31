#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
    import draw: *

    grid((0,0), (1,1))
})

#test-case({
    import draw: *

    grid((0,0), (1,1), step: 0.3)
})

#test-case({
    import draw: *

    grid((0,0), (1,1), step: (0.1, 0.2))
})

// Test shift
#test-case({
    import draw: *

    grid((0,0), (1,1), step: (0.3, 0.2), shift: (0.1, 0.1))
})
