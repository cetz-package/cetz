#set page(width: auto, height: auto)
#import "../../src/lib.typ": *

#box(stroke: 2pt + red, canvas({
    import draw: *

    group(name: "g", {
      translate((-.5, .5, 0))
      rotate(65deg)

      rect((0, 0), (1, 1), name: "r")
      copy-anchors("r")
    })

    stroke(green)
    circle("g.top-left", radius: .1)
    circle("g.top-right", radius: .1)
    circle("g.bottom-left", radius: .1)
    circle("g.bottom-right", radius: .1)
}))
