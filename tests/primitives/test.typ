#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    line((0, 0), (1, 0))
    rect((0, 1), (1, 2))
    circle((.5, 3.5), radius: .5)
}))
