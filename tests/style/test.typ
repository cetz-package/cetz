#set page(width: auto, height: auto)
#import "../../src/lib.typ": *

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
    set-style(mark: (stroke: yellow), stroke: blue)
    line((0,0), (1,0), mark: (end: ">"), fill: green)
  })
  next({
    // Blue arrow
    set-style(mark: (stroke: yellow), stroke: red)
    line((0,0), (1,0), mark: (end: ">", stroke: "inherit"), stroke: blue)
  })
}))

#canvas({
  import draw: *

  group(ctx => {
    let s = styles.resolve(ctx.style, (:), root: "test1")
    assert(s == (:), message: "Non existing root must return empty dictionary.")

    line((), ())
  })

  group(ctx => {
    let n = (a: 1, fill: "inherit", mark: "inherit", stroke: "inherit")
    let s = styles.resolve(ctx.style, (mark: (end: ">")), root: "test1", inject: n)

    assert.eq(s.a, 1)
    assert(type(s.stroke) == "stroke")
    assert.eq(s.mark.end, ">")
    assert.eq(s.mark.start, none)

    line((), ())
  })
})
