#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

// Test aabb
#for angle in (0deg, 30deg, -30deg, 45deg, -45deg, 90deg, -90deg) {
  test-case({
    import draw: *
    content((), [Content], angle: angle)
  })
}

// Rotate to coordinate
#for angle in (0deg, 30deg, -30deg, 45deg, -45deg, 90deg, -90deg) {
  test-case({
    import draw: *
    let pt = (angle, 2)
    line((0,0), pt)
    content((0,0), [Content], angle: pt)
  })
}
