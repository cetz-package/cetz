#import "/src/lib.typ" as cetz

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
