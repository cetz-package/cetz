#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas({
    import draw: *

    circle((0,0), radius: 0.5)
    arc((0, 1), start: -90deg, stop: 90deg, name: "c", anchor: "arc-start")
    stroke(blue)
    circle("c.arc-start", radius: 0.1)
}))
