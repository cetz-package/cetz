#let typst-angle = angle
#let typst-rotate = rotate

#import "/src/coordinate.typ"
#import "/src/drawable.typ"
#import "/src/styles.typ"
#import "/src/path-util.typ"
#import "/src/util.typ"
#import "/src/vector.typ"
#import "/src/process.typ"
#import "/src/bezier.typ" as bezier_

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
    
    return (
      ctx: ctx,
      name: name,
      anchor: anchor,
      drawables: drawable.apply-transform(ctx.transform, drawable.ellipse(
        ..pos,
        ..util.resolve-radius(style.radius).map(util.resolve-number.with(ctx)),
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

    let anchors = (
      a: a,
      b: b,
      c: c,
      center: center,
    )

    let (x, y, ..) = center
    let r = vector.dist(a, (x, y))
    let style = styles.resolve(ctx.style, style, root: "circle")

    return (
      ctx: ctx,
      name: name,
      anchor: anchor,
      anchors: util.apply-transform(
        ctx.transform,
        anchors
      ),
      drawables: drawable.apply-transform(
        ctx.transform,
        drawable.ellipse(
          x,
          y,
          0,
          r,
          r,
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
  
  return (ctx => {
    let (ctx, position) = coordinate.resolve(ctx, position)
    let (x, y, z) = position
    
    let style = styles.resolve(ctx.style, style, root: "arc")
    let (rx, ry) = util.resolve-radius(style.radius).map(util.resolve-number.with(ctx))
    
    let anchors = (
      start: position,
      end: (
        x - rx * calc.cos(start-angle) + rx * calc.cos(stop-angle),
        y - ry * calc.sin(start-angle) + ry * calc.sin(stop-angle),
        z,
      ),
      origin: (x - rx * calc.cos(start-angle), y - ry * calc.sin(start-angle), z,),
    )
    
    return (
      ctx: ctx,
      name: name,
      anchor: anchor,
      default-anchor: "start",
      anchors: util.apply-transform(ctx.transform, anchors),
      drawables: drawable.apply-transform(
        ctx.transform,
        drawable.arc(
          ..position,
          start-angle,
          stop-angle,
          rx,
          ry,
          stroke: style.stroke,
          fill: style.fill,
          mode: style.mode,
        ),
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
    let (ctx, pts) = coordinate.resolve-many(ctx, (from, to))
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
    let anchors = (
      start: pts.first(),
      end: pts.last()
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
      anchors: util.apply-transform(ctx.transform, anchors),
      drawables: drawable.apply-transform(ctx.transform, drawables)
    )
  },)
}

#let grid(from, to, step: 1, name: none, help-lines: false, ..style) = {
  (from, to).map(coordinate.resolve-system)

  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  style = style.named()

  return (ctx => {
    let (ctx, from, to) = coordinate.resolve(ctx, from, to)
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

    return (
      ctx: ctx,
      name: name,
      drawables: drawable.apply-transform(
        ctx.transform,
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
      let x-dir = vector.scale((calc.cos(angle), -calc.sin(angle)), width/2)
      let y-dir = vector.scale((calc.sin(angle), calc.cos(angle)), height/2)
      let tr-dir = vector.add(x-dir, y-dir)
      let tl-dir = vector.sub(x-dir, y-dir)

      let center = if auto-size {
        a
      } else {
        vector.add(a, (width / 2, -height / 2))
      }

      (
        center: center,
        top-left: vector.sub(center, tl-dir),
        top-right: vector.add(center, tr-dir),
        bottom-left: vector.sub(center, tr-dir),
        bottom-right: vector.add(center, tl-dir),
        left: vector.sub(center, x-dir),
        right: vector.add(center, x-dir),
        bottom: vector.sub(center, y-dir),
        top: vector.add(center, y-dir),
      )
    }

    let drawables = ()

    if style.frame in ("rect", "circle") {
      drawables.push(
        if style.frame == "rect" {
          drawable.path(
            path-util.line-segment((
              anchors.top-left,
              anchors.top-right,
              anchors.bottom-right,
              anchors.bottom-left
            )),
            close: true,
            stroke: style.stroke,
            fill: style.fill
          )
        } else if style.frame == "circle" {
          let (x, y, z) = util.calculate-circle-center-3pt(anchors.top-left, anchors.bottom-left, anchors.bottom-right)
          let r = vector.dist((x, y, z), anchors.top-left)
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


    return (
      ctx: ctx,
      name: name,
      anchor: anchor,
      default-anchor: if auto-size { "center" } else { "top-left" },
      anchors: util.apply-transform(ctx.transform, anchors),
      drawables: drawable.apply-transform(
        ctx.transform,
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
      
      let c = vector.sub(b, a)
      let (w, h, d) = c
      let anchors = (
        bottom-left: a,
        bottom: vector.add(a, (w / 2, 0, d / 2)),
        bottom-right: vector.add(a, (w, 0, d)),
        top-left: vector.sub(b, (w, 0, d)),
        top: vector.sub(b, (w / 2, 0, d / 2)),
        top-right: b,
        left: vector.add(a, (0, h / 2, d / 2)),
        right: vector.sub(b, (0, h / 2, d / 2)),
        center: vector.add(a, (w / 2, h / 2, d / 2)),
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
        anchor: anchor,
        anchors: util.apply-transform(ctx.transform, anchors),
        drawables: drawable.apply-transform(ctx.transform, drawables),
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
      
      let anchors = (start: start, end: end, ctrl-0: ctrl.at(0), ctrl-1: ctrl.at(1))
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
        anchors: util.apply-transform(ctx.transform, anchors),
        drawables: drawable.apply-transform(
          ctx.transform,
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

    return bezier(start, end, ..control, ..style).first()(ctx)
  },)
}

#let catmull(..pts-style, tension: .5, close: false, name: none) = {
  let (pts, style)  = (pts-style.pos(), pts-style.named())

  assert(pts.len() >= 2, message: "Catmull-rom curve requires at least two points. Got " + repr(pts.len()) + "instead.")

  pts.map(coordinate.resolve-system)

  return (ctx => {
    let (ctx, ..pts) = coordinate.resolve(ctx, ..pts)

    let anchors = (
      start: pts.first(),
      end: pts.last(),
    )
    for (i, pt) in pts.enumerate() {
      anchors.insert("pt-" + str(i + 1), pt)
    }

    let style = styles.resolve(ctx.style, style, root: "catmull")
    // let curves = catmull-to-cubic()

    return (
      ctx: ctx,
      name: name,
      anchors: util.apply-transform(ctx.transform, anchors),
      drawables: drawable.apply-transform(
        ctx.transform,
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
          if segments != () {
            assert.eq(r.drawables.first().type, "path")
            let start = path-util.segment-end(segments.last())
            let end = path-util.segment-start(r.drawables.first().segments.first())
            if vector.dist(start, end) > 0 {
              segments.push(path-util.line-segment((end,)))
            }
          }
          for drawable in r.drawables {
            assert.eq(drawable.type, "path")
            segments += drawable.segments
          }
        }
      }
      
      
      let style = styles.resolve(ctx.style, style)
      return (
        ctx: ctx,
        name: name,
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