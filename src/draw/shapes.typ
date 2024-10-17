#let typst-angle = angle
#let typst-rotate = rotate

#import "/src/coordinate.typ"
#import "/src/drawable.typ"
#import "/src/styles.typ"
#import "/src/path-util.typ"
#import "/src/util.typ"
#import "/src/vector.typ"
#import "/src/matrix.typ"
#import "/src/process.typ"
#import "/src/bezier.typ" as bezier_
#import "/src/hobby.typ" as hobby_
#import "/src/anchor.typ" as anchor_
#import "/src/mark.typ" as mark_
#import "/src/mark-shapes.typ" as mark-shapes_
#import "/src/polygon.typ"
#import "/src/aabb.typ"

#import "transformations.typ": *
#import "styling.typ": *
#import "grouping.typ": *

/// Draws a circle or ellipse.
///
/// ```typc example
/// circle((0,0))
/// // Draws an ellipse
/// circle((0,-2), radius: (0.75, 0.5))
/// ```
///
/// - position (coordinate): The position to place the circle on.
/// - name (none,str):
/// - anchor (none, str):
/// - ..style (style):
///
/// ### Styling
/// *Root*: `circle`
///
/// - radius (number, array) = 1: A number that defines the size of the circle's radius. Can also be set to a tuple of two numbers to define the radii of an ellipse, the first number is the `x` radius and the second is the `y` radius.
///
/// ### Anchors
///   Supports border and path anchors. The `"center"` anchor is the default.
///
#let circle(position, name: none, anchor: none, ..style) = {
  // No extra positional arguments from the style sink
  assert.eq(
    style.pos(),
    (),
    message: "Unexpected positional arguments: " + repr(style.pos()),
  )
  let style = style.named()

  (ctx => {
    let (ctx, pos) = coordinate.resolve(ctx, position)
    let style = styles.resolve(ctx.style, merge: style, root: "circle")
    let (rx, ry) = util.resolve-radius(style.radius).map(util.resolve-number.with(ctx))
    let (cx, cy, cz) = pos

    let drawables = drawable.ellipse(
      cx, cy, cz,
      rx, ry,
      fill: style.fill,
      stroke: style.stroke
    )

    let (transform, anchors) = anchor_.setup(
      (_) => pos,
      ("center",),
      default: "center",
      name: name,
      offset-anchor: anchor,
      transform: ctx.transform,
      border-anchors: true,
      path-anchors: true,
      radii: (rx*2, ry*2),
      path: drawables,
    )

    return (
      ctx: ctx,
      name: name,
      anchors: anchors,
      drawables: drawable.apply-transform(transform, drawables),
    )
  },)
}

/// Draws a circle through three coordinates.
///
/// ```typc example
/// let (a, b, c) = ((0,0), (2,-.5), (1,1))
/// line(a, b, c, close: true, stroke: gray)
/// circle-through(a, b, c, name: "c")
/// circle("c.center", radius: .05, fill: red)
/// ```
///
/// - a (coordinate): Coordinate a.
/// - b (coordinate): Coordinate b.
/// - c (coordinate): Coordinate c.
/// - name (none,str):
/// - anchor (none,str):
/// - ..style (style):
///
/// ### Styling
/// *Root*: `circle`
///
///   `circle-through` has the same styling as [circle](./circle#styling) except for `radius` as the circle's radius is calculated by the given coordinates.
///
/// ### Anchors
/// Supports the same anchors as [circle](./circle#anchors) as well as:
/// - **a**: Coordinate a
/// - **b**: Coordinate b
/// - **c**: Coordinate c
#let circle-through(a, b, c, name: none, anchor: none, ..style) = {
  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  style = style.named()

  (a, b, c).map(coordinate.resolve-system)

  return (ctx => {
    let (ctx, a, b, c) = coordinate.resolve(ctx, a, b, c)

    let center = util.calculate-circle-center-3pt(a, b, c)

    let style = styles.resolve(ctx.style, merge: style, root: "circle")
    let (cx, cy, cz) = center
    let r = vector.dist(a, (cx, cy))

    let drawables = drawable.ellipse(
      cx, cy, 0,
      r, r,
      fill: style.fill,
      stroke: style.stroke
    )

    let (transform, anchors) = anchor_.setup(
      (anchor) => (
        center: center,
        a: a,
        b: b,
        c: c
      ).at(anchor),
      ("center", "a", "b", "c"),
      default: "center",
      name: name,
      offset-anchor: anchor,
      transform: ctx.transform,
      border-anchors: true,
      path-anchors: true,
      radii: (r*2, r*2),
      path: drawables,
    )

    return (
      ctx: ctx,
      name: name,
      anchors: anchors,
      drawables: drawable.apply-transform(
        transform,
        drawables
      )
    )
  },)
}

/// Draws a circular segment.
///
/// ```typc example
/// arc((0,0), start: 45deg, stop: 135deg)
/// arc((0,-0.5), start: 45deg, delta: 90deg, mode: "CLOSE")
/// arc((0,-1), stop: 135deg, delta: 90deg, mode: "PIE")
/// ```
///
/// Note that two of the three angle arguments (`start`, `stop` and `delta`) must be set.
/// The current position `()` gets updated to the arc's end coordinate (anchor `arc-end`).
///
/// - position (coordinate): Position to place the arc at.
/// - start (auto,angle): The angle at which the arc should start. Remember that `0deg` points directly towards the right and `90deg` points up.
/// - stop (auto,angle): The angle at which the arc should stop.
/// - delta (auto,angle): The change in angle away start or stop.
/// - name (none,str):
/// - anchor (none, str):
/// - ..style (style):
///
/// ## Styling
/// *Root*: `arc`\
/// - radius (number, array) = 1: The radius of the arc. An elliptical arc can be created by passing a tuple of numbers where the first element is the x radius and the second element is the y radius.
/// - mode (str) = "OPEN": The options are: `"OPEN"` no additional lines are drawn so just the arc is shown; `"CLOSE"` a line is drawn from the start to the end of the arc creating a circular segment; `"PIE"` lines are drawn from the start and end of the arc to the origin creating a circular sector.
/// - update-position (bool) = true: Update the current canvas position to the arc's end point (anchor `"arc-end"`). This overrides the default of `true`, that allows chaining of (arc) elements.
///
/// ## Anchors
/// Supports border and path anchors.
/// - **arc-start**: The position at which the arc's curve starts, this is the default.
/// - **arc-end**: The position of the arc's curve end.
/// - **arc-center**: The midpoint of the arc's curve.
/// - **center**: The center of the arc, this position changes depending on if the arc is closed or not.
/// - **chord-center**: Center of chord of the arc drawn between the start and end point.
/// - **origin**: The origin of the arc's circle.
#let arc(
  position,
  start: auto,
  stop: auto,
  delta: auto,
  name: none,
  anchor: none,
  ..style,
) = {
  // Start, stop, delta check
  assert(
    (start, stop, delta).filter(it => { it == auto }).len() == 1,
    message: "Exactly two of three options start, stop and delta should be defined.",
  )

  // No extra positional arguments from the style sink
  assert.eq(
    style.pos(),
    (),
    message: "Unexpected positional arguments: " + repr(style.pos()),
  )
  let style = style.named()

  // Coordinate check
  let t = coordinate.resolve-system(position)

  let start-angle = if start == auto { stop - delta } else { start }
  let stop-angle = if stop == auto { start + delta } else { stop }
  // Border angles can break if the angle is 0.
  assert.ne(start-angle, stop-angle, message: "Angle must be greater than 0deg")

  return (ctx => {
    let style = styles.resolve(ctx.style, merge: style, root: "arc")
    assert(style.mode in ("OPEN", "PIE", "CLOSE"))

    let (ctx, arc-start) = coordinate.resolve(ctx, position)
    let (rx, ry) = util.resolve-radius(style.radius).map(util.resolve-number.with(ctx))

    let (x, y, z) = arc-start
    let drawables = drawable.arc(
      ..arc-start,
      start-angle,
      stop-angle,
      rx,
      ry,
      stroke: style.stroke,
      fill: style.fill,
      mode: style.mode
    )

    let sector-center = (
      x - rx * calc.cos(start-angle),
      y - ry * calc.sin(start-angle),
      z
    )
    let arc-end = (
      sector-center.first() + rx * calc.cos(stop-angle),
      sector-center.at(1) + ry * calc.sin(stop-angle),
      z
    )
    let chord-center = vector.lerp(arc-start, arc-end, 0.5)
    let arc-center = (
      sector-center.first() + rx * calc.cos((stop-angle + start-angle)/2),
      sector-center.at(1) + ry * calc.sin((stop-angle + start-angle)/2),
      z
    )

    // Set the last position to arc-end
    if style.update-position {
      ctx.prev.pt = arc-end
    }

    // Center is calculated based on observations of tikz's circular sector and semi circle shapes.
    let center = if style.mode != "CLOSE" {
      // A circular sector's center anchor is placed half way between the sector-center and arc-center when the angle is 180deg. At 60deg it is placed 1/3 of the way between, this is mirrored at 300deg.
      vector.lerp(
        arc-center,
        sector-center,
        if (stop-angle + start-angle) > 180deg { (stop-angle + start-angle) } else { (stop-angle + start-angle) + 180deg } / 720deg
      )
    } else {
      // A semi circle's center anchor is placed half way between the sector-center and arc-center, so that is always `center` when the arc is closed. Otherwise the point at which compass anchors are calculated from will be outside the lines.
      vector.lerp(
        arc-center,
        chord-center,
        0.5
      )
    }

    let (transform, anchors) = anchor_.setup(
      anchor => (
        arc-start: arc-start,
        origin: sector-center,
        arc-end: arc-end,
        arc-center: arc-center,
        chord-center: chord-center,
        center: center,
      ).at(anchor),
      ("arc-center", "chord-center", "origin", "arc-start", "arc-end", "center"),
      default: "arc-start",
      name: name,
      offset-anchor: anchor,
      transform: ctx.transform,
      border-anchors: true,
      path-anchors: true,
      radii: (rx, ry), // Don't multiply as its not from the arc's center
      path: drawables
    )

    if mark_.check-mark(style.mark) {
      drawables = mark_.place-marks-along-path(ctx, style.mark, transform, drawables)
    } else {
      drawables = drawable.apply-transform(transform, drawables)
    }

    return (
      ctx: ctx,
      name: name,
      anchors: anchors,
      drawables: drawables,
    )
  },)
}

/// Draws an arc that passes through three points a, b and c.
///
/// Note that all three points must not lie on a straight line, otherwise
/// the function fails.
///
/// ```typc example
/// arc-through((0,1), (1,1), (1,0))
/// ```
///
/// - a (coordinate): Start position of the arc
/// - b (coordinate): Position the arc passes through
/// - c (coordinate): End position of the arc
/// - name (none, str):
/// - ..style (style):
///
/// ### Styling
/// *Root*: `arc`
///
/// Uses the same styling as [arc](./arc#styling)
///
/// ### Anchors
///   For anchors see [arc](./arc#anchors).
///
#let arc-through(
  a,
  b,
  c,
  name: none,
  ..style,
) = get-ctx(ctx => {
  let (ctx, a, b, c) = coordinate.resolve(ctx, a, b, c)
  assert(a.at(2) == b.at(2) and b.at(2) == c.at(2),
    message: "The z coordinate of all points must be equal, but is: " + repr((a, b, c).map(v => v.at(2))))

  // Calculate the circle center from three points or fails if all
  // three points are on one straight line.
  let center = util.calculate-circle-center-3pt(a, b, c)
  let radius = vector.dist(center, a)

  // Find the start and inner angle between a-center-c
  let start = vector.angle2(center, a)
  let delta = vector.angle(a, center, c)

  // Returns a negative number if pt is left of the line a-b,
  // if pt is right to a-b, a positive number is returned,
  // otherwise zero.
  let side-on-line(a, b, pt) = {
    let (x1, y1, ..) = a
    let (x2, y2, ..) = b
    let (x,  y, ..)  = pt
    return (x - x1) * (y2 - y1) - (y - y1) * (x2 - x1)
  }

  // Center & b     b is left,
  //  are left      center not
  //
  //    +-b-+          +-b-+
  //   /     \        /     \
  //  |   C   |    --a-------c--
  //   \     /        \  C  /
  // ---a---c---       +---+
  //
  // If b and C are on the same side of a-c, the arcs radius is >= 180deg,
  // otherwise the radius is < 180deg.
  let center-is-left = side-on-line(a, c, center) < 0
  let b-is-left = side-on-line(a, c, b) < 0

  // If the center and point b are on the same side of a-c,
  // the arcs delta must be > 180deg. Note, that delta is
  // the inner angle between a-center-c, so we need to calculate
  // the outer angle by subtracting from 360deg.
  if center-is-left == b-is-left {
    delta = 360deg - delta
  }

  // If b is left of a-c, swap a-c to c-a by using a negative delta
  if b-is-left {
    delta *= -1
  }

  return arc(
    a,
    start: start,
    delta: delta,
    radius: radius,
    anchor: "arc-start",
    name: name,
    ..style
  )
})

/// Draws a single mark pointing towards a target coordinate.
///
/// ```typc example
/// mark((0,0), (1,0), symbol: ">", fill: black)
/// mark((0,0), (1,1), symbol: "stealth", scale: 3, fill: black)
/// ```
///
/// Note: To place a mark centered at the first coodinate (`from`) use
/// the marks `anchor: "center"` style.
///
/// - from (coordinate): The position to place the mark.
/// - to (coordinate,angle): The position or angle the mark should point towards.
/// - ..style (style):
///
/// ## Styling
/// *Root*: `mark`
///
/// You can directly use the styling from [Mark Styling](/docs/basics/marks).
#let mark(from, to, ..style) = {
  assert.eq(
    style.pos(),
    (),
    message: "Unexpected positional arguments: " + repr(style.pos()),
  )

  let style = style.named()

  if type(to) == angle {
    // Construct a coordinate pointing (+1, 0) away from
    // `from`, rotated by the angle given.
    to = ((rel: (to, 1), to: from))
  }

  (from, to).map(coordinate.resolve-system)

  return (ctx => {
    let (ctx, ..pts) = coordinate.resolve(ctx, from, to)
    let style = styles.resolve(ctx.style, merge: style, root: "mark")

    if style.end == none {
      style.end = style.symbol
    }
    style.start = none
    style.symbol = none

    let (to, from) = (..pts)
    from = vector.sub(to, vector.sub(from, to))

    let drawables = drawable.path((path-util.line-segment((from, to)),))
    drawables = mark_.place-marks-along-path(ctx, style, none, drawables, add-path: false)
    return (
      ctx: ctx,
      drawables: drawable.apply-transform(ctx.transform, drawables)
    )
  },)
}

/// Draws a line, more than two points can be given to create a line-strip.
///
/// ```typc example
/// line((-1.5, 0), (1.5, 0))
/// line((0, -1.5), (0, 1.5))
/// line((-1, -1), (-0.5, 0.5), (0.5, 0.5), (1, -1), close: true)
/// ```
///
/// If the first or last coordinates are given as the name of an element,
/// that has a `"default"` anchor, the intersection of that element's border
/// and a line from the first or last two coordinates given is used as coordinate.
/// This is useful to span a line between the borders of two elements.
///
/// ```typc example
/// circle((1,2), radius: .5, name: "a")
/// rect((2,1), (rel: (1,1)), name: "b")
/// line("a", "b")
/// ```
/// - ..pts-style (coordinate,style): Positional two or more coordinates to draw lines between. Accepts style key-value pairs.
/// - close (bool): If true, the line-strip gets closed to form a polygon
/// - name (none,str):
///
/// ## Styling
/// *Root:* `line`
///
/// Supports mark styling.
///
/// ## Anchors
///   Supports path anchors.
///   - **centroid**: The centroid anchor is calculated for _closed non self-intersecting_ polygons if all vertices share the same z value.
#let line(..pts-style, close: false, name: none) = {
  // Extra positional arguments from the pts-style sink are interpreted as coordinates.
  let pts = pts-style.pos()
  let style = pts-style.named()

  assert(pts.len() >= 2, message: "Line must have a minimum of two points")

  // Coordinate check
  let pts-system = pts.map(coordinate.resolve-system)

  // Find the intersection between line a-b next to b
  // if no intersection could be found, return a.
  let element-line-intersection(ctx, elem, a, b) = {
    // Vectors a and b are not transformed yet, but the vectors of the
    // drawable are.
    let (ta, tb) = util.apply-transform(ctx.transform, a, b)

    let pts = ()
    for drawable in elem.at("drawables", default: ()).filter(d => d.type == "path") {
      pts += intersection.line-path(ta, tb, drawable)
    }
    return if pts == () {
      a
    } else {
      // Find the nearest point
      let pt = util.sort-points-by-distance(tb, pts).first()

      // Reverse the transformation
      return util.revert-transform(ctx.transform, pt)
    }
  }

  return (ctx => {
    let first-elem = pts.first()
    let last-elem = pts.last()
    let (ctx, ..pts) = coordinate.resolve(ctx, ..pts)

    // If the first/last element, test for intersection
    // of that element and a line from the two first/last coordinates of this
    // line strip.
    if pts-system.first() == "element" {
      let elem = ctx.nodes.at(first-elem)
      pts.first() = element-line-intersection(ctx, elem, ..pts.slice(0, 2))
    }
    if pts-system.last() == "element" {
      let elem = ctx.nodes.at(last-elem)
      pts.last() = element-line-intersection(ctx, elem, ..pts.slice(-2).rev())
    }

    let style = styles.resolve(ctx.style, merge: style, root: "line")

    let drawables = drawable.path(
      (path-util.line-segment(pts),),
      fill: style.fill,
      fill-rule: style.fill-rule,
      stroke: style.stroke,
      close: close
    )

    // Get bounds
    let (transform, anchors) = anchor_.setup(
      name => {
        if name == "centroid" {
          return polygon.simple-centroid(pts)
        }
      },
      if close != none { ("centroid",) } else { () },
      name: name,
      transform: ctx.transform,
      path-anchors: true,
      path: drawables
    )

    // Place marks and adjust segments
    if mark_.check-mark(style.mark) {
      drawables = mark_.place-marks-along-path(ctx, style.mark, transform, drawables)
    } else {
      drawables = drawable.apply-transform(transform, drawables)
    }

    return (
      ctx: ctx,
      name: name,
      anchors: anchors,
      drawables: drawables,
    )
  },)
}

/// Draws a grid between two coordinates
///
/// ```typc example
/// // Draw a grid
/// grid((0,0), (2,2))
///
/// // Draw a smaller blue grid
/// grid((1,1), (2,2), stroke: blue, step: .25)
/// ```
///
/// - from (coordinate): The top left of the grid
/// - to (coordinate): The bottom right of the grid
/// - name (none,str):
/// - ..style (style):
///
/// ## Styling
/// *Root*: `grid`
/// - step (number, array, dictionary) = 1: Distance between grid lines. A distance of $1$ means to draw a grid line every $1$ length units in x- and y-direction. If given a dictionary with `x` and `y` keys or a tuple, the step is set per axis.
/// - help-lines (bool) = false: If true, force the stroke style to `gray + 0.2pt`
///
/// ## Anchors
///   Supports border anchors.
#let grid(from, to, name: none, ..style) = {
  (from, to).map(coordinate.resolve-system)

  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  style = style.named()

  return (ctx => {
    let (ctx, from, to) = coordinate.resolve(ctx, from, to)

    (from, to) = {
      let pairs = ((from.at(0), to.at(0)), (from.at(1), to.at(1)), (from.at(2), from.at(2)))
      (
        pairs.map(e => calc.min(..e)),
        pairs.map(e => calc.max(..e))
      )
    }

    let style = styles.resolve(ctx.style, merge: style, root: "grid", base: (
      step: 1,
      stroke: auto,
      help-lines: false,
    ))
    if style.help-lines {
      style.stroke = 0.2pt + gray
    }

    let (x-step, y-step) = if type(style.step) == dictionary {
      (style.step.at("x", default: 1), style.step.at("y", default: 1))
    } else if type(style.step) == array {
      style.step
    } else {
      (style.step, style.step)
    }.map(util.resolve-number.with(ctx))

    let drawables = {
      if x-step != 0 {
        range(int((to.at(0) - from.at(0)) / x-step)+1).map(x => {
          x *= x-step
          x += from.at(0)
          drawable.path(
            path-util.line-segment(((x, from.at(1)), (x, to.at(1)))),
            stroke: style.stroke
          )
        })
      } else {
        ()
      }
      if y-step != 0 {
        range(int((to.at(1) - from.at(1)) / y-step)+1).map(y => {
          y *= y-step
          y += from.at(1)
          drawable.path(
            path-util.line-segment(((from.at(0), y), (to.at(0), y))),
            stroke: style.stroke
          )
        })
      } else {
        ()
      }
    }

    let center = vector.lerp(from, to, .5)
    let (transform, anchors) = anchor_.setup(
      _ => center,
      ("center",),
      name: name,
      transform: ctx.transform,
      border-anchors: true,
      radii: (vector.dist(center, from) * 2,) * 2,
      path: drawable.path(
        path-util.line-segment((
          from,
          (from.first(), to.at(1), 0),
          to,
          (to.first(), from.at(1), 0)
        )),
        close: true
      )
    )

    return (
      ctx: ctx,
      name: name,
      anchors: anchors,
      drawables: drawable.apply-transform(
        transform,
        drawables
      )
    )
  },)
}

/// Positions Typst content in the canvas. Note that the content itself is not transformed only its position is.
///
/// ```typc example
/// content((0,0), [Hello World!])
/// ```
/// To put text on a line you can let the function calculate the angle between its position and a second coordinate by passing it to `angle`:
///
/// ```typc example
/// line((0, 0), (3, 1), name: "line")
/// content(
///   ("line.start", 50%, "line.end"),
///   angle: "line.end",
///   padding: .1,
///   anchor: "south",
///   [Text on a line]
/// )
/// ```
///
/// ```typc example
/// // Place content in a rect between two coordinates
/// content(
///   (0, 0),
///   (2, 2),
///   box(
///     par(justify: false)[This is a long text.],
///     stroke: 1pt,
///     width: 100%,
///     height: 100%,
///     inset: 1em
///   )
/// )
/// ```
/// 
/// - ..args-style (coordinate, content, style): When one coordinate is given as a positional argument, the content will be placed at that position. When two coordinates are given as positional arguments, the content will be placed inside a rectangle between the two positions. All named arguments are styling and any additional positional arguments will panic.
/// - angle (angle,coordinate): Rotates the content by the given angle. A coordinate can be given to rotate the content by the angle between it and the first coordinate given in `args`. This effectively points the right hand side of the content towards the coordinate. This currently exists because Typst's rotate function does not change the width and height of content.
/// - anchor (none, str):
/// - name (none, str):
///
/// ## Styling
/// *Root*: `content`
/// - padding (number, dictionary) = 0: Sets the spacing around content. Can be a single number to set padding on all sides or a dictionary to specify each side specifically. The dictionary follows Typst's `pad` function: https://typst.app/docs/reference/layout/pad/
/// - frame (str, none) = none: Sets the frame style. Can be {{none}}, `"rect"` or `"circle"` and inherits the `stroke` and `fill` style.
///
/// ## Anchors
/// Supports border anchors, the default anchor is set to **center**.
/// - **mid**: Content center, from baseline to top bounds
/// - **mid-east**: Content center extended to the east
/// - **mid-west**: Content center extended to the west
/// - **base**: Horizontally centered baseline of the content
/// - **base-east**: Baseline height extended to the east
/// - **base-west**: Baseline height extended to the west
/// - **text**: Position at the content start on the baseline of the content
#let content(
    ..args-style,
    angle: 0deg,
    anchor: none,
    name: none,
  ) = {
  let (args, style) = (args-style.pos(), args-style.named())

  let (a, b, body) = if args.len() == 2 {
    args.insert(1, auto)
    args
  } else if args.len() == 3 {
    args
  } else {
    panic("Expected 2 or 3 positional arguments, got " + str(args.len()))
  }

  coordinate.resolve-system(a)

  if b != auto {
    coordinate.resolve-system(b)
  }

  if type(angle) != typst-angle {
    coordinate.resolve-system(angle)
  }

  return (ctx => {
    let style = styles.resolve(ctx.style, merge: style, root: "content")
    let padding = util.as-padding-dict(style.padding)
    for (k, v) in padding {
      padding.insert(k, util.resolve-number(ctx, v))
    }

    let (ctx, a) = coordinate.resolve(ctx, a)
    let b = b
    let auto-size = b == auto
    if not auto-size {
      (ctx, b) = coordinate.resolve(ctx, b)
    }

    let angle = if type(angle) != typst-angle {
      let c
      (ctx, c) = coordinate.resolve(ctx, angle)
      vector.angle2(a, c)
    } else {
      angle
    }

    // Typst's `rotate` function is clockwise relative to x-axis, which is backwards from us
    angle = angle * -1

    // Height from the baseline to content-north
    let (content-width, baseline-height) = util.measure(ctx, text(top-edge: "cap-height", bottom-edge: "baseline", body))

    // Size of the bounding box
    let (width, height, ..) = if auto-size {
      util.measure(ctx, text(top-edge: "cap-height", bottom-edge: "bounds", body))
    } else {
      vector.sub(b, a)
    }

    let bounds-width = calc.abs(width)
    let bounds-height = calc.abs(height)
    baseline-height = bounds-height - baseline-height

    width = bounds-width + padding.left + padding.right
    height = bounds-height + padding.top + padding.bottom

    let anchors = {
      let w = width / 2
      let h = height / 2
      let bh = (baseline-height - padding.top - padding.bottom) / 2

      let bounds-center = if auto-size {
        a
      } else {
        vector.lerp(a, b, .5)
      }

      // Only the center anchor gets transformed. All other anchors
      // must be calculated relative to the transformed center!
      bounds-center = matrix.mul4x4-vec3(ctx.transform,
        vector.as-vec(bounds-center, init: (0,0,0)))

      let east-dir = vector.rotate-z((1, 0, 0), angle)
      let north-dir = vector.rotate-z((-1, 0, 0), angle + 90deg)
      let east-scaled = vector.scale(east-dir, +w)
      let west-scaled = vector.scale(east-dir, -w)
      let north-scaled = vector.scale(north-dir, +h)
      let south-scaled = vector.scale(north-dir, -h)

      let north = vector.add(bounds-center, north-scaled)
      let south = vector.add(bounds-center, south-scaled)
      let east = vector.add(bounds-center, east-scaled)
      let west = vector.add(bounds-center, west-scaled)
      let north-east = vector.add(bounds-center, vector.add(north-scaled, east-scaled))
      let north-west = vector.sub(bounds-center, vector.add(south-scaled, east-scaled))
      let south-east = vector.add(bounds-center, vector.add(south-scaled, east-scaled))
      let south-west = vector.sub(bounds-center, vector.add(north-scaled, east-scaled))

      let base = vector.add(south,
        vector.scale(north-dir, padding.bottom + baseline-height))
      let mid = vector.lerp(
        vector.sub(north, vector.scale(north-dir, padding.top)),
        base,
        0.5)
      let base-east = vector.add(base, east-scaled)
      let base-west = vector.add(base, west-scaled)
      let text = vector.add(base, vector.scale(east-dir, -content-width / 2))
      let mid-east = vector.add(mid, east-scaled)
      let mid-west = vector.add(mid, west-scaled)

      (
        center: bounds-center,
        mid: mid,
        mid-east: mid-east,
        mid-west: mid-west,
        base: base,
        base-east: base-east,
        base-west: base-west,
        text: text,
        north: north,
        north-east: north-east,
        north-west: north-west,
        south: south,
        south-east: south-east,
        south-west: south-west,
        east: east,
        west: west,
      )
    }

    let border = if style.frame in (none, "rect") {
      drawable.path(
        path-util.line-segment((
          anchors.north-west,
          anchors.north-east,
          anchors.south-east,
          anchors.south-west
        )),
        close: true,
        stroke: style.stroke,
        fill: style.fill)
    } else if style.frame == "circle" {
      let (x, y, z) = util.calculate-circle-center-3pt(anchors.north-west, anchors.south-west, anchors.south-east)
      let r = vector.dist((x, y, z), anchors.north-west)
      drawable.ellipse(
        x, y, z,
        r, r,
        stroke: style.stroke,
        fill: style.fill
      )
    }

    let (aabb-width, aabb-height, ..) = aabb.size(aabb.aabb(
      (anchors.north-west, anchors.north-east,
       anchors.south-west, anchors.south-east)))

    let drawables = ()
    if style.frame != none {
      drawables.push(border)
    }

    // Because of precision problems with some fonts (e.g. "Source Sans 3")
    // we need to round the block sizes up. Otherwise, unwanted hyphenation
    // gets introduced.
    let round-up(v, digits: 8) = {
      calc.ceil(v * calc.pow(10, digits)) / calc.pow(10, digits)
    }

    drawables.push(
      drawable.content(
        anchors.center,
        aabb-width,
        aabb-height,
        border.segments,
        typst-rotate(angle,
          reflow: true,
          origin: center + horizon,
          block(
            width: round-up(width) * ctx.length,
            height: round-up(height) * ctx.length,
            inset: (
              top: padding.at("top", default: 0) * ctx.length,
              left: padding.at("left", default: 0) * ctx.length,
              bottom: padding.at("bottom", default: 0) * ctx.length,
              right: padding.at("right", default: 0) * ctx.length,
            ),
            text(top-edge: "cap-height", bottom-edge: "baseline", body)
          )
        )
      )
    )

    let (transform, anchors) = anchor_.setup(
      anchor => {
        if type(anchor) == str {
          anchors.at(anchor)
        }
      },
      anchors.keys(),
      default: if auto-size { "center" } else { "north-west" },
      offset-anchor: anchor,
      transform: none, // Content does not get transformed, see the calculation of anchors.
      name: name,
    )

    return (
      ctx: ctx,
      name: name,
      anchors: anchors,
      drawables: drawable.apply-transform(
        transform,
        drawables
      )
    )
  },)
}

/// Draws a rectangle between two coordinates.
/// ```typc example
/// rect((0,0), (1,1))
/// rect(
///   (-.5, -.5),
///   (rel: (2, 2)),
///   radius: (
///     north-east: (100%, .5),
///     south-west: (100%, .5),
///     rest: .2
///   ),
///   stroke: red
/// )
/// rect((-1, -1), (rel: (3, 3)), radius: .5, stroke: blue)
/// ```
///
/// - a (coordinate): Coordinate of the bottom left corner of the rectangle.
/// - b (coordinate): Coordinate of the top right corner of the rectangle. You can draw a rectangle with a specified width and height by using relative coordinates for this parameter `(rel: (width, height))`.
/// - name (none,str):
/// - anchor (none, str):
/// - ..style (style):
///
/// ## Styling
/// *Root*: `rect`
/// <Parameter name="radius" types="number,ratio,dictionary" default_value="0">
/// The rectangle's corner radius. If set to a single number, that radius is applied to all four corners of the rectangle. If passed a dictionary you can set the radii per corner. The following keys support either a <Type>number</Type>, <Type>ratio</Type> or an array of <Type>number</Type> or <Type>ratio</Type> for specifying a different x- and y-radius: `north`, `east`, `south`, `west`, `north-west`, `north-east`, `south-west` and `south-east`. To set a default value for remaining corners, the `rest` key can be used.
///
/// Ratio values are relative to the rectangle's width and height.
///
/// ```typc example vertical
/// rect((0,0), (rel: (1,1)), radius: 0)
/// rect((2,0), (rel: (1,1)), radius: 25%)
/// rect((4,0), (rel: (1,1)), radius: (north: 50%))
/// rect((6,0), (rel: (1,1)), radius: (north-east: 50%))
/// rect((8,0), (rel: (1,1)), radius: (south-west: 0, rest: 50%))
/// rect((10,0), (rel: (1,1)), radius: (rest: (20%, 50%)))
/// ```
/// </Parameter>
///
/// ## Anchors
///   Supports border and path anchors. It's default is the `"center"` anchor.
///
#let rect(a, b, name: none, anchor: none, ..style) = {
  // Coordinate check
  let t = (a, b).map(coordinate.resolve-system)

  // No extra positional arguments from the style sink
  assert.eq(
    style.pos(),
    (),
    message: "Unexpected positional arguments: " + repr(style.pos()),
  )
  let style = style.named()

  return (
    ctx => {
      let ctx = ctx
      let (ctx, a, b) = coordinate.resolve(ctx, a, b)
      assert(a.at(2) == b.at(2),
        message: "Both rectangle points must have the same z value.")
      (a, b) = {
        let lo = (
          calc.min(a.at(0), b.at(0)),
          calc.min(a.at(1), b.at(1)),
          calc.min(a.at(2), b.at(2)),
        )
        let hi = (
          calc.max(a.at(0), b.at(0)),
          calc.max(a.at(1), b.at(1)),
          calc.max(a.at(2), b.at(2)),
        )
        (lo, hi)
      }

      let style = styles.resolve(ctx.style, merge: style, root: "rect")
      let (x1, y1, z1) = a
      let (x2, y2, z2) = b

      let size = (calc.abs(x2 - x1), calc.abs(y2 - y1))
      let (north-west: nw, north-east: ne,
           south-west: sw, south-east: se) = util.as-corner-radius-dict(ctx, style.radius, size)

      let drawables = {
        let z = z1

        // Compute two corner points offset by radius from origin pt.
        //
        //   x radius * a
        //    |----|
        // --p1←--pt  ---
        //         |   | y radius * b
        //         ↓   |
        //         p2 ---
        //         |
        //
        // parameters a and b function as direction vectors in which
        // direction the resulting points p1 and p2 should get offset to.
        //
        // The point pt is the corner point of the non-rounded rectangle.
        // If the radius is zero, we can just return that point for both
        // new corners.
        let get-corner-pts(radius, pt, a, b) = {
          let (rx, ry) = radius
          if rx > 0 or ry > 0 {
            let (xa, ya) = a
            let (xb, yb) = b
            (vector.add(pt, (xa * rx, ya * ry)),
             vector.add(pt, (xb * rx, yb * ry)))
          } else {
            (pt, pt)
          }
        }

        // Get segments for arc between start- and stop angle, starting
        // at point. If radius is zero for both axes, x and y, nothing
        // gets returned.
        //
        // s----p0/
        //      p1
        //       |
        //       e
        //
        // Returns a cubic bezier curve between s and e
        // with the control points pointing from s in direction
        // p0 * radius and from e in direction p1 * radius.
        // The bezier approximates a 90 degree arc.
        let corner-arc(radius, s, e, p0, p1) = {
          let (rx, ry) = radius
          if rx > 0 or ry > 0 {
            let m = 0.551784
            let p0 = (p0.at(0) * m * rx,
                      p0.at(1) * m * ry)
            let p1 = (p1.at(0) * m * rx,
                      p1.at(1) * m * ry)
            (path-util.cubic-segment(s, e,
              vector.add(s, p0),
              vector.add(e, p1)),)
          }
        }

        // Compute all eight corner points:
        //
        //    p1-------p2
        //   / |       | \
        // p0--+       +--p3
        //  |             |
        // p7--+       +--p4
        //   \ |       | /
        //    p6-------p5
        //
        // If a corner has radius (0,0), both of its
        // corner points are the same. See the comment on get-corner-pts
        // on how the corners get computed.
        let (p0, p1) = get-corner-pts(nw, (x1, y2, z), ( 0,-1), ( 1, 0))
        let (p2, p3) = get-corner-pts(ne, (x2, y2, z), (-1, 0), ( 0,-1))
        let (p4, p5) = get-corner-pts(se, (x2, y1, z), ( 0, 1), (-1, 0))
        let (p6, p7) = get-corner-pts(sw, (x1, y1, z), ( 1, 0), ( 0, 1))

        let segments = ()
        segments += corner-arc(nw, p1, p0, (-1,0), (0, 1))
        if p0 != p7 { segments += (path-util.line-segment((p0, p7)),) }
        segments += corner-arc(sw, p7, p6, (0,-1), (-1,0))
        if p6 != p5 { segments += (path-util.line-segment((p6, p5)),) }
        segments += corner-arc(se, p5, p4, (1, 0), (0,-1))
        if p4 != p3 { segments += (path-util.line-segment((p4, p3)),) }
        segments += corner-arc(ne, p3, p2, (0, 1), (1, 0))
        if p2 != p1 { segments += (path-util.line-segment((p2, p1)),) }

        drawable.path(segments, fill: style.fill, stroke: style.stroke, close: true)
      }

      // Calculate border anchors
      let center = vector.lerp(a, b, .5)
      let (width, height, ..) = size
      let (transform, anchors) = anchor_.setup(
        _ => center,
        ("center",),
        default: "center",
        name: name,
        offset-anchor: anchor,
        transform: ctx.transform,
        border-anchors: true,
        path-anchors: true,
        radii: (width, height),
        path: drawables,
      )

      return (
        ctx: ctx,
        name: name,
        anchors: anchors,
        drawables: drawable.apply-transform(transform, drawables),
      )
    },
  )
}

/// Draws a quadratic or cubic bezier curve
///
/// ```typc example
/// let (a, b, c) = ((0, 0), (2, 0), (1, 1))
/// line(a, c,  b, stroke: gray)
/// bezier(a, b, c)
///
/// let (a, b, c, d) = ((0, -1), (2, -1), (.5, -2), (1.5, 0))
/// line(a, c, d, b, stroke: gray)
/// bezier(a, b, c, d)
/// ```
///
/// - start (coordinate): Start position
/// - end (coordinate): End position (last coordinate)
/// - name (none,str):
/// - ..ctrl-style (coordinate,style): The first two positional arguments are taken as cubic bezier control points, where the first is the start control point and the second is the end control point. One control point can be given for a quadratic bezier curve instead. Named arguments are for styling.
///
/// ## Styling
/// *Root* `bezier`
///
/// Supports marks.
///
/// ## Anchors
/// Supports path anchors.
/// - **ctrl-n**: nth control point where n is an integer starting at 0
///
#let bezier(start, end, ..ctrl-style, name: none) = {
  // Extra positional arguments are treated like control points.
  let (ctrl, style) = (ctrl-style.pos(), ctrl-style.named())

  // Control point check
  let len = ctrl.len()
  assert(
    len in (1, 2),
    message: "Bezier curve expects 1 or 2 control points. Got " + str(len),
  )
  let coordinates = (start, ..ctrl, end)

  // Coordinates check
  let t = coordinates.map(coordinate.resolve-system)

  return (
    ctx => {
      let (ctx, start, ..ctrl, end) = coordinate.resolve(ctx, ..coordinates)

      if ctrl.len() == 1 {
        (start, end, ..ctrl) = bezier_.quadratic-to-cubic(start, end, ..ctrl)
      }

      let style = styles.resolve(ctx.style, merge: style, root: "bezier")
      let drawables = drawable.path(
        (path-util.cubic-segment(start, end, ..ctrl),),
        fill: style.fill,
        fill-rule: style.fill-rule,
        stroke: style.stroke,
      )

      let (transform, anchors) = anchor_.setup(
        anchor => (
          ctrl-0: ctrl.at(0),
          ctrl-1: ctrl.at(1),
        ).at(anchor),
        ("ctrl-0", "ctrl-1"),
        default: "start",
        name: name,
        transform: ctx.transform,
        path-anchors: true,
        path: drawables,
      )

      if mark_.check-mark(style.mark) {
        drawables = mark_.place-marks-along-path(ctx, style.mark, transform, drawables)
      } else {
        drawables = drawable.apply-transform(transform, drawables)
      }

      return (
        ctx: ctx,
        name: name,
        anchors: anchors,
        drawables: drawables,
      )
    },
  )
}

/// Draws a cubic bezier curve through a set of three points. See [bezier](./bezier) for style and anchor details.
///
/// ```typc example
/// let (a, b, c) = ((0, 0), (1, 1), (2, -1))
/// line(a, b, c, stroke: gray)
/// bezier-through(a, b, c, name: "b")
///
/// // Show calculated control points
/// line(a, "b.ctrl-0", "b.ctrl-1", c, stroke: gray)
/// ```
///
/// - start (coordinate): The position to start the curve.
/// - pass-through (coordinate): The position to pass the curve through.
/// - end (coordinate): The position to end the curve.
/// - name (none,str):
/// - ..style (style):
#let bezier-through(start, pass-through, end, name: none, ..style) = {
  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  style = style.named()

  return (ctx => {
    let (ctx, start, pass-through, end) = coordinate.resolve(ctx, start, pass-through, end)

    let (start, end, ..control) = bezier_.cubic-through-3points(start, pass-through, end)

    return bezier(start, end, ..control, ..style, name: name).first()(ctx)
  },)
}

/// Draws a Catmull-Rom curve through a set of points.
///
/// ```typc example
/// catmull((0,0), (1,1), (2,-1), (3,0), tension: .4, stroke: blue)
/// catmull((0,0), (1,1), (2,-1), (3,0), tension: .5, stroke: red)
/// ```
///
/// - ..pts-style (coordinate,style): Positional arguments should be coordinates that the curve should pass through. Named arguments are for styling.
/// - close (bool): Closes the curve with a straight line between the start and end of the curve.
/// - name (none,str):
///
/// ## Styling
/// *Root*: `catmull`
///
/// Supports marks.
///
/// - tension (float) = 0.5: How tight the curve should fit to the points. The higher the tension the less curvy the curve.
///
/// ## Anchors
/// Supports path anchors.
/// - **pt-n**: The nth given position (0 indexed so "pt-0" is equal to "start")
#let catmull(..pts-style, close: false, name: none) = {
  let (pts, style)  = (pts-style.pos(), pts-style.named())

  assert(pts.len() >= 2, message: "Catmull-rom curve requires at least two points. Got " + repr(pts.len()) + "instead.")

  pts.map(coordinate.resolve-system)

  return (ctx => {
    let (ctx, ..pts) = coordinate.resolve(ctx, ..pts)
    let style = styles.resolve(ctx.style, merge: style, root: "catmull")

    let curves = bezier_.catmull-to-cubic(
      pts,
      style.tension,
      close: close)

    let segments = curves.map(c => path-util.cubic-segment(..c))
    let drawables = drawable.path(
      segments,
      fill: style.fill,
      fill-rule: style.fill-rule,
      stroke: style.stroke,
      close: close)

    let (transform, anchors) = {
      let a = for (i, pt) in pts.enumerate() {
        (("pt-" + str(i)): pt)
      }
      anchor_.setup(
        anchor => a.at(anchor), // Would like to return just `a.at` but Typst is mean :<
        a.keys(),
        name: name,
        default: "start",
        transform: ctx.transform,
        path-anchors: true,
        path: drawables,
      )
    }

    if mark_.check-mark(style.mark) {
      drawables = mark_.place-marks-along-path(ctx, style.mark, transform, drawables)
    } else {
      drawables = drawable.apply-transform(transform, drawables)
    }

    return (
      ctx: ctx,
      name: name,
      anchors: anchors,
      drawables: drawables,
    )
  },)
}

/// Draws a Hobby curve through a set of points.
///
/// ```typc example
/// hobby((0, 0), (1, 1), (2, -1), (3, 0), omega: 0, stroke: blue)
/// hobby((0, 0), (1, 1), (2, -1), (3, 0), omega: 1, stroke: red)
/// ```
///
/// - ..pts-style (coordinate,style): Positional arguments are the coordinates to use to draw the curve with, a minimum of two is required. Named arguments are for styling.
/// - tb (auto,array): Incoming tension at `pts.at(n+1)` from `pts.at(n)` to `pts.at(n+1)`. The number given must be one less than the number of points.
/// - ta (auto, array): Outgoing tension at `pts.at(n)` from `pts.at(n)` to `pts.at(n+1)`. The number given must be one less than the number of points.
/// - close (bool): Closes the curve with a proper smooth curve between the start and end of the curve.
/// - name (none,str):
///
/// ## Styling
/// *Root* `hobby`
///
/// Supports marks.
/// - omega (array) = (1, 1): A tuple of floats that describe how curly the curve should be at each endpoint. When the curl is close to zero, the spline approaches a straight line near the endpoints. When the curl is close to one, it approaches a circular arc.
///
/// ## Anchors
/// Supports path anchors.
/// - **pt-n**: The nth given position (0 indexed, so "pt-0" is equal to "start")
#let hobby(..pts-style, ta: auto, tb: auto, close: false, name: none) = {
  let (pts, style)  = (pts-style.pos(), pts-style.named())

  assert(pts.len() >= 2, message: "Hobby curve requires at least two points. Got " + repr(pts.len()) + "instead.")

  pts.map(coordinate.resolve-system)

  return (ctx => {
    let (ctx, ..pts) = coordinate.resolve(ctx, ..pts)
    let style = styles.resolve(ctx.style, merge: style, root: "hobby")

    let curves = hobby_.hobby-to-cubic(
      pts,
      ta: ta,
      tb: tb,
      omega: style.omega,
      close: close)

    let segments = curves.map(c => path-util.cubic-segment(..c))
    let drawables = drawable.path(
      segments,
      fill: style.fill,
      fill-rule: style.fill-rule,
      stroke: style.stroke,
      close: close)

    let (transform, anchors) = {
      let a = for (i, pt) in pts.enumerate() {
        (("pt-" + str(i)): pt)
      }
      anchor_.setup(
        anchor => {
          if type(anchor) == str and anchor in a {
            return a.at(anchor)
          }
        },
        a.keys(),
        name: name,
        default: "start",
        transform: ctx.transform,
        path-anchors: true,
        path: drawables,
      )
    }

    if mark_.check-mark(style.mark) {
      drawables = mark_.place-marks-along-path(ctx, style.mark, transform, drawables)
    } else {
      drawables = drawable.apply-transform(transform, drawables)
    }

    return (
      ctx: ctx,
      name: name,
      anchors: anchors,
      drawables: drawables,
    )
  },)
}

/// Merges two or more paths by concattenating their elements. Anchors and visual styling, such as `stroke` and `fill`, are not preserved. When an element's path does not start at the same position the previous element's path ended, a straight line is drawn between them so that the final path is continuous. You must then pay attention to the direction in which element paths are drawn.
///
/// ```typc example
/// merge-path(fill: white, {
///   line((0, 0), (1, 0))
///   bezier((), (0, 0), (1,1), (0,1))
/// })
/// ```
///
/// Elements hidden via @@hide() are ignored.
///
/// ## Anchors
///   **centroid**: Centroid of the _closed and non self-intersecting_ shape. Only exists if `close` is true.
///   Supports path anchors and shapes where all vertices share the same z-value.
///
/// - body (elements): Elements with paths to be merged together.
/// - close (bool): Close the path with a straight line from the start of the path to its end.
/// - name (none,str):
/// - ..style (style):
#let merge-path(body, close: false, name: none, ..style) = {
  // No extra positional arguments from the style sink
  assert.eq(
    style.pos(),
    (),
    message: "Unexpected positional arguments: " + repr(style.pos()),
  )
  let style = style.named()

  return (
    ctx => {
      let ctx = ctx
      let segments = ()
      for element in body {
        let r = process.element(ctx, element)
        if r != none {
          ctx = r.ctx
          if segments != () and r.drawables != () {
            assert.eq(r.drawables.first().type, "path")
            let start = path-util.segment-end(segments.last())
            let end = path-util.segment-start(r.drawables.first().segments.first())
            if vector.dist(start, end) > 0 {
              segments.push(path-util.line-segment((start, end,)))
            }
          }
          for drawable in r.drawables {
            if drawable.hidden { continue }
            assert.eq(drawable.type, "path")
            segments += drawable.segments
          }
        }
      }

      let style = styles.resolve(ctx.style, merge: style)
      let drawables = drawable.path(fill: style.fill, fill-rule: style.fill-rule, stroke: style.stroke, close: close, segments)

      let (transform, anchors) = anchor_.setup(
        name => {
          if name == "centroid" {
            // Try finding a closed shapes center by
            // Sampling it to a polygon.
            return polygon.simple-centroid(polygon.from-segments(drawables.segments))
          }
        },
        if close != none { ("centroid",) } else { () },
        name: name,
        transform: none,
        path-anchors: true,
        path: drawables,
      )

      return (
        ctx: ctx,
        name: name,
        anchors: anchors,
        drawables: drawables,
      )
    },
  )
}
