#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    stroke(black)
    circle((0, 0), radius: .05)

    stroke(green)
    circle((1, 1), radius: .05)

    stroke(yellow)
    circle((0, 1), radius: .05)

    stroke(blue)
    circle((1, 0), radius: .05)

    fill(blue)
    line((0, 0, 0), ( 0deg, .5), mark-end: ">")
    line((0, 0, 0), (45deg, .5), mark-end: ">")
    line((0, 0, 0), (90deg, .5), mark-end: ">")
}))
