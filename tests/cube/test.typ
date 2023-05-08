#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *
    stroke((paint: black, join: "round"))

    // No fill
    cube((0, 0, 0), 1)

    // Shade sides
    fill(blue)
    cube((2, 0, 0), 1, fill: "shade")

    // Fill sides manually
    cube((4, 0, 0), 1, fill: (left: yellow, back: red, bottom: blue))
}))
