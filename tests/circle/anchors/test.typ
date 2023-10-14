#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *
  
  circle((0,0), radius: (2,3), name: "c")
  for-each-anchor("c", name => {
    content("c."+name, box(fill: white)[#name])
  })
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  
  rotate(45deg)
  circle((0,0), radius: (2,3), name: "c")
  for-each-anchor("c", name => {
    content("c."+name, box(fill: white)[#name])
  })
}))
