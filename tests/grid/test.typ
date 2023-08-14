#set page(width: auto, height: auto)
#import "../../src/lib.typ": *

#box(stroke: 2pt + red, canvas({
    import draw: *

    grid((0,0), (1,1), step: .1)

    translate((0, 1.5))
    grid((0,0), (1,1), step: .5)

    translate((0, 1.5))
    grid((0,0), (1,1), step: (x: .2, y: .5))
}))
