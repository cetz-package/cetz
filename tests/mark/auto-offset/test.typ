#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#for a in range(30, 180 + 30, step: 30) {
  let a = a * 1deg
  box(stroke: 2pt + red, canvas({
    import draw: *

    for x in range(0, 8) {
      let width = (x + 1) * 1pt
      let x = x * 2

      set-style(stroke: width, mark: (angle: a, size: 1, stroke: width))
      line((x,0), (x,3), mark: (end: ">", start: ">"))

      line((x - .5,3), (x + .5,3), stroke: .5pt + green)
      line((x - .5,0), (x + .5,0), stroke: .5pt + green)
    }
    for x in range(0, 8) {
      let width = (x + 1) * 1pt
      let x = x * 2 + 2 * 8

      set-style(stroke: width, mark: (angle: a, size: 1, stroke: width))
      line((x,0), (x,3), mark: (end: "<", start: "<"))

      line((x - .5,3), (x + .5,3), stroke: .5pt + green)
      line((x - .5,0), (x + .5,0), stroke: .5pt + green)
    }
  }))
  par([])
}
