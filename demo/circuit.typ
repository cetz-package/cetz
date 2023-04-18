#import "../canvas.typ": *

#set page(width: auto, height: auto)

#canvas(fill: gray, length: 1cm, {
  import "../draw.typ": *
  stroke(1pt + black)

  let ground(name: none) = {
    group(name: name, {
      anchor("default", ())
      line((), (rel: (0, -1)))
      stroke(2pt + black)
      line((rel: (-.5, 0)), (rel: (1, 0)))
      line((rel: (-.9, -.15)), (rel: (.8, 0)))
      line((rel: (-.7, -.15)), (rel: (.6, 0)))
    })
  }

  let resistor(name: none) = {
    let height = .4
    let pin-length = .4
    group(name: name, move: true, {
      anchor("left", ())
      line((), (rel: (pin-length, 0)))
      rect((rel: (0, - height/2, 0)), (rel: (1, height, 0)))
      line((rel: (0, - height/2)), (rel: (pin-length, 0)))
      anchor("right", ())
      anchor("default", ())
    })
  }

  let diode(name: none) = {
    group(name: name, move: true, {
      anchor("left", ())
      line((rel: (0, -.5)), (rel: (0, 1)), (rel: (1, -.5)), cycle: true)
      line((rel: (0, -.5)), (rel: (0, 1)))
      anchor("right", (rel: (0, -.5), move: false))
      anchor("default", (rel: (0, -.5)))
    })
  }

  ground()
  resistor(name: "r1")
  resistor()
  ground()

  line("r1.left", (rel: (0, 1)))
  resistor()
  diode()
  line((), (rel: (.5, 0)))

  content((0, 2), [Just some random symbols])
})
