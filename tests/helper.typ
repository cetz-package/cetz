#import "/src/lib.typ" as cetz

/// Draw a point + label
#let point(pt, name, placement: "south", fill: black) = {
  import cetz.draw: scope, circle, content
  scope({
    let placements = (north: (rel: (0,  .2cm), to: "pt"),
                      south: (rel: (0, -.2cm), to: "pt"),
                      east: (rel: (.2cm, 0), to: "pt"),
                      west: (rel: (-.2cm, 0), to: "pt"))
    let offset = placements.at(placement, default: placement)
    circle(pt, radius: .05cm, fill: fill, stroke: none, name: "pt")
    content(offset, text(7pt)[#name], fill: white.transparentize(25%), frame: "rect", stroke: none, padding: .025cm)
  })
}

/// Draw a cross at position pt
#let cross(pt, size: .25, ..style) = {
  import cetz.draw: *
  scope({
    let len = size / 2
    line((rel: (-len,0), to: pt),
        (rel: (len, 0), to: pt), stroke: green, ..style)
    line((rel: (0,-len), to: pt),
        (rel: (0, len), to: pt), stroke: green, ..style)
  })
}

#let _show-anchor(element-name, anchor-name) = {
  import cetz.draw: *
  scope({
    anchor("pt", element-name + "." + anchor-name)
    anchor("label-pt", ("pt", -0.4cm, element-name + ".center"))
    on-layer(-1, {
      line(element-name + ".center", "pt", stroke: (dash: "dashed", paint: gray))
    })
    point("pt", [#anchor-name], placement: "label-pt", fill: blue)
  })
}

/// Show border anchors
#let show-border-anchors(body: none, element: "element") = {
  import cetz.draw: *
  let angles = range(0, 360, step: 45).map(v => v * 1deg)
  scope({
    body
    for angle in angles {
      _show-anchor(element, repr(angle))
    }
  })
}

/// Show compass anchors
#let show-compass-anchors(body: none, element: "element") = {
  import cetz.draw: *
  let names = ("north", "north-west", "north-east", "south", "south-west", "south-east", "east", "west")
  scope({
    body
    for name in names {
      _show-anchor(element, name)
    }
  })
}

/// Test case canvas surrounded by a red border
#let test-case(body, ..canvas-args, args: none) = {
  if type(body) != function {
    body = _ => { body }
    args = (none,)
  } else {
    assert(type(args) == array and args.len() > 0,
      message: "Function body requires args set!")
  }

  for arg in args {
    block(stroke: 2pt + red,
      cetz.canvas(..canvas-args, {
        body(arg)
      })
    )
  }
}
