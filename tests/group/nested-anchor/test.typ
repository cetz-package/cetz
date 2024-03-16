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

#box(stroke: 2pt + red, canvas({
  import draw: *

  group(name: "parent", {
    content((0,0), [Content], name: "content")
    group(name: "child", {
      circle((1,-2), fill: blue, name: "circle")
    })
  })

  rect("parent.content.south-west",
       "parent.content.north-east", stroke: green)
  rect(
    "parent.child.circle.-45deg",
    "parent.child.circle.135deg",
    stroke: green
  )
}))