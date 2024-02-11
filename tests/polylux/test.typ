#import "/src/lib.typ": *
#import "@preview/polylux:0.3.1" as pl
#import pl: *

#set page(width: auto, height: auto)

#polylux-slide[
  Heading
  #canvas(polylux: pl, {
    import draw: *
    import polylux: *

    rect((-1,-1), (1,1), fill: red)
    only(2, circle((.5,.3), fill: blue))
    uncover("2-3", {
      line((.2,.1), (rel: (1,1.3)), (rel: (.7, -1.8)), fill: green, close: true)
      content((0, -2), [Hello])
    })
  })
]
