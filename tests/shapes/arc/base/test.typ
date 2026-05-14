#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case(mode => {
  import draw: *

  arc((0,0), start: 135deg, stop: 225deg, name: "a", mode: mode)
  show-path-anchors("a")
}, args: ("OPEN", "CLOSE", "PIE"))

#test-case(mode => {
  import draw: *

  arc((0,0), start: 135deg, stop: 225deg, name: "a", mode: mode)
  show-compass-anchors("a")
}, args: ("CLOSE", "PIE"))

#test-case(mode => {
  import draw: *

  arc((0,0), start: 135deg, stop: 225deg, name: "a", mode: mode)
  show-border-anchors("a")
}, args: ("CLOSE", "PIE"))

#test-case({
  import draw: *

  arc((0,0), start: 135deg, stop: 225deg, name: "a")
  show-path-anchors("a")
})

#test-case({
  import draw: *

  arc((0,0), start: 180deg, stop: 0deg, update-position: false)
  point((), [current])
})
