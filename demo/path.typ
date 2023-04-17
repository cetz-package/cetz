#import "../canvas.typ": *

#set page(width: auto, height: auto)

#canvas(fill: gray, length: 2cm, {
    import "../draw.typ": *

    // Quadratic
    curve((0, 1), (1, 1), ctrl: ((.25, .5), (.75, 1.5)), name: "q")
    group({
        stroke(blue)
        line("q.start", "q.ctrl-0", "q.ctrl-1", "q.end")
        fill(white)
        circle("q.ctrl-0", radius: .05)
        circle("q.ctrl-1", radius: .05)
    })

    // Cubic
    curve((0, 2), (1, 2), ctrl: ((.5, 1.5),), name: "c")
    group({
        stroke(blue)
        line("c.start", "c.ctrl-0", "c.end")
        fill(white)
        circle("c.ctrl-0", radius: .05)
    })

    // Linear
    curve((0, 3), (1, 3), ctrl: ())

    // Merged
    merge-path({
        curve((0, 4), (1, 4), ctrl: ((0.5, 3.5),), name: "c")
        line((), (.5, 4.5))
    }, cycle: true)

    // Transformed
    rotate((z: 90deg))
    translate(-.5, 0, 0)
    curve((0, 1), (1, 1), ctrl: ((.25, .5), (.75, 1.5)))
})
