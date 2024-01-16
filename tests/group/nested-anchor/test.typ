#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *

  group(name: "g", {
    group(name: "inner-1", {
      group(name: "inner-2", {
        rect((-1,-1), (1,1))
        anchor("p1", (1,1))
      })
      copy-anchors("inner-2")
      anchor("p2", (-1,-1))
    })
    copy-anchors("inner-1")
  })

  circle("g.p1", fill: blue)
  circle("g.p2", fill: red)
}))
