#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    group(name: "g", {
      translate((-1.5, 1.5, 0))

      rect((0, 0), (1, 1))
      anchor("tl", (0, 0))
      anchor("tr", (1, 0))
      anchor("bl", (0, 1))
      anchor("br", (1, 1))
    })

    group({
        line((-2, 0), (2, 0))
        line((0, -2), (0, 2))
    })

    stroke(green)
    circle("g.tl", radius: .1)
    circle("g.tr", radius: .1)
    circle("g.bl", radius: .1)
    circle("g.br", radius: .1)
}))
