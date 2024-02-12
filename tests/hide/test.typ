#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *
  rect((0,0), (5,5))

  // Hide a circle
  hide(circle((6,6)))

  // Hide content
  hide(content((-6,-6), [Hidden]))

  // Hide multiple elements
  hide({
    rect((0,0), (1,1))
    rect((1,1), (2,2))
    rect((2,2), (3,3))
  })

  // Use hidden anchor
  hide(line((0,0), (2.5, 2.5), name: "line"))
  content("line.end", [Hidden anchor])
})

#test-case({
  import draw: *

  merge-path({
    arc((0,0), start: 0deg, stop: 180deg)
    hide({
      // This gets ignored
      line((), (rel: (-5,0), update: false))
    })
    line((), (rel: (1, -1)))
  }, close: true)
})

#test-case({
  import draw: *

  hide(line((-1,-1), (1,1)), bounds: true)
})
