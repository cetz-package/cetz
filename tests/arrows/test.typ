#set page(width: auto, height: auto)
#import "../../src/lib.typ": *

#box(stroke: 2pt + red, canvas({
    import draw: *

    let next(mark) = {
        line((), (rel: (1, 0)), mark: mark)
        move-to((rel: (-1, .25)))
    }

    set-style(fill: blue, selector: "mark")
    rotate(-90deg)

    let marks = (">", "<", "|", "<>", "o")
    for m in marks {
        next((end: m))
    }

    for m in marks {
        next((start: m))
    }

    set-style(fill: none, selector: "mark")

    let marks = (">", "<")
    for m in marks {
        next((end: m))
    }

    for m in marks {
        next((start: m))
    }
}))
