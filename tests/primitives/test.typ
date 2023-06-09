#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    line((0, 0), (1, 0))
    rect((0, 1), (1, 2))
    circle((.5, 3.5), radius: .5)
    arc((1, 4.5), start: 0deg, stop: 90deg, radius: .5)
    bezier((0, 6), (1, 6), (.5, 5))
    bezier((0, 7), (1, 7), (.25, 6), (.75, 8))
}))
