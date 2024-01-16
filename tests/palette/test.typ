#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  import palette

  let p = palette.pink
  for i in range(0, p("len")) {
    set-style(..p(i))
    rect((0,0), (1,1))
    set-origin((1,0))
  }
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  import palette

  let p = palette.new(
    base: (stroke: (paint: none, dash: "dashed")),
    colors: (red, green, blue),
    dash: ("solid", "dashed", "dotted"))
  for i in range(0, p("len")) {
    set-style(..p(i, stroke: true, fill: false))
    circle((.5,.5), radius: .5)
    set-origin((1,0))
  }
}))
