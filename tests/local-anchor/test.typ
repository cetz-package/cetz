#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    circle((0,0), radius: 0.5)
    arc((0, 1), 0deg, 180deg, name: "c", anchor: "end")
    stroke(blue)
    circle("c.end", radius: 0.1)
}))
