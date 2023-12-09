#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let display(body, ..args) = {
  import draw: *

  // Fixed distance
  (body)(..args, name: "elem");
  for i in (0, .5, 1) {
    circle((name: "elem", anchor: i), radius: .1)
  }

  set-origin((3,0))

  (body)(..args, name: "elem");
  for i in (0%, 25%, 50%, 75%, 100%) {
    circle((name: "elem", anchor: i), radius: .1)
  }
}

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(circle, (0,0))
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(circle-through, (-1,0), (0,1), (1,0))
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(arc, (0,0), start: 225deg, stop: 135deg, radius: 2, mode: "OPEN")
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(arc, (0,0), start: 225deg, stop: 135deg, radius: 2, mode: "PIE")
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(arc, (0,0), start: 225deg, stop: 135deg, radius: 2, mode: "CLOSE")
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(line, (-1,0), (0,1), (1,0))
}))

/*
#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(content, (), text(2cm)[Text])
}))
*/

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(rect, (-1,-1), (1,1))
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(rect, (-1,-1), (1,1), radius: .5)
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(bezier, (-2,0), (2,0), (-1,1), (1,-1))
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(bezier, (-1,-1), (1,-1), (0,2))
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(bezier-through, (-1,-1), (0,1), (1,-1))
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(catmull, (-2,0), (-1,-1), (0,1), (1,-1), (2,0))
}))
