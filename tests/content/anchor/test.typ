#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *
#import draw: content, rotate, scale, translate

#test-case({
  import draw: *
  content((0, 0), text(size: 40pt)[Yogurt], padding: (rest: 1, top: 2), frame: "rect", name: "content")
  line("content.base-west", "content.base-east", stroke: green)
  for-each-anchor("content", name => {
    content((), text(size: 6pt)[#name], frame: "rect",
      fill: white, stroke: none)
  })
})

#for a in ("center", "north", "south", "east", "west", "north-east", "north-west", "south-east", "south-west", "mid", "base") {
  test-case({
    cross((0,0))
    content((0,0), [#a], anchor: a)
  })

  test-case({
    cross((0,0))
    rotate(45deg)
    content((0,0), [#a (rotate)], anchor: a)
  })

  test-case({
    cross((0,0))
    translate((1,1))
    cross((0,0))
    content((0,0), [#a (translate)], anchor: a)
  })

  test-case({
    cross((0,0))
    scale(2)
    cross((0,0))
    content((0,0), [#a (scale)], anchor: a)
  })
}
