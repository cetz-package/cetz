#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  merge-path({
    line((-1,0), (1,0))
    bezier((1,0), (-1,0), (1,1), (-1,1))
  }, fill: blue, fill-rule: "even-odd", name: "path")

  for-each-anchor("path", name => {
    cross("path." + name)
  })
})

#test-case({
  import draw: *

  set-ctx(ctx => {
    ctx.debug = true
    return ctx
  })

  let end-pos = (0.1, 1)
  let (tri-w, tri-h) = (0.5em, 1em)
  group({
    merge-path({
      rect((0,0), end-pos)
      line(end-pos,
        (rel: (y: -tri-h)),
        (rel: (tri-w, tri-h / 2)),
        close: true)
    }, stroke: none, fill: blue)
  }, padding: 0.5, name: "flag")
  hide(rect("flag.south-west", "flag.north-east"), bounds: true)
})
