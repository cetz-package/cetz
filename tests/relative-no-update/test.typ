#set page(width: auto, height: auto)
#import "../../src/lib.typ": *

#box(stroke: 2pt + red, canvas({
    import draw: *
    circle((0, 0), stroke: blue)
    circle((rel: (0, -1), update: false), stroke: red)
    circle((rel: (0, -2)), stroke: green)
}))
