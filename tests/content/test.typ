#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *
  content((0,0), [This is a test.])
})

#test-case({
  import draw: *
  content((0,0), auto, [This is a test.], frame: "rect")
})

#test-case({
  import draw: *
  content((0,0), (1.5,1), [This is a test.], frame: "rect")
})

#test-case({
  import draw: *
  content((0,0), (1,1.5), [This is a test.], frame: "rect")
})

#test-case({
  import draw: *
  content((0,0), auto, angle: 45deg, [This is a test.], frame: "rect")
})

#test-case({
  import draw: *
  content((0,0), (1,1.5), angle: 45deg, [This is a test.], frame: "rect")
})

#test-case({
  import draw: *
  content((0,0), (1.5,1), angle: 45deg, [This is a test.], frame: "rect")
})

#test-case({
  import draw: *
  content((0,0), auto, angle: 0deg, [This is a test.], frame: "circle")
})

#test-case({
  import draw: *
  content((0,0), auto, angle: 45deg, [This is a test.], frame: "circle")
})

#test-case({
  import draw: *
  content((0,0), (1,1.5), angle: 45deg, [This is a test.], frame: "circle")
})

#test-case({
  import draw: *
  set-style(content: (frame: "circle", stroke: 3pt), fill: blue)
  content((0,0), (1,1), angle: 15deg,
    text(white, align(center+horizon)[With style!]))
})

#test-case({
  import draw: *
  circle((0,0), name: "c")
  content((0,0), angle: "c.north-east", [Text])
})

// Test the z coordinate is respected
#test-case({
  import draw: *
  content((0, 0,-1), [Z=-1])
  content((0, 0, 0), [Z=0])
  content((0, 0, 1), [Z=1])
})

// Test inline math measuring
#test-case({
  import draw: *
  content((0, 0), $x$)
})

#test-case({
  import draw: *

  let elements = ("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l")

  line((1, 4), (13, 4), (13, 3), (1, 3), close: true)

  for i in range(1, 13) {
    line((i, 4), (i, 3))
    content((i + 0.5, 3.5), text(bottom-edge:"descender", top-edge: "ascender")[#elements.at(i - 1)])
  }
})

#test-case({
  import draw:*
  content((-1,0), [Text], name: "a")
  content((+1,0), [Text], name: "b")
  line("a", "b")
})

// Compiler crash
#test-case({
  import draw: *
  rect((-1,-1), (1,1))
  content((0,0), [Test], padding: -1, frame: "rect")
})
