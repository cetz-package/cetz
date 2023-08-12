#set page(width: auto, height: auto)
#import "../../src/lib.typ": *

#box(stroke: 2pt + red, canvas(length: .5cm, {
    import draw: *

    let (a, b, c) = ((0,0), (2,-.5), (1,1))
    line(a, b, c, close: true, stroke: gray)
    circle-through(a, b, c, name: "c")
    circle("c.center", radius: .05, fill: red)
}))
