#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *
  grid((-2,-1), (7,1), stroke: gray)

  let a = (1,0)
  let b = (4,0)

  set-style(circle: (radius: .1))
  for i in (-50%, 0%, 50%, 100%, 150%) {
    let pt = (a, i, b)
    circle(pt)
    content(pt, repr(i), anchor: "north", padding: (top: .5))
  }
})

#test-case({
  import draw: *
  grid((-2,-1), (7,1), stroke: gray)

  let a = (1,0)
  let b = (4,0)

  set-style(circle: (radius: .1))
  for i in (-1.5, 0, 1.5, 3, 4.5) {
    let pt = (a, i, b)
    circle(pt)
    content(pt, repr(i), anchor: "north", padding: (top: .5))
  }
})


#test-case({
  import draw: *
  grid((-2,-1), (7,1), stroke: gray)

  let a = (1,0)
  let b = (4,0)

  set-style(circle: (radius: .1))
  for i in (-1.5cm, 0cm, 1.5cm, 3cm, 4.5cm) {
    let pt = (a, i, b)
    circle(pt)
    content(pt, repr(i), anchor: "north", padding: (top: .5))
  }
})
