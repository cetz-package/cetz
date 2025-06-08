#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  merge-path({
    line((0,0), (1,0))
    bezier-through((1,0), (1/2,1), (0,0))
  }, fill: blue, name: "path")

  for-each-anchor("path", name => {
    cross("path." + name)
  })
})
