#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let display(body, ..args, angle: false) = {
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

  if angle {
    set-origin((3,0))

    (body)(..args, name: "elem");
    for i in (0deg, 45deg, 90deg, 170deg, 180deg) {
      circle((name: "elem", anchor: i), radius: .1)
    }
  }
}

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(line, (0,0), (.75,1), (1.25,-1), (2,0))
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(circle, (0,0), angle: true)
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(circle-through, (-1,0), (0,1), (1,0), angle: true)
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
  display(rect, (-1,-1), (1,1), angle: true)
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

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(group, {
    circle((0,0), radius: .5)
    circle((1,1), radius: .7)
  }, angle: true)
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  rotate(10deg)
  rect((-1,-1), (1,1), name: "a")
  for i in (0, 1, 2, 3, 4, 5, 6, 7) {
    circle((name: "a", anchor: i), radius: .1)
  }

  set-origin((3,0))

  rect((-1,-1), (1,1), name: "a")
  for i in (0%, 10%, 20%, 30%, 40%, 50%) {
    circle((name: "a", anchor: i), radius: .1)
  }

  set-origin((3, 0))

  rect((-1,-1), (1,1), name: "a")
  for i in range(0, 360, step: 36) {
    let i = i * 1deg
    circle((name: "a", anchor: i), radius: .1)
  }
}))
