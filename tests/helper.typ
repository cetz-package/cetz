#import "/src/lib.typ" as cetz

/// Draw a point + label
#let point(pt, name, anchor: "west", offset: (0, 0)) = {
  cetz.draw.circle(pt, radius: 1pt, fill: black, stroke: none, name: "pt")
  cetz.draw.content((rel: offset, to: "pt"), [#name], anchor: anchor)
}

/// Draw a cross at position pt
#let cross(pt, size: .25, ..style) = {
  import cetz.draw: *
  let len = size / 2
  line((rel: (-len,0), to: pt),
       (rel: (len, 0), to: pt), stroke: green, ..style)
  line((rel: (0,-len), to: pt),
       (rel: (0, len), to: pt), stroke: green, ..style)
}

#let _outset-point(center, ref, distance: 0.5) = {
  let d = cetz.vector.sub(ref, center)
  if cetz.vector.len(d) == 0 { d = (0, 1, 0) }
  cetz.vector.add(ref, cetz.vector.scale(cetz.vector.norm(d), distance))
}

#let show-named-anchors(center: "center", element, ..names) = {
  import cetz.draw: *
  for name in names.pos() {
    circle(element + "." + name, radius: 1pt, fill: black, name: "pt")
    if center != none {
      content((_outset-point, element + "." + center, "pt"), text(7pt)[#name])
    } else {
      content((rel: (0, 0.15), to: "pt"), text(7pt)[#name], anchor: "west", angle: 90deg)
    }
  }
}

#let show-compass-anchors(center: "center", element, ..names) = {
  import cetz.draw: *
  let compass-names = (
    "north", "north-east", "north-west",
    "east", "west",
    "south", "south-east", "south-west")
  show-named-anchors(center: center, element, ..names, ..compass-names)
}

#let show-border-anchors(center: "center", element, ..anchors) = {
  import cetz.draw: *
  let angles = if anchors.pos() == () {
    (0deg, 45deg, 90deg, 135deg, 180deg, 225deg, 270deg, 315deg)
  } else {
    anchors.pos()
  }
  for angle in angles {
    circle((name: element, anchor: angle), radius: 1pt, fill: black, name: "pt")
    if center != none {
      content((_outset-point, element + "." + center, "pt"), text(7pt)[#repr(angle)])
    } else {
      content((rel: (0, 0.15), to: "pt"), text(7pt)[#repr(angle)], anchor: "west", angle: 90deg)
    }
  }
}

#let show-path-anchors(center: "center", element, ..anchors) = {
  import cetz.draw: *
  let lengths = if anchors.pos() == () {
    (0, 1cm, 25%, 50%, 75%)
  } else {
    anchors.pos()
  }
  for l in lengths {
    circle((name: element, anchor: l), radius: 1pt, fill: black, name: "pt")
    if center != none {
      content((_outset-point, element + "." + center, "pt"), text(7pt)[#repr(l)])
    } else {
      content((rel: (0, 0.15), to: "pt"), text(7pt)[#repr(l)], anchor: "west", angle: 90deg)
    }
  }
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
