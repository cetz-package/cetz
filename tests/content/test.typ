#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  content((0,0), [This is a test.])
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  content((0,0), auto, [This is a test.], frame: "rect")
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  content((0,0), (1.5,1), [This is a test.], frame: "rect")
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  content((0,0), (1,1.5), [This is a test.], frame: "rect")
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  content((0,0), auto, angle: 45deg, [This is a test.], frame: "rect")
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  content((0,0), (1,1.5), angle: 45deg, [This is a test.], frame: "rect")
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  content((0,0), (1.5,1), angle: 45deg, [This is a test.], frame: "rect")
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  content((0,0), auto, angle: 0deg, [This is a test.], frame: "circle")
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  content((0,0), auto, angle: 45deg, [This is a test.], frame: "circle")
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  content((0,0), (1,1.5), angle: 45deg, [This is a test.], frame: "circle")
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  set-style(content: (frame: "circle", stroke: 3pt), fill: blue)
  content((0,0), (1,1), angle: 15deg,
    text(white, align(center+horizon)[With style!]))
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  circle((0,0), name: "c")
  content((0,0), angle: "c.north-east", [Text])
}))

// Test the z coordinate is respected
#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  content((0, 0,-1), [Z=-1])
  content((0, 0, 0), [Z=0])
  content((0, 0, 1), [Z=1])
}))

// Test inline math measuring
#context box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  content((0, 0), $x$)
}))

#context box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  let elements = ("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l")

  line((1, 4), (13, 4), (13, 3), (1, 3), close: true)

  for i in range(1, 13) {
    line((i, 4), (i, 3))
    content((i + 0.5, 3.5), text(bottom-edge:"descender", top-edge: "ascender")[#elements.at(i - 1)])
  }
}))
