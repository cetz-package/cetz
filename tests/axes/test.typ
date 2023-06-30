#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    set-style(radius: .05)

    circle((0, 0), stroke: black)

    circle((1, 1), stroke: green)

    circle((0, 1), stroke: yellow)

    circle((1, 0), stroke: blue)

    set-style(stroke: blue, mark: (end: ">", fill: blue, stroke: blue))
    line((0, 0, 0), ( 0deg, .5))
    line((0, 0, 0), (45deg, .5))
    line((0, 0, 0), (90deg, .5))
}))
