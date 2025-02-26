#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

// Test various style combinations that produce
// no marks but must compile
#test-case({
  import draw: *

  let styles = (
    (mark: none),
    (mark: (:)),
    (mark: (symbol: none)),
    (mark: (start: none)),
    (mark: (end: none)),
    (mark: (symbol: ">")),
    (line: (mark: none)),
    (line: (mark: (symbol: none))),
  )

  for s in styles {
    scope({
      set-style(..s)
      hide(line((0,0), (1,0)))
    })
  }
})

// Test various style combinations that produce a mark
#test-case({
  import draw: *

  let styles = (
    (mark: (end: ">")),
    (mark: (start: ">")),
    (mark: (start: ">", end: ">")),
  )

  for s in styles {
    translate((0, 1))
    scope({
      set-style(..s)
      line((0,0), (1,0))
    })
  }
})
