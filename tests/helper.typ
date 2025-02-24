#import "/src/lib.typ" as cetz

/// Draw a point + label
#let point(pt, name) = {
  cetz.draw.circle(pt, radius: .05cm, fill: black, stroke: none, name: "pt")
  cetz.draw.content((rel: (.2cm, 0), to: "pt"), [#name], anchor: "west")
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
