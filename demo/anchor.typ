#import "../canvas.typ": *

#canvas(fill: gray, length: 1cm, {
  import "../draw.typ": *
  stroke(black + .5pt)

  // Put circles at both sides of a node
  line((0,0), (1,0), name: "a")
  circle((node: "a", at: "end"), radius: .1)
  circle((node: "a", at: "start"), radius: .1)

  // Create custom anchors
  /* NEEDS FIX
  group(name: "b", {
    line((0,1), (1,1))
    anchor("mid", (.5,1))
  })
  circle((node: "b", at: "mid"), radius: .1)
  */
})
