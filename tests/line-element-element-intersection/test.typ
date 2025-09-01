#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#let test(a, b, ..line-args) = {
  import draw: *

  a; b;
  line("a", "b", ..line-args)
}

#test-case({
  import draw: *

  test(rect((0,-.5), (rel: (1,1)), name: "a"),
       circle((3,0), name: "b"))
})

#test-case({
  import draw: *

  test(rect((0,-1), (rel: (1,1)), name: "a"),
       circle((2,1), name: "b"))
})

#test-case({
  import draw: *

  test(rect((0,-2), (rel: (1,1)), name: "a"),
       circle((2,2), name: "b"))
})

#test-case({
  import draw: *

  test(rect((0,0), (rel: (1,1)), name: "a"),
       rect((0,0), (rel: (1,1)), name: "b"))
})

#test-case({
  import draw: *

  set-style(content: (padding: .1))
  test(content((0,0), [Text], name: "a"),
       content((1,1), [Text], name: "b"))
})

#test-case({
  import draw: *

  set-style(content: (padding: .1))
  test(content((0,0), [Text], frame: "circle", name: "a"),
       content((1,1), [Text], frame: "circle", name: "b"))
})

#test-case({
  import draw: *

  set-style(content: (padding: .1))
  test(rect((0,0), (rel: (1,1)), name: "a"),
       group({
         line((2,2), (3,1), (rel: (0,2)), (rel: (-.1, -1.6)), close: true)
         anchor("default", (5,3))
       }, name: "b"))
})

#test-case({
  import cetz.draw: *

  // <point-a> perpendicular <point-b> <point-c>
  register-coordinate-resolver((ctx, coord) => {
    if type(coord) == array and coord.len() >= 2 and coord.at(1) == "perpendicular" {
      import cetz: vector
      let (p, _, a, b) = coord
      (_, p, a, b) = cetz.coordinate.resolve(ctx, p, a, b)

      let ap = vector.sub(p, a)
      let ab = vector.sub(b, a)

      return vector.add(a, vector.scale(ab, vector.dot(ap,ab)/vector.dot(ab,ab)))
    }

    return coord
  })

  scale(4)
  arc((), start: 15deg, stop: 35deg, radius: 5mm, mode: "PIE", fill: color.mix((green, 20%), white), anchor: "origin")
  let orig = (0, 0)
  let (o, a, b) = ((0, 0), (35deg, 1cm), (15deg, 1.25cm))
  line(o, a, mark: (end: ">"), name: "v1")
  line(o, b, mark: (end: ">"), name: "v2")

  // Because of a bug with `line`, curstom coordinates do not work properly,
  // so we create a named anchor.
  anchor("pt", ("v1.end", "perpendicular", "v2.start", "v2.end"))
  //line("v1.end", "pt", stroke: red)

  // #944: ERROR resolving coordinate:
  line("v1.end", ("v1.end", "perpendicular", "v2.start", "v2.end"),
    stroke: red)
})
