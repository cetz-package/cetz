#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas({
  import "../../draw.typ": *

  group(name: "g", {
    rotate(37deg)
    bezier((0,0), (0, 10), (1,-10), (-5,20))
  })
  rect("g.bottom-left", "g.top-right", stroke: .5pt + red)
}))
