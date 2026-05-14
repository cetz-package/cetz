#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  group(name: "b", {
    group(name: "a", {
      rect((-1,-1), (1,1))
      anchor("my-anchor", (0,0))
    })

    copy-anchors("a")
    circle("my-anchor", radius: .1, stroke: red)
  })

  circle("b.my-anchor", radius: .2, stroke: blue)
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  group(name: "a", {
    group(name: "b", {
      line((), (1,1), name: "l")
    })
    copy-anchors("b")
    circle("l.end")
  })

  circle("a.l.start")
}))