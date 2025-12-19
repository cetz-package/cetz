#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  group(name: "g", {
    anchor("a", (1, 1))
    scope({
      anchor("b", (-1, -1))
    })
  })

  line("g.a", "g.b")
})

#test-case({
  import draw: *

  group(name: "g", {
    anchor("a", (1, 1))
    scope({
      scope({
        scope({
          anchor("b", (-1, -1))
        })
      })
    })
  })

  line("g.a", "g.b")
})

#test-case({
  import draw: *

  group(name: "g", {
    anchor("a", (1, 1))
    scope({
      anchor("b", (-1, 0))
    })
    anchor("b", (-1, -1)) // Must overwrite previous "b"
  })

  line("g.a", "g.b")
})

#test-case({
  import draw: *

  group(name: "g", {
    anchor("a", (1, 1))
    anchor("b", (-1, 0))
    scope({
      anchor("b", (-1, -1)) // Must overwrite previous "b"
    })
  })

  line("g.a", "g.b")
})

#test-case({
  import draw: *

  group(name: "g", {
    scope({
      rect((-1, -1), (1, 1), name: "a")
      rotate(45deg)
      rect((-1, -1), (1, 1), name: "b")
    })
  })

  // Access nested elements
  line("g.a.north", "g.b.south-west")
})
