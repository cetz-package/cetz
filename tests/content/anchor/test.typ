#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *
#import draw: content, rotate, scale, translate

#for a in ("center", "north", "south", "east", "west", "north-east", "north-west", "south-east", "south-west") {
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
  [\ ]
}
