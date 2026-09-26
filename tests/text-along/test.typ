#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/src/path-measure.typ"
#import "/src/lib/decorations/text-layout.typ"
#import "/tests/helper.typ": *

#let near(a, b, epsilon: 1e-3) = calc.abs(a - b) <= epsilon
#let point-near(a, b, epsilon: 1e-3) = a.zip(b).all(((x, y)) => near(x, y, epsilon: epsilon))

// Line strips, closing edges, and split subpaths measure separately.
#{
  let strip = (((0, 0), false, (("l", (1, 0), (1, 1)),)),)
  let measure = path-measure.build(strip).first()
  assert(near(measure.total, 2))
  assert.eq(measure.pieces.len(), 2)
  assert.eq(measure.corners.len(), 1)
  assert(point-near(path-measure.point-at(measure, 25%).point, (.5, 0, 0)))
  let reverse = path-measure.point-at(measure, 25%, reverse: true)
  assert(point-near(reverse.point, (1, .5, 0)))
  assert(point-near(reverse.direction, (0, -1, 0)))
  // At a join, reverse uses the outgoing segment.
  assert(point-near(path-measure.point-at(measure, 50%, reverse: true).direction,
    (-1, 0, 0)))

  let closed = path-measure.build((
    ((0, 0), true, (("l", (1, 0), (1, 1)),)),
  )).first()
  assert(near(closed.total, 2 + calc.sqrt(2)))
  assert.eq(closed.pieces.len(), 3)
  assert.eq(closed.corners.len(), 3)

  let disconnected = path-measure.build((
    ((0, 0), false, (("l", (1, 0)),)),
    ((10, 0), false, (("l", (11, 0)),)),
  ))
  assert.eq(disconnected.len(), 2)
  assert.eq(disconnected.map(m => m.total), (1, 1))
  assert(point-near(path-measure.point-at(disconnected.at(1), 50%).point, (10.5, 0, 0)))
  let spatial = path-measure.build((((0, 0, 0), false, (("l", (1, 0, 1)),)),)).first()
  assert.eq(spatial.xy-planar, false)
}

// Nonuniform cubics need adaptive subdivision.
#{
  let curve = (((0, 0), false, (("c", (0, 0), (0, 0), (1, 0)),)),)
  let measure = path-measure.build(curve).first()
  let middle = path-measure.point-at(measure, 50%)
  assert(near(measure.total, 1))
  assert(near(middle.point.first(), .5, epsilon: .003))
  assert(point-near(path-measure.point-at(measure, 0).direction, (1, 0, 0)))
  assert.eq(measure.corners, ())
}

// Error control is scale independent.
#{
  let scaled(k) = path-measure.build((
    ((0, 0), false, (("c", (0, k), (k, k), (k, 0)),)),
  )).first()
  let tiny = scaled(1e-9)
  let unit = scaled(1)
  let huge = scaled(1e9)
  assert(near(tiny.total / 1e-9, unit.total, epsilon: 1e-5))
  assert(near(huge.total / 1e9, unit.total, epsilon: 1e-5))
  for measure in (tiny, unit, huge) {
    let scale = measure.pieces.first().curve.at(1).first()
    let middle = path-measure.point-at(measure, 50%).point
    assert(near(middle.first() / scale, .5, epsilon: .002))
    assert(near(middle.at(1) / scale, .75, epsilon: .002))
  }

  // Loops with coincident endpoints keep positive length.
  let loop = path-measure.build((
    ((0, 0), false, (("c", (1, 1), (-1, 1), (0, 0)),)),
  )).first()
  assert(loop.total > 2)
  assert(path-measure.point-at(loop, 50%) != none)
}

// Transparent styles split. Opaque content stays whole.
#{
  let clusters = text-layout.tokenize([*ab* #box[$x^2$] c])
  assert.eq(clusters.len(), 6)
  assert(text-layout.is-space(clusters.at(2)))
  assert(text-layout.is-space(text-layout.tokenize(linebreak()).first()))
  let rigid = text-layout.tokenize(([office], [$x^2$]))
  assert.eq(rigid.len(), 2)
  assert(text-layout.is-text-cluster(text-layout.tokenize([*a*]).first()))
  assert(not text-layout.is-text-cluster(rigid.first()))
}

// Layout uses alignment with no trailing gap.
#{
  assert.eq(text-layout.layout-distances((2, 2), (2, 2), 10, align: center), (4, 6))
  assert.eq(text-layout.layout-distances((2, 2), (2, 2), 10, spacing: "fit"), (1, 9))
  assert.eq(text-layout.layout-distances((2, 2), (2, 2), 10, spacing: "equidistant"), (2.5, 7.5))
  assert.eq(text-layout.layout-distances(
    (2, 2, 2), (2, 2, 2), 10,
    spacing: "fit-spaces", spaces: (false, true, false),
  ), (1, 3, 9))
  let padded = text-layout.apply-corners(
    (1, 2, 3), (1, 1, 1), ((s: 2, angle: 90deg, side: 1),), 4,
  )
  assert.eq(padded, (1, 2.5, 3.5))
  // Crowded joins clear both sides. Miter grows with raise.
  let crowded = text-layout.apply-corners(
    (1, 1.75, 2, 2.25, 3), (.4, .4, .4, .4, .4),
    ((s: 2, angle: 90deg, side: 1),), 4, raise: .5,
  )
  assert(crowded.all(mid => calc.abs(mid - 2) >= .7 - 1e-9))
  let crowded-gaps = crowded.windows(2).map(pair => pair.at(1) - pair.first())
  assert.eq((crowded-gaps.at(0), crowded-gaps.at(1), crowded-gaps.at(3)), (.75, .25, .75))
  assert(crowded-gaps.at(2) >= 1.4 - 1e-9)
  let outer = text-layout.apply-corners(
    (1.75, 2.25), (.4, .4), ((s: 2, angle: 90deg, side: 1),), 4, raise: -.5,
  )
  assert.eq(outer, (1.75, 2.25))
  assert.eq(text-layout.apply-overflow((.5, 1.5, 2.5), (2, 2, 2), 3),
    (none, 1.5, none))
  assert.eq(text-layout.apply-overflow(
    (.5, 1.5, 2.5), (2, 2, 2), 3, policy: "clamp",
  ), (1, 1.5, 2))
  // Outside joins do not constrain layout.
  assert.eq(text-layout.apply-corners(
    (1, 2, 3), (1, 1, 1),
    ((s: -2, angle: 90deg, side: 1), (s: 8, angle: 90deg, side: 1)),
    4, raise: .5,
  ), (1, 2, 3))
  // Backward shifts move to the next run. Order never reverses.
  let ordered = text-layout.apply-corners(
    (.1, .3, .5, .7, .9, 1.1, 1.3, 1.5, 1.7), (.2,) * 9,
    ((s: 1.5, angle: 90deg, side: 1), (s: 3, angle: 90deg, side: -1)),
    4, raise: .2, above: (.25,) * 9, below: (0,) * 9,
  )
  assert(ordered.windows(2).all(pair => pair.at(1) - pair.first() >= .2 - 1e-9))
  assert(ordered.at(5) > 1.5)
}

// Named path, styled wrappers, and centered alignment.
#test-case({
  import draw: *
  bezier((0, 0), (4, 0), (1, 1.2), (3, -1.2), name: "curve",
    stroke: gray, mark: (end: ">"))
  decorations.text-along("curve", text(9pt)[*Styled* path],
    name: "label", raise: .16, align: center)
  circle("label.center", radius: .03, fill: red, stroke: none)
})

// Inline target and explicit chunks, including non-text content.
#test-case({
  import draw: *
  decorations.text-along(
    line((0, 0), (4, 1), mark: (end: ">")),
    ([one], [ ], [$x^2$], [ ], [path]),
    raise: .18,
  )
})

// Auto-upright text around a closed path, traversed in reverse.
#test-case({
  import draw: *
  circle((0, 0), radius: 1.25, name: "ring", stroke: gray)
  decorations.text-along("ring", [REVERSED AROUND], reverse: true,
    raise: .16, align: center, upright: auto)
})

// Whitespace fitting uses its real styled width and expands only spaces.
#test-case({
  import draw: *
  line((0, 0), (5, 0), name: "line", stroke: gray)
  decorations.text-along("line", text(10pt)[fit these words],
    spacing: "fit-spaces", raise: .18)
})

// Signed raise selects either side of the direction of travel.
#test-case({
  import draw: *
  line((0, 0), (4, 0), name: "line", stroke: gray)
  decorations.text-along("line", [positive], raise: .25, align: center)
  decorations.text-along("line", [negative], raise: -.25, align: center)
})

// Corner runs are solved together and remain clear on both sides of each join.
#test-case({
  import draw: *
  line((0, 0), (2, 0), (2, 1.5), (4, 1.5), name: "corner", stroke: gray)
  decorations.text-along("corner", [corner safe],
    start: 5%, stop: 95%, raise: .2, corners: "pad")
})
