#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case(sides => {
    import cetz.draw: *
    n-star((0, 0), sides, angle: 9deg)
}, args: (3, 4, 5, 6, 7))

#test-case(sides => {
    import cetz.draw: *
    n-star((0, 0), inner-radius: 0.8, sides, fill: blue)
}, args: (3, 4, 5, 6, 7))
