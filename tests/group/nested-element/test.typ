#set page(width: auto, height: auto)
#import "/src/lib.typ": *

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
  rect((name: "parent.child.circle", anchor: -45deg),
       (name: "parent.child.circle", anchor: +135deg), stroke: green)
}))
