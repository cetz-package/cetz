#set page(width: auto, height: auto)
#import "/src/lib.typ": *

This is an example #canvas(baseline: "text.base", stroke: red, {
  import draw: *

  content((0,0), [A letter: g], name: "text")
  hobby("text.north-west", (rel: (0, 1), to: ("text.north-east", 50%, "text.north-west")), "text.north-east", mark: (start: "|", end: ">"))
}) with an inline canvas!


This is an example #canvas(baseline: (0, 0), stroke: red, {
  import draw: *

  content((0,0), [Picture \ Picture \ Picture])
}) with an inline canvas!

By default #canvas(stroke: red, {
  import draw: *

  content((0,0), [Picture])
}) is a "block level" element.
