#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *

  let next(body) = {
    translate((0,-.2,0))
    group(body)
  }

  next({
    line((0,0), (1,0))
  })
  next({
    set-style(stroke: blue)
    line((0,0), (1,0))
  })
  next({
    line((0,0), (1,0), stroke: blue)
  })
  next({
    // Blue arrow
    set-style(stroke: blue)
    line((0,0), (1,0), mark: (end: ">"))
  })
  next({
    // Blue arrow
    line((0,0), (1,0), mark: (end: ">"), stroke: blue)
  })
  next({
    // Blue + Green arrow head
    line((0,0), (1,0), mark: (end: ">", stroke: green), stroke: blue)
  })
  next({
    // Blue + Yellow arrow head
    set-style(mark: (stroke: yellow))
    line((0,0), (1,0), mark: (end: ">"), stroke: blue)
  })
  next({
    // Blue + Green arrow head
    set-style(mark: (stroke: yellow), stroke: red)
    line((0,0), (1,0), mark: (end: ">", stroke: green), stroke: blue)
  })
  next({
    // Blue + Yellow/Green arrow head
    set-style(mark: (stroke: yellow, fill: auto), stroke: blue, fill: blue)
    line((0,0), (1,0), mark: (end: ">"), fill: green, stroke: green)
  })
  next({
    // Blue arrow
    set-style(stroke: red)
    line((0,0), (1,0), mark: (end: ">"), stroke: blue)
  })
}))

