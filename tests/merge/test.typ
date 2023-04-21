#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    fill(green)
    merge-path({
        bezier((0, 0), (2, 0), (1, 2))
        bezier((2, 0), (0, 0), (1, 1))
    })
}))
