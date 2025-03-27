#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#let path0 = ()
#let path1 = (
  ("m", (0, 0)),
  ("l", (1, 0)),
)
#let path2 = (
  ("m", (0, 0)),
  ("l", (1, 0)),
  ("z",)
)
#let path3 = (
  ("m", (0, 0)),
  ("l", (1, 0)),
  ("m", (0, 1)),
  ("l", (1, 1)),
)

/*
#assert.eq(path-util.split(path0).len(), 0)
#assert.eq(path-util.split(path1).len(), 1)
#assert.eq(path-util.split(path2).len(), 1)
#assert.eq(path-util.split(path3).len(), 2)

#assert.eq(path-util.first-path-start(path0), none)
#assert.eq(path-util.last-path-end(path0), none)
#assert.eq(path-util.first-path-start(path1), (0, 0))
#assert.eq(path-util.last-path-end(path1), (1, 0))
#assert.eq(path-util.first-path-start(path2), (0, 0))
#assert.eq(path-util.last-path-end(path2), (0, 0))
#assert.eq(path-util.first-path-start(path3), (0, 0))
#assert.eq(path-util.last-path-end(path3), (1, 1))
*/
