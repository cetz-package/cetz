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
#import "/src/anchor.typ" as anchor_

#import "transformations.typ": *
#import "styling.typ": *
#import "grouping.typ": *

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
    let (x, y, z) = arc-start
    let (rx, ry) = util.resolve-radius(style.radius).map(util.resolve-number.with(ctx))

    let path = (drawable.arc(
      x, y, z,
      start-angle,
      stop-angle,
      rx,
      ry,
      stroke: style.stroke,
      fill: style.fill,
      mode: style.mode,
    ),)

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
            path-util.line-segment((position, sector-center)),
            path-util.line-segment((sector-center, arc-end))
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
          arc-start: position,
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
      style.size,
      fill: style.fill,
      stroke: style.stroke,
    ))
  },)
}

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
    
    let drawables = (drawable.path(
      (path-util.line-segment(pts),),
      fill: style.fill,
      stroke: style.stroke,
      close: close,
    ),)
    
    if style.mark.start != none {
      drawables.push(drawable.mark(
        pts.at(1),
        pts.at(0),
        style.mark.start,
        style.mark.size,
        fill: style.mark.fill,
        stroke: style.mark.stroke,
      ))
    }
    if style.mark.end != none {
      drawables.push(drawable.mark(
        pts.at(-2),
        pts.at(-1),
        style.mark.end,
        style.mark.size,
        fill: style.mark.fill,
        stroke: style.mark.stroke,
      ))
    }

    return (
      ctx: ctx,
      name: name,
      anchors: anchors,
      drawables: drawable.apply-transform(transform, drawables)
    )
  },)
}

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
    panic("Expected 2 or 3 positional arguments, got " + str(args.len))
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
    let padding = util.resolve-number(ctx, style.padding)

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


    let (width, height, ..) = if auto-size {
      util.measure(ctx, body)
    } else {
      vector.sub(b, a)
    }

    width = calc.abs(width) + 2 * padding
    height = calc.abs(height) + 2 * padding

    let anchors = {
      let w = width/2
      let h = height/2
      let center = if auto-size {
        a
      } else {
        vector.add(a, (w, -h))
      }

      let north = (calc.sin(angle)*h, calc.cos(angle)*h,0)
      let east = (calc.cos(-angle)*w, calc.sin(-angle)*w,0)
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

    

    drawables.push(
      drawable.content(
        anchors.center,
        calc.abs(calc.sin(angle) * height + calc.cos(angle) * width),
        calc.abs(calc.cos(angle) * height + calc.sin(angle) * width),
        typst-rotate(angle, 
          block(
            width: width * ctx.length,
            height: height * ctx.length,
            inset: padding * ctx.length,
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
      transform: ctx.transform,
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

#let bezier(start, end, ..ctrl-style, name: none) = {
  // Extra positional arguments are treated like control points.
  let (ctrl, style) = (ctrl-style.pos(), ctrl-style.named())
  
  // Control point check
  let len = ctrl.len()
  assert(
    len in (1, 2),
    message: "Bezier curve expects 1 or 2 control points. Got " + str(len),
  )
  let coordinates = (start, end, ..ctrl)
  
  // Coordinates check
  let t = coordinates.map(coordinate.resolve-system)
  
  return (
    ctx => {
      let (ctx, start, end, ..ctrl) = coordinate.resolve(ctx, ..coordinates)
      
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

      let drawables = (drawable.path(
        path-util.cubic-segment(start, end, ctrl.at(0), ctrl.at(1)),
        fill: style.fill,
        stroke: style.stroke,
      ),)

      if style.mark != none {
        style = style.mark
        let offset = 0.001
        if style.start != none {
          drawables.push(drawable.mark(
            start,
            bezier_.cubic-point(start, end, ..ctrl, offset),
            style.start,
            style.size,
            fill: style.fill,
            stroke: style.stroke
          ))
        }
        if style.start != none {
          drawables.push(drawable.mark(
            bezier_.cubic-point(start, end, ..ctrl, 1 - offset),
            end,
            style.end,
            style.size,
            fill: style.fill,
            stroke: style.stroke
          ))
        }
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


#let bezier-through(start, pass-through, end, name: none, ..style) = {
  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  style = style.named()

  return (ctx => {
    let (ctx, start, pass-through, end) = coordinate.resolve(ctx, start, pass-through, end)

    let (start, end, ..control) = bezier_.cubic-through-3points(start, pass-through, end)

    return bezier(start, end, ..control, ..style, name: name).first()(ctx)
  },)
}

#let catmull(..pts-style, tension: .5, close: false, name: none) = {
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

    return (
      ctx: ctx,
      name: name,
      anchors: anchors,
      drawables: drawable.apply-transform(
        transform,
        drawable.path(
          bezier_.catmull-to-cubic(
            pts,
            tension,
            close: close
          ).map(c => path-util.cubic-segment(..c)),
          fill: style.fill,
          stroke: style.stroke,
          close: close
        )
      )
    )
  },)
}

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

#let shadow(body, ..style) = {
  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  style = style.named()
  return (ctx => {
    let style = styles.resolve(ctx.style, style, root: "shadow")

    let body = {
      group({
        set-style(fill: style.color, stroke: style.color)
        translate((style.offset-x, style.offset-y, 0))
        body
      })
      body
    }

    let (ctx, drawables, ..) = process.many(ctx, body)

    return (
      ctx: ctx,
      drawables: drawables
    )
  },)
}
