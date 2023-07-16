#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas(length: .5cm, {
    import "../../draw.typ": *

    let (a, b, c) = ((0, 0), (1, 1), (2, -1))
    line(a, b, c, stroke: gray)
    bezier-through(a, b, c)
}))
