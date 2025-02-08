#set page(width: auto, height: auto)
#import "/tests/helper.typ": *

#test-case({
  import cetz.draw: *

  group(name: "g", {
    rotate(10deg)
    rect((-1, -1), (1, 1), radius: .45)
  })

  for i in range(0, 360, step: 10) {
    let pt = (i * 1deg,  2)

    find-closest-point("test", pt, {
      rotate(10deg)
      hide(rect((-1, -1), (1, 1), radius: .45))
    })

    line(pt, "test")
    circle(pt, radius: .1, fill: blue)
  }
})

#test-case({
  import cetz.draw: *

  group(name: "g", {
    rotate(10deg)
    rect((-1, -1), (1, 1), radius: .45)
  })

  let pt = (2, 2)
  find-closest-point("test", pt, "g")
  line("test", pt)
})
