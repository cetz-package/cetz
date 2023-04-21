#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    let next(begin, end) = {
        line((), (rel: (1, 0)), mark-begin: begin, mark-end: end)
        move-to((rel: (-1, .25)))
    }

    rotate(45deg)
    fill(blue)

    next(none, ">")
    next(none, "<")
    next(none, "|")
    next(none, "<>")
    next(none, "o")

    next(">", none)
    next("<", none)
    next("|", none)
    next("<>", none)
    next("o", none)
}))
