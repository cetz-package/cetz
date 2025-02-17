#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#for w in range(1, 10) {
  let w = w / 10
  let l = 1
  box(stroke: 2pt + red, canvas({
    import draw: *

    for x in range(0, 8) {
      let width = (x + 1) * 1pt
      let x = x * 2

      set-style(stroke: width, mark: (width: w, length: 1, scale: .4, stroke: width))
      line((x,0), (x,3), mark: (end: ">", start: ">"))

      line((x - .5,3), (x + .5,3), stroke: .5pt + green)
      line((x - .5,0), (x + .5,0), stroke: .5pt + green)
    }
    for x in range(0, 8) {
      let width = (x + 1) * 1pt
      let x = x * 2 + 2 * 8

      set-style(stroke: width, mark: (width: w, length: 1, scale: .4, stroke: width + red))
      line((x,0), (x,3), mark: (end: "<", start: "<"))

      line((x - .5,3), (x + .5,3), stroke: .5pt + green)
      line((x - .5,0), (x + .5,0), stroke: .5pt + green)
    }
  }))
  par([])
}

#box(stroke: 2pt + red, canvas({
  import draw: *
  rect((1,-1), (2,2))
  rect((-2,-1), (-1,2))
  bezier((-1,-.5), (1,1), (0,-.5), (0,1),
    mark: (start: ">", end: ">", fill: red, stroke: blue, flex: false))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  rect((1,-1), (2,2))
  rect((-2,-1), (-1,2))
  bezier((-1,-.5), (1,1), (0,-.5), (0,1),
    mark: (start: ">", end: ">", fill: red, stroke: blue, flex: true))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  rect((1,-1), (2,2))
  rect((-2,-1), (-1,2))
  bezier((-1,-.5), (1,1), (0,-.5), (0,1),
    mark: (start: "|", end: "o", fill: red, stroke: blue))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  rect((1,-1), (2,2))
  rect((-2,-1), (-1,2))
  catmull((-1,-.5), (0,-.5), (0,1), (1,1),
    mark: (start: ">", end: ">", fill: red, stroke: blue))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  rect((1,-1), (2,2))
  rect((-2,-1), (-1,2))
  hobby((-1,-.5), (0,-.5), (0,1), (1,1),
    mark: (start: ">", end: ">", fill: red, stroke: blue))
}))
