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
    circle("g.north-west", radius: .1)
    circle("g.north-east", radius: .1)
    circle("g.south-west", radius: .1)
    circle("g.south-east", radius: .1)
}))
