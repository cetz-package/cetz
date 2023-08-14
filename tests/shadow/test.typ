#set page(width: auto, height: auto)
#import "../../src/lib.typ": *

#box(stroke: 2pt + red, canvas({
    import draw: *

    fill(white)
    shadow({
        rect((0, 0), (1, 1))
        line((0, 2), (1, 2))
    })
    shadow(offset-x: -.1, offset-y: .1, {
        rect((2, 0), (3, 1))
        line((2, 2), (3, 2))
    })
}))
