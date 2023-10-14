#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *
  
  rect((0,0), (4,2), name: "r")
  for-each-anchor("r", name => {
    content("r."+name, box(fill: white)[#name])
  })
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  
  rotate(45deg)
  rect((0,0), (4,2), name: "r")
  for-each-anchor("r", name => {
    content("r."+name, box(fill: white)[#name])
  })
}))
