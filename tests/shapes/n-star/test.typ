#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case(
  sides => {
    import cetz.draw: *

    n-star((0, 0), sides, angle: 9deg, stroke: luma(200) + 1pt)
    set-origin((3, 0))
    n-star((0, 0), sides, radius: (1, 1.5), angle: 30deg)
    set-origin((4, 0))
    n-star((0, 0), sides, radius: (1, 2), angle: 60deg, fill: red)
    set-origin((4.5, 0))
    n-star((0, 0), sides, radius: (1, 2.5), angle: 90deg, fill: blue, show-inner: true)
  },
  args: (3, 4, 5, 6, 7),
)
