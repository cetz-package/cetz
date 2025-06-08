#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  compound-path({
    rect((-1,-1),(1,1))
    circle((0,0))
  }, fill: blue, fill-rule: "even-odd", name: "path")

  for-each-anchor("path", name => {
    cross("path." + name)
  })
})
