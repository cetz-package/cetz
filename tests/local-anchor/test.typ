#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    circle((0,0), radius: 0.5)
    arc((0, 1), -90deg, 90deg, name: "c", anchor: "start")
    stroke(blue)
    circle("c.start", radius: 0.1)
}))
