#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    // Merge lines
    fill(red)
    merge-path({
        line((0,0), (1,2))
        line((), (2,0))
        line((), (0,0))
    }, close: true)

    translate((0, -1))

    // Merge bezier paths
    fill(blue)
    merge-path({
        bezier((0,0), (2,0), (1, 1))
        bezier((2, -1), (rel: (-2, 0)), (.5, -2), (1.5, 0))
    }, close: true)

    translate((0, -2))

    // Merge different paths
    fill(green)
    merge-path({
        line((0,0), (1,0), (2,-1))
        arc((), start: 0deg, stop: -130deg, name: "arc")
        bezier("arc.end", (0,0), (0, -1), (2, -2))
    })
}))
