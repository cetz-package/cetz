#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *

  place-marks(line((0, 0), (1, 0)),
    fill: green,
    (mark: ">", pos: 0),
    (mark: ">", pos: 1),
    (mark: "|", pos: .5))

  translate((0, 1))
  place-marks(bezier((0, 0), (1, 0), (.5, .5)),
    fill: green,
    (mark: ">", pos: 0),
    (mark: ">", pos: 1),
    (mark: "|", pos: .5))

  translate((0, 1))
  place-marks(bezier((0, 0), (1, 0), (.33, .5), (.66, -.5)),
    fill: green,
    (mark: ">", pos: 0),
    (mark: ">", pos: 1),
    (mark: "|", pos: .5))

  translate((0, 1))
  place-marks(line((0, 0), (.33, .2), (.66, -.2), (1, 0)),
    fill: green,
    (mark: ">", pos: 0),
    (mark: ">", pos: 1),
    (mark: "|", pos: .5))

  translate((0, 1))
  place-marks(merge-path({
      line((0,0), (1,0))
      bezier((), (0,0), (1,1), (0,1))
    }),
    fill: green,
    (mark: ">", pos: 0),
    (mark: ">", pos: 1),
    (mark: "|", pos: .5))

  translate((0, 1))
  place-marks(circle((.5,.5), radius: .5),
    fill: green,
    (mark: ">", pos: 0.05),
    (mark: ">", pos: 0.95),
    (mark: "o", pos: .25),
    (mark: "<>", pos:.75),
    (mark: "|", pos: .5))
}))
