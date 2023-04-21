#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    line((0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1), cycle: true)
    line((0, 0, 1), (0, 0, 0))
    line((1, 0, 1), (1, 0, 0))
    line((1, 1, 1), (1, 1, 0))
    line((0, 1, 1), (0, 1, 0))
    line((0, 0), (1, 0), (1, 1), (0, 1), cycle: true)
}))
