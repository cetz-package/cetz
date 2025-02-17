#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *

  line((-1,0), (1,0), mark: (start: ">", end: ">"))
  line((0,-1), (0,1), mark: (start: ">", end: ">"))
  line((0,0,-1), (0,0,1), mark: (start: ">", end: ">",
    scale: 1))
}))
