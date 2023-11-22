#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let cases = (
  (samples: 2, res: ((0,0), (100,10))),
  (samples: 5, res: ((0,0), (25,2.5), (50,5.0), (75,7.5), (100,10.0))),
  (samples: 2, res: ((0,0), (50,5.0), (60,6.0), (100,10)), extra: (50,60)),
)
#for c in cases {
  let pts = plot.sample-fn(x => x/10, (0, 100), c.samples,
    sample-at: c.at("extra", default: ()))
  assert.eq(pts, c.res,
    message: "Expected: " + repr(c.res) + ", got: " + repr(pts))
}

#let cases = (
  (samples: (2,2), res: ((  0,100),
                         (100,200))),
  (samples: (3,3), res: ((  0, 50,100),
                         ( 50,100,150),
                         (100,150,200))),
)
#for c in cases {
  let rows = plot.sample-fn2((x, y) => x + y, (0, 100), (0,100),
    c.samples.at(0), c.samples.at(1))
  assert.eq(rows, c.res,
    message: "Expected: " + repr(c.res) + ", got: " + repr(rows))
}

#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (3, 1), axis-style: none, {
    plot.add(domain: (0, 100), x => 0, mark: "x", samples: 2)
    plot.add(domain: (0, 100), x => 1, mark: "x", samples: 5)
  })
}))
