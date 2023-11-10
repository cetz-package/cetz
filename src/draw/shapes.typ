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
#import "/src/aabb.typ"

#import "transformations.typ": *
#import "styling.typ": *
#import "grouping.typ": *

/// Draw an ellipse
///
/// The radii of the ellipse can be set via the style key `radius`, which
/// takes a `number` or a tuple of `number`s for the x- an y-radius.
///
/// *Style Root* `circle`
///
/// *Anchors*
///   / `"center"`: The center of the ellipse
///
/// - position (coordinate): Anchor position, by default this is the
///   ellipses center
/// - name (none,string): Element name
/// - anchor (none,string): Anchor to position the element relative to
/// - ..style (style): Style key-values
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
    let style = styles.resolve(ctx.style, style, root: "circle")
    let (rx, ry) = util.resolve-radius(style.radius).map(util.resolve-number.with(ctx))
    let (cx, cy, cz) = pos
    let (ox, oy) = (calc.cos(45deg) * rx, calc.sin(45deg) * ry)

    let (transform, anchors) = anchor_.setup(
      (anchor) => {
        (
          north: (cx, cy + ry),
          north-east: (cx + ox, cy + oy),
          east: (cx + rx, cy),
          south-east: (cx + ox, cy - oy),
          south: (cx, cy - ry),
          south-west: (cx - ox, cy - oy),
          west: (cx - rx, cy),
          north-west: (cx - ox, cy + oy),
          center: (cx, cy)
        ).at(anchor)
        (cz,)
      },
      (
        "north",
        "north-east",
        "east",
        "south-east",
        "south",
        "south-west",
        "west",
        "north-west",
        "center",
      ),
      default: "center",
      name: name,
      offset-anchor: anchor,
      transform: ctx.transform
    )

    return (
      ctx: ctx,
      name: name,
      anchors: anchors,
      // anchors: calculate-anchor.with(transform: transform),
      drawables: drawable.apply-transform(transform, drawable.ellipse(
        cx, cy, cz,
        rx, ry,
        fill: style.fill,
        stroke: style.stroke,
      )),
    )
  },)
}

/// Draw a circle through three coordinates
///
/// *Style Root* `circle`
///
/// *Anchors*
///   / `"center"`: The center of the ellipse
///
/// - a (coordinate): Coordinate a
/// - b (coordinate): Coordinate b
/// - c (coordinate): Coordinate c
/// - name (none,string): Element name
/// - anchor (none,string): Anchor to position the element relative to
/// - ..style (style): Style key-values
#let circle-through(a, b, c, name: none, anchor: none, ..style) = {
  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  style = style.named()

  (a, b, c).map(coordinate.resolve-system)

  return (ctx => {
    let (ctx, a, b, c) = coordinate.resolve(ctx, a, b, c)

    let center = util.calculate-circle-center-3pt(a, b, c)

    let style = styles.resolve(ctx.style, style, root: "circle")
    let (cx, cy, cz) = center
    let r = vector.dist(a, (cx, cy))
    let (ox, oy) = (calc.cos(45deg) * r, calc.sin(45deg) * r)

    let (transform, anchors) = anchor_.setup(
      anchor => {
        (
          north: (cx, cy + r),
          north-east: (cx + ox, cy + oy),
          east: (cx + r, cy),
          south-east: (cx + ox, cy - oy),
          south: (cx, cy - r),
          south-west: (cx - ox, cy - oy),
          west: (cx - r, cy),
          north-west: (cx - ox, cy + oy),
          center: (cx, cy)
        ).at(anchor)
        (cz,)
      },
      (
        "north",
        "north-east",
        "east",
        "south-east",
        "south",
        "south-west",
        "west",
        "north-west",
        "center",
      ),
      default: "center",
      name: name,
      offset-anchor: anchor,
      transform: ctx.transform
    )

    return (
      ctx: ctx,
      name: name,
      anchors: anchors,
      drawables: drawable.apply-transform(
        transform,
        drawable.ellipse(
          cx, cy, 0,
          r, r,
          fill: style.fill,
          stroke: style.stroke
        )
      )
    )
  },)
}

/// Draw a circular segment
///
/// *Style Root* `arc`
///
/// *Anchors*
///   / `"center"`: The center of the arc
///   / `"arc-center"`: Mid-point on the arc border
///   / `"chord-center"`: Center of the chord
///   / `"origin"`: Arc origin
///   / `"arc-start"`: Arc start coordinate
///   / `"arc-end"`: Arc end coordinate
///
/// - position (coordinate): Position to place the arc at. If `anchor` is unset, this
///   is the arcs start position.
/// - start (none,angle): Start angle
/// - stop (none,angle): Stop angle
/// - delta (auto,angle): Angle delta from either start or stop. Exactly two of the three
///   angle arguments must be set.
/// - name (none,string): Element name
/// - ..style (style): Style key-values
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
    let style = styles.resolve(ctx.style, style, root: "arc")
    assert(style.mode in ("OPEN", "PIE", "CLOSE"))

    let (ctx, arc-start) = coordinate.resolve(ctx, position)
    let (rx, ry) = util.resolve-radius(style.radius).map(util.resolve-number.with(ctx))

    // Calculate marks and optimized angles
    let (marks, draw-arc-start, draw-start-angle, draw-stop-angle) = if style.mark != none {
      mark_.place-marks-along-arc(ctx, start-angle, stop-angle,
        arc-start, rx, ry, style, style.mark)
    } else {
      (none, arc-start, start-angle, stop-angle)
    }

    let (x, y, z) = arc-start
    let path = (drawable.arc(
      ..draw-arc-start,
      draw-start-angle,
      draw-stop-angle,
      rx,
      ry,
      stroke: style.stroke,
      fill: style.fill,
      mode: style.mode,
    ),)

    if marks != none {
      path += marks
    }

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

    // center is calculated based on observations of tikz's circular sector and semi circle shapes.
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

    // compass anchors are placed on the shapes border in tikz so prototype version is setup for use here
    let border = anchor_.border.with(
      center, 
      2*rx, 2*ry, 
      path + if style.mode == "OPEN" {
        (
          drawable.path((
            path-util.line-segment((arc-start, sector-center, arc-end)),
          ))
        ,)
      }
    )

    let (transform, anchors) = anchor_.setup(
      anchor => {
        if anchor in anchor_.compass-angle {
          return border(anchor_.compass-angle.at(anchor))
        }
        (
          arc-start: arc-start,
          origin: sector-center,
          arc-end: arc-end,
          arc-center: arc-center,
          chord-center: chord-center,
          center: center,
        ).at(anchor)
      },
      (
        "north",
        "north-east",
        "east",
        "south-east",
        "south",
        "south-west",
        "west",
        "north-west",
        "center",
        "arc-center",
        "chord-center",
        "origin",
        "arc-start",
        "arc-end"
      ),
      default: "arc-start",
      name: name,
      offset-anchor: anchor,
      transform: ctx.transform,
    )

    return (
      ctx: ctx,
      name: name,
      anchors: anchors,
      drawables: drawable.apply-transform(
        transform,
        path,
      )
    )
  },)
}

/// Draw a single mark pointing at a target coordinate
///
/// *Style Root* `mark`
///
/// *Note*: The size of the mark depends on its style values, not
/// the distance between `from` and `to`, which only determine its
/// orientation.
///
/// - from (coordinate): Starting position used for orientation calculation
/// - to (coordinate): The marks target position at which it points
/// - ..style (style): Style key-value pairs
#let mark(from, to, ..style) = {
  assert.eq(
    style.pos(),
    (),
    message: "Unexpected positional arguments: " + repr(style.pos()),
  )
  
  let style = style.named()
  (from, to).map(coordinate.resolve-system)
  
  return (ctx => {
    let (ctx, ..pts) = coordinate.resolve(ctx, from, to)
    let style = styles.resolve(ctx.style, style, root: "mark")
    
    return (ctx: ctx, drawables: drawable.mark(
      ..pts,
      style.symbol,
      style
    ))
  },)
}

/// Draw a line or a line-strip
///
/// *Style Root* `line`
///
/// *Anchors*
///   / `"start"`: The lines start position
///   / `"end"`: The linees start position
///
/// *Style Root* `line`
///
/// - ..pts-style (coordinate,style): Positional two or more coordinates to draw lines between.
///   Accepts style key-value pairs.
/// - close (bool): If true, the line-strip gets closed to form a polygon
/// - name (none,string): Element name
#let line(..pts-style, close: false, name: none) = {
  // Extra positional arguments from the pts-style sink are interpreted as coordinates.
  let pts = pts-style.pos()
  let style = pts-style.named()
  
  assert(pts.len() >= 2, message: "Line must have a minimum of two points")
  
  // Coordinate check
  pts.map(coordinate.resolve-system)
  
  return (ctx => {
    let (ctx, ..pts) = coordinate.resolve(ctx, ..pts)
    let style = styles.resolve(ctx.style, style, root: "line")
    let (transform, anchors) = anchor_.setup(
      (anchor) => {
        (
          start: pts.first(),
          end: pts.last()
        ).at(anchor)
      },
      (
        "start",
        "end"
      ),
      name: name,
      transform: ctx.transform,
    )

    // Place marks and adjust points
    let (marks, pts) = if style.mark != none {
      mark_.place-marks-along-line(ctx, pts, style.mark)
    } else {
      (none, pts)
    }

    let drawables = (drawable.path(
      (path-util.line-segment(pts),),
      fill: style.fill,
      stroke: style.stroke,
      close: close,
    ),)

    if marks != none {
      drawables += marks
    }

    return (
      ctx: ctx,
      name: name,
      anchors: anchors,
      drawables: drawable.apply-transform(transform, drawables)
    )
  },)
}

/// Draw a grid between two coordinates
///
/// *Style Root* `grid`
///
/// - from (coordinate): Start coordinate
/// - to (coordinate): End coordinate
/// - step (number): Grid spacing in canvas units
/// - name (none,string): Element name
/// - ..style (style): Style key-value pairs
#let grid(from, to, step: 1, name: none, help-lines: false, ..style) = {
  (from, to).map(coordinate.resolve-system)

  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  style = style.named()

  return (ctx => {
    let (ctx, from, to) = coordinate.resolve(ctx, from, to)

    (from, to) = (
      (calc.min(from.at(0), to.at(0)), calc.min(from.at(1), to.at(1))),
      (calc.max(from.at(0), to.at(0)), calc.max(from.at(1), to.at(1)))
    )

    let style = styles.resolve(ctx.style, style)
    if help-lines {
      style.stroke = 0.2pt + gray
    }

    let (x-step, y-step) = if type(step) == dictionary {
      (step.at("x", default: 1), step.at("y", default: 1))
    } else if type(step) == array {
      step
    } else {
      (step, step)
    }.map(util.resolve-number.with(ctx))

    let drawables = {
      if x-step != 0 {
        range(int((to.at(0) - from.at(0)) / x-step)+1).map(x => {
          x *= x-step
          x += from.at(0)
          drawable.path(
            path-util.line-segment(((x, from.at(1)), (x, to.at(1)))),
            fill: style.fill,
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
            path-util.line-segment(((from.at(0), y), (to.at(1), y))),
            fill: style.fill,
            stroke: style.stroke
          )
        })
      } else {
        ()
      }
    }

    let center = ((from.first() + to.first()) / 2, (from.last() + to.last()) / 2)
    let (transform, anchors) = anchor_.setup(
      anchor => {
        (
          north: (center.first(), to.last()),
          north-east: to,
          east: (to.first(), center.last()),
          south-east: (to.first(), from.last()),
          south: (center.first(), from.last()),
          south-west: from,
          west: (from.first(), center.last()),
          north-west: (from.first(), to.last()),
          center: center,
        ).at(anchor)
        (0,)
      },
      (
        "north",
        "north-east",
        "east",
        "south-east",
        "south",
        "south-west",
        "west",
        "north-west",
        "center"
      ),
      name: name,
      transform: ctx.transform
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

/// Position typst content in the canvas
///
/// You can call the function with one or two coordinates:
///   - One coordinate `content((..), [..])`: The content gets
///     placed at the coordinate
///   - Two coordinates `content((..), (..), [..])`: The content
///     gets placed insides the rect between the two coordinates
///
/// *Style Root* `content`
///
/// - ..args-style (coordinate,content):
/// - angle (angle,coordinate): Rotation of the content. If a coordinate instead of an angle is used
///   the angle between it and the contents first coordinate is used for rotation
/// - clip (bool): If true, the content is placed inside a box that gets clipped
/// - anchor (none,string): Anchor to position the content relative to. Defaults to the contents center.
/// - name (none,string): Element name
#let content(
    ..args-style,
    angle: 0deg,
    clip: false,
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
    let style = styles.resolve(ctx.style, style, root: "content")
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

    let (width, height, ..) = if auto-size {
      util.measure(ctx, body)
    } else {
      vector.sub(b, a)
    }

    width = (calc.abs(width)
      + padding.at("left", default: 0)
      + padding.at("right", default: 0))
    height = (calc.abs(height)
      + padding.at("top", default: 0)
      + padding.at("bottom", default: 0))

    let anchors = {
      let w = width/2
      let h = height/2
      let center = if auto-size {
        a
      } else {
        vector.add(a, (w, -h))
      }

      // Only the center anchor gets transformed. All other anchors
      // must be calculated relative to the transformed center!
      center = matrix.mul-vec(ctx.transform,
        vector.as-vec(center, init: (0,0,0,1)))

      let north = (calc.sin(angle)*h, -calc.cos(angle)*h,0)
      let east = (calc.cos(-angle)*w, -calc.sin(-angle)*w,0)
      let south = vector.scale(north, -1)
      let west = vector.scale(east, -1)
      (
        center: center,
        north: vector.add(center, north),
        north-east: vector.add(center, vector.add(north, east)),
        east: vector.add(center, east),
        south-east: vector.add(center, vector.add(south, east)),
        south: vector.add(center, south),
        south-west: vector.add(center, vector.add(south, west)),
        west: vector.add(center, west),
        north-west: vector.add(center, vector.add(north, west)),
      )
    }

    let drawables = ()
    if style.frame in ("rect", "circle") {
      drawables.push(
        if style.frame == "rect" {
          drawable.path(
            path-util.line-segment((
              anchors.north-west,
              anchors.north-east,
              anchors.south-east,
              anchors.south-west
            )),
            close: true,
            stroke: style.stroke,
            fill: style.fill
          )
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
      )
    }

    let (aabb-width, aabb-height, ..) = aabb.size(aabb.aabb(
      (anchors.north-west, anchors.north-east,
       anchors.south-west, anchors.south-east)))

    drawables.push(
      drawable.content(
        anchors.center,
        aabb-width,
        aabb-height,
        typst-rotate(angle,
          block(
            width: width * ctx.length,
            height: height * ctx.length,
            inset: (
              top: padding.at("top", default: 0) * ctx.length,
              left: padding.at("left", default: 0) * ctx.length,
              bottom: padding.at("bottom", default: 0) * ctx.length,
              right: padding.at("right", default: 0) * ctx.length,
            ),
            body
          )
        )
      )
    )

    let (transform, anchors) = anchor_.setup(
      anchor => {
        anchors.at(anchor)
      },
      anchors.keys(),
      default: if auto-size { "center" } else { "north-west" },
      offset-anchor: anchor,
      transform: none, // Content does not get transformed, see the calculation
                       // of anchors.
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

/// Draw a rect between two coordinates
///
/// *Style Root* `rect`
///
/// *Tip:* To draw a rect with a specified size instead of two coordinates, use
/// relative coordinates for the second: `(rel: (<width>, <height>))`.
///
/// - a (coordinate): First coordinate
/// - b (coordinate): Second coordinate
/// - name (none,string): Element name
/// - ..style (style): Style key-value pairs
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
      let (transform, anchors) = anchor_.setup(
        (anchor) => {
          let (w, h, d) = vector.sub(b, a)
          let center = vector.add(a, (w/2, h/2))
          (
            north: (center.at(0), b.at(1)),
            north-east: b,
            east: (b.at(0), center.at(1)),
            south-east: (b.at(0), a.at(1)),
            south: (center.at(0), a.at(1)),
            south-west: a,
            west: (a.at(0), center.at(1)),
            north-west: (a.at(0), b.at(1)),
            center: center
          ).at(anchor)
        },
        ("north", "south-west", "south", "south-east", "north-west", "north-east", "east", "west", "center"),
        default: "center",
        name: name,
        offset-anchor: anchor,
        transform: ctx.transform
      )
      
      let style = styles.resolve(ctx.style, style, root: "rect")
      let (x1, y1, z1) = a
      let (x2, y2, z2) = b
      let drawables = drawable.path(
        path-util.line-segment(((x1, y1, z1), (x2, y1, z2), (x2, y2, z2), (x1, y2, z1))),
        fill: style.fill,
        stroke: style.stroke,
        close: true,
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

/// Draw a quadratic or cubic bezier curve
///
/// *Anchors*
/// / `ctrl-<n>`: Nth control point (n is an integer starting at 0)
///
/// *Style Root* `bezier`
///
/// - start (coordinate): Start position
/// - end (coordinate): End position (last coordinate)
/// - ..ctrl-style (coordinate,style): One or two control point coordinates.
///   Accepts style key-value pairs.
/// - name (none,string): Element name
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

      let (transform, anchors) = anchor_.setup(
        anchor => {
          (
            start: start,
            end: end,
            ctrl-0: ctrl.at(0),
            ctrl-1: ctrl.at(1),
          ).at(anchor)
        },
        ("start", "end", "ctrl-0", "ctrl-1"),
        default: "start",
        name: name,
        transform: ctx.transform
      )

      let style = styles.resolve(ctx.style, style, root: "bezier")

      let curve = (start, end, ..ctrl)
      let (marks, curve) = if style.mark != none {
        mark_.place-marks-along-bezier(ctx, curve, style, style.mark)
      } else {
        (none, curve)
      }

      let drawables = (drawable.path(
        path-util.cubic-segment(..curve),
        fill: style.fill,
        stroke: style.stroke,
      ),)

      if marks != none {
        drawables += marks
      }

      return (
        ctx: ctx, 
        name: name,
        anchors: anchors,
        drawables: drawable.apply-transform(
          transform,
          drawables
        )
      )
    },
  )
}

/// Draw a cubic bezier curve through a set of three points
///
/// See `bezier` for style and anchor details.
///
/// - start (coordinate): Start position
/// - pass-through (coordinate): Curve mid-point
/// - end (coordinate): End coordinate
/// - name (none,string): Element name
/// - ..style (style): Style key-value pairs
#let bezier-through(start, pass-through, end, name: none, ..style) = {
  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  style = style.named()

  return (ctx => {
    let (ctx, start, pass-through, end) = coordinate.resolve(ctx, start, pass-through, end)

    let (start, end, ..control) = bezier_.cubic-through-3points(start, pass-through, end)

    return bezier(start, end, ..control, ..style, name: name).first()(ctx)
  },)
}

/// Draw a Catmull-Rom curve through a set of points
///
/// The curves tension can be adjusted using the style key `tension`.
///
/// *Anchors*
///   / `"start"`: First point
///   / `"end"`: Last point
///   / `"pt-<n>"`: Nth point (n is an integer starting at 0)
///
/// *Style Root* `catmull`
///
/// - ..pts-style (coordinate,style): List of points to run the curve through.
///   Accepts style key-value pairs.
/// - close (bool): Auto-close the curve
/// - name (none,string): Element name
#let catmull(..pts-style, close: false, name: none) = {
  let (pts, style)  = (pts-style.pos(), pts-style.named())

  assert(pts.len() >= 2, message: "Catmull-rom curve requires at least two points. Got " + repr(pts.len()) + "instead.")

  pts.map(coordinate.resolve-system)

  return (ctx => {
    let (ctx, ..pts) = coordinate.resolve(ctx, ..pts)

    let (transform, anchors) = {
      let a = (
        start: pts.first(),
        end: pts.last(),
      )
      for (i, pt) in pts.enumerate() {
        a.insert("pt-" + str(i), pt)
      }
      anchor_.setup(
        anchor => {
          a.at(anchor)
        },
        a.keys(),
        name: name,
        default: "start",
        transform: ctx.transform
      )
    }

    let style = styles.resolve(ctx.style, style, root: "catmull")
    let curves = bezier_.catmull-to-cubic(
      pts,
      style.tension,
      close: close)

    let (marks, curves) = if style.mark != none {
      mark_.place-marks-along-beziers(ctx, curves, style, style.mark)
    } else {
      (none, curves)
    }

    let drawables = (
      drawable.path(
        curves.map(c => path-util.cubic-segment(..c)),
        fill: style.fill,
        stroke: style.stroke,
        close: close),)
    if marks != none {
      drawables += marks
    }

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

/// Draw a Hobby curve through a set of points
///
/// The curves curlyness can be adjusted using the style key `omega`.
/// The rho function can be set using the style key `rho`.
///
/// *Anchors*
///   / `"start"`: First point
///   / `"end"`: Last point
///   / `"pt-<n>"`: Nth point (n is an integer starting at 0)
///
/// *Style Root* `hobby`
///
/// - ..pts-style (coordinate,style): List of points to run the curve through.
///   Accepts style key-value pairs.
/// - ta (auto,array): Outgoing tension at point.at(n) from point.at(n) to point.at(n+1). Length must be the length of points minus one
/// - tb (auto,array): Incoming tension at point.at(n+1) from point.at(n) to point.at(n+1). Length must be the length of points minus one:
/// - close (bool): Auto-close the curve
/// - name (none,string): Element name
#let hobby(..pts-style, ta: auto, tb: auto, close: false, name: none) = {
  let (pts, style)  = (pts-style.pos(), pts-style.named())

  assert(pts.len() >= 2, message: "Hobby curve requires at least two points. Got " + repr(pts.len()) + "instead.")

  pts.map(coordinate.resolve-system)

  return (ctx => {
    let (ctx, ..pts) = coordinate.resolve(ctx, ..pts)

    let (transform, anchors) = {
      let a = (
        start: pts.first(),
        end: pts.last(),
      )
      for (i, pt) in pts.enumerate() {
        a.insert("pt-" + str(i), pt)
      }
      anchor_.setup(
        anchor => {
          a.at(anchor)
        },
        a.keys(),
        name: name,
        default: "start",
        transform: ctx.transform
      )
    }

    let style = styles.resolve(ctx.style, style, root: "hobby")
    let curves = hobby_.hobby-to-cubic(
      pts,
      ta: ta,
      tb: tb,
      omega: style.omega,
      rho: style.rho,
      close: close)

    let (marks, curves) = if style.mark != none {
      mark_.place-marks-along-beziers(ctx, curves, style, style.mark)
    } else {
      (none, curves)
    }

    let drawables = (
      drawable.path(
        curves.map(c => path-util.cubic-segment(..c)),
        fill: style.fill,
        stroke: style.stroke,
        close: close),)
    if marks != none {
      drawables += marks
    }

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

/// Merge two or more paths by concattenating their elements
///
/// Note that the draw direction of the joined elements is important
/// to be continuous, as jumps get connected by straight lines!
///
/// - body (drawables): Drawables to be merged into one
/// - close (bool): Auto-close the path (by a straight line)
/// - name (none,string): Element name
/// - ..style (style): Style key-value pairs
#let merge-path(body, close: false, name: none, ..style) = {
  // No extra positional arguments from the style sink
  assert(type(body) in (array, function),
    message: "Incorrect type for body: " + type(body))
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
      let body = if type(body) == function { body(ctx) } else { body }
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
            assert.eq(drawable.type, "path")
            segments += drawable.segments
          }
        }
      }

      let style = styles.resolve(ctx.style, style)

      let (transform, anchors) = anchor_.setup(
        anchor => {
          (
            start: path-util.segment-start(segments.first()),
            end: path-util.segment-end(segments.last()),
          ).at(anchor)
        },
        (
          "start",
          "end"
        ),
        name: name,
        transform: ctx.transform,
      )

      return (
        ctx: ctx,
        name: name,
        anchors: anchors,
        drawables: drawable.path(fill: style.fill, stroke: style.stroke, close: close, segments),
      )
    },
  )
}
