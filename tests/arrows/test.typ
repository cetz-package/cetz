#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    let next(mark) = {
        line((), (rel: (1, 0)), mark: mark)
        move-to((rel: (-1, .25)))
    }

    rotate(45deg)
    fill(blue)

    let marks = (">", "<", "|", "<>", "o")
    for m in marks {
        next((end: m))
    }
    for m in marks {
        next((start: m))
    }
    // next((mark: (end: ">")))
    // next((mark: (end: "<")))
    // next((mark: (end: "|")))
    // next((mark: (end: "<>")))
    // next((mark: (end: "o")))

    // next(">", none)
    // next("<", none)
    // next("|", none)
    // next("<>", none)
    // next("o", none)
}))
