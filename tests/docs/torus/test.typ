#set page(width: auto, height: auto)
#import "/src/lib.typ" as cetz
#import "/tests/helper.typ": *

#let torus(pos, angle: 60deg, cap-angle: 5deg, radius: 1, thickness: 0.4, fill: yellow, stroke: black) = {
  import cetz.draw: scope, compound-path, circle, arc, hide, intersections, arc-through, merge-path

  let cap-angle = cap-angle * calc.sin(angle)

  scope({
    let radius = (radius, radius * calc.cos(angle))
    let inner-north = pos.at(1) + radius.at(1) - thickness
    let show-hole = inner-north > pos.at(1)

    hide({
      circle(pos, radius: cetz.vector.add(radius, (thickness, thickness)), name: "outer")
      circle(pos, radius: radius, name: "mid")
    })

    intersections("inner", {
      arc-through(
        ((name: "outer", anchor: 0deg - cap-angle), 200%, (name: "mid", anchor: 0deg)),
        ((name: "outer", anchor: 270deg), 200%, (name: "mid", anchor: 270deg)),
        ((name: "outer", anchor: 180deg + cap-angle), 200%, (name: "mid", anchor: 180deg)),)
      arc-through(
        ((name: "outer", anchor: 180deg - cap-angle), 200%, (name: "mid", anchor: 180deg)),
        ((name: "outer", anchor: 90deg), 200%, (name: "mid", anchor: 90deg)),
        ((name: "outer", anchor: 0deg + cap-angle), 200%, (name: "mid", anchor: 0deg)),)
    })

    compound-path({
      circle(pos, radius: cetz.vector.add(radius, (thickness, thickness)), name: "outer")

      if show-hole {
        if cap-angle > 0deg {
          merge-path({
            arc-through("inner.0",
                        ((name: "outer", anchor: 90deg), 200%, (name: "mid", anchor: 90deg)),
                        "inner.1")
            arc-through("inner.1",
                        ((name: "outer", anchor: 270deg), 200%, (name: "mid", anchor: 270deg)),
                        "inner.0")
          }, close: true)
        } else {
          circle(pos, radius: cetz.vector.sub(radius, (thickness, thickness)))
        }
      }
    }, fill-rule: "even-odd", fill: fill, stroke: stroke)

    if cap-angle > 0deg and angle not in (0deg, 90deg, 180deg, 270deg) {
      arc-through(((name: "outer", anchor: 0deg - cap-angle), 200%, (name: "mid", anchor: 0deg)),
                  ((name: "outer", anchor: 270deg), 200%, (name: "mid", anchor: 270deg)),
                  ((name: "outer", anchor: 180deg + cap-angle), 200%, (name: "mid", anchor: 180deg)), fill: none, stroke: stroke)
    }
  })
}

#cetz.canvas({
  import cetz.draw: *

  torus((0, 0))
})
