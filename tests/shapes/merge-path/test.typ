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
