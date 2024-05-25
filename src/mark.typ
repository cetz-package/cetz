#import "drawable.typ"
#import "vector.typ"
#import "matrix.typ"
#import "util.typ"
#import "path-util.typ"
#import "styles.typ"
#import "mark-shapes.typ": get-mark
#import "process.typ"

#import util: typst-length

/// Checks if a mark should be drawn according to the current style.
/// - style (style): The current style.
/// -> bool
#let check-mark(style) = style != none and (style.start, style.end, style.symbol).any(v => v != none)

/// Processes the mark styling.
/// TODO: remember what is actually going on here.
///
/// - ctx (context): The context object.
/// - style (style): The current style.
/// - root (str): Where the mark is being placed, normally either `"start"` or `"end"`. Allows different styling for marks in different directions.
/// - path-length (float): The length of the path. This is used for relative offsets.
#let process-style(ctx, style, root, path-length) = {
  let base-style = (
    symbol: auto,
    fill: auto,
    stroke: auto,
    slant: auto,
    harpoon: auto,
    flip: auto,
    reverse: auto,
    inset: auto,
    width: auto,
    scale: auto,
    length: auto,
    sep: auto,
    pos: auto,
    offset: auto,
    flex: auto,
    xy-up: auto,
    z-up: auto,
    shorten-to: auto,
    position-samples: auto,
    anchor: auto,
  )

  if type(style.at(root)) != array {
    style.at(root) = (style.at(root),)
  }
  if type(style.symbol) != array {
    style.symbol = (style.symbol,)
  }

  let out = ()
  for i in range(calc.max(style.at(root).len(), style.symbol.len())) {
    let style = style
    style.symbol = style.symbol.at(i, default: auto)
    style.at(root) = style.at(root).at(i, default: auto)

    if type(style.symbol) == dictionary {
      style = styles.resolve(style, merge: style.symbol)
    }

    if type(style.at(root)) == str {
      style.symbol = style.at(root)
    } else if type(style.at(root)) == dictionary {
      style = styles.resolve(style, root: root, base: base-style)
    }

    style.stroke = util.resolve-stroke(style.stroke)
    style.stroke.thickness = util.resolve-number(ctx, style.stroke.thickness)

    if "angle" in style and type(style.angle) == angle {
      style.width = calc.tan(style.angle / 2) * style.length * 2
    }

    // Stroke thickness relative attributes
    for (k, v) in style {
      if k in ("length", "width", "inset", "sep") {
        style.insert(k, if type(v) == ratio {
          style.stroke.thickness * v / 100%
        } else {
          util.resolve-number(ctx, v)
        } * style.scale)
      }
    }

    // Path length relative attributes
    for k in ("offset", "pos",) {
      let v = style.at(k)
      if v != none and v != auto {
        style.insert(k, if type(v) == ratio {
          v * path-length / 100%
        } else {
          util.resolve-number(ctx, v)
        })
      }
    }

    out.push(style)
  }
  return out
}

#let transform-mark(style, mark, pos, dir, flip: false, reverse: false, slant: none, harpoon: false) = {
  let up = style.xy-up
  if dir.at(2) != 0 {
    up = style.z-up
  }

  assert(style.anchor in ("tip", "base", "center"))
  let tip = mark.tip
  let base = mark.base
  let origin = mark.at(style.anchor)

  mark.offset = vector.dist(origin, tip)

  let t = (
    /* Translate & rotate to the target coordinate & direction */
    matrix.transform-translate(..pos),
    matrix.transform-rotate-dir(dir, up),
    matrix.transform-rotate-z(-90deg),

    /* Apply mark transformations */
    if slant not in (none, 0%) {
      if type(slant) == ratio {
        slant /= 100%
      }
      matrix.transform-shear-x(slant)
    },
    if flip or reverse {
      matrix.transform-scale({
        if flip {
          (y: -1)
        }
        if reverse {
          (x: -1)
        }
      })
    },

    /* Rotate mark to have base->tip on the x-axis */
    matrix.transform-rotate-z(vector.angle2(base, tip)),

    /* Translate mark to have its anchor (tip, base, center) at (0,0) */
    matrix.transform-translate(..vector.scale(origin, -1)),
  )

  mark.drawables = drawable.apply-transform(
    matrix.mul-mat(..t.filter(m => m != none)),
    mark.drawables
  )

  return mark
}

#let _eval-mark(ctx, mark, style) = {
  ctx.groups = ()
  ctx.nodes = (:)
  ctx.transform = matrix.ident()

  import "/src/draw.typ"
  let body = draw.group({
    draw.scale(y: -1)
    draw.set-style(
      stroke: style.at("stroke", default: none),
      fill: style.at("fill", default: none)
    )
    draw.set-ctx(ctx => {
      ctx.testtest = "hello"
      return ctx
    })
    mark
  }, name: "mark")
  let (ctx: ctx, bounds: bounds, drawables: drawables) = process.many(ctx, body)
  let anchor-fn = ctx.nodes.at("mark").anchors

  // Check if the mark has named anchor
  let has-anchor(name) = {
    return name in (anchor-fn)(())
  }

  // Fetch special mark anchors
  let get-anchor(name, default: none) = {
    if default != none {
      if not has-anchor(name) {
        return default
      }
    }
    return (anchor-fn)(name)
  }

  let tip = get-anchor("tip", default: (0, 0, 0))
  let base = get-anchor("base", default: tip)
  let center = get-anchor("center", default: vector.lerp(tip, base, .5))

  return (
    tip: tip,
    base: base,
    center: center,
    length: vector.dist(tip, base),
    drawables: drawables,
  )
}

/// Places a mark on the given path. Returns a {{dictionary}} with the following keys:
/// - drawables (drawable): The mark drawables.
/// - distance (float): The length to shorten the path by.
/// - pos (float): The position of the mark, can be used to snap the end of the path to after shortening.
///
/// ---
///
/// - ctx (context): The canvas context object.
/// - styles (style): A processed mark styling.
/// - segments (drawable): The path to place the mark on.
/// - is-end (bool): TODO
/// -> dictionary
#let place-mark-on-path(ctx, styles, segments, is-end: false) = {
  if type(styles) != array {
    styles = (styles,)
  }
  let distance = 0
  let shorten-distance = 0
  let shorten-pos = none
  let drawables = ()
  for (i, style) in styles.enumerate() {
    let is-last = i + 1 == styles.len()
    if style.symbol == none {
      continue
    }

    // Override position, if set
    if style.pos != none {
      distance = style.pos
    }

    // Apply mark offset
    distance += style.offset

    let (mark-fn, defaults) = get-mark(ctx, style.symbol)

    let merge-flag(style, key, default: false) = {
      let old = style.at(key)
      let def = defaults.at(key, default: default)
      style.insert(key, (old or def) and not (old and def))
      return style
    }

    style = merge-flag(style, "reverse")
    style = merge-flag(style, "flip")
    style = merge-flag(style, "harpoon")

    let mark = _eval-mark(ctx, mark-fn(style), style)

    let pos = if style.flex {
      path-util.point-on-path(
        segments,
        if distance != 0 {
          distance * if is-end { -1 } else { 1 }
        } else {
          if is-end {
            100%
          } else {
            0%
          }
        }, extrapolate: true)
    } else {
      let (_, dir) = path-util.direction(
        segments,
        if is-end {
          100%
        } else {
          0%
        },
        clamp: true)
      let pt = if is-end {
        path-util.segment-end(segments.last())
      } else {
        path-util.segment-start(segments.first())
      }
      vector.sub(pt, vector.scale(vector.norm(dir), distance * if is-end { 1 } else { -1 }))
    }
    assert.ne(pos, none,
      message: "Could not determine mark position")

    let dir = if style.flex {
      let a = pos
      let b = path-util.point-on-path(
        segments,
        (mark.length + distance) * if is-end { -1 } else { 1 },
        samples: style.position-samples,
        extrapolate: true)
      if b != none and a != b {
        vector.sub(b, a)
      } else {
        let (_, dir) = path-util.direction(
          segments,
          distance,
          clamp: true)
        vector.scale(dir, if is-end { -1 } else { 1 })
      }
    } else {
      let (_, dir) = path-util.direction(
        segments,
        if is-end {
          100%
        } else {
          0%
        },
        clamp: true)
      if dir != none {
        vector.scale(dir, if is-end { -1 } else { 1 })
      }
    }
    assert.ne(pos, none,
      message: "Could not determine mark direction")

    mark = transform-mark(
      style,
      mark,
      pos,
      dir,
      reverse: style.reverse,
      slant: style.slant,
      flip: style.flip,
      harpoon: style.harpoon,
    )

    // Shorten path to this mark
    let inset = mark.at("inset", default: 0)
    if style.shorten-to != none and (style.shorten-to == auto or i <= style.shorten-to) {
      let offset = mark.offset
      inset += offset

      shorten-distance = distance + mark.length - inset
      shorten-pos = vector.add(pos,
        vector.scale(vector.norm(dir), mark.length - inset))
    }

    drawables += mark.drawables
    distance += mark.length

    // Add separator
    distance += style.sep
  }

  return (
    drawables: drawables,
    distance: shorten-distance,
    pos: shorten-pos
  )
}

/// Places marks along a path. Returns them as an {{array}} of {{drawable}}.
///
/// - ctx (context): The context object.
/// - style (style): The current mark styling.
/// - transform (matrix): The current transformation matrix.
/// - path (drawable): The path to place the marks on.
/// - add-path (bool): When `true` the shortened path will returned as the first {{drawable}} in the {{array}}
/// -> array
#let place-marks-along-path(ctx, style, transform, path, add-path: true) = {
  let distance = (0, 0)
  let snap-to = (none, none)
  let drawables = ()

  let (path, is-transformed) = if not style.transform-shape and transform != none {
    (drawable.apply-transform(transform, path).first(), true)
  } else {
    (path, false)
  }

  let segments = path.segments
  if style.start != none or style.symbol != none {
    let (drawables: start-drawables, distance: start-distance, pos: pt) = place-mark-on-path(
      ctx,
      process-style(ctx, style, "start", path-util.length(segments)),
      segments
    )
    drawables += start-drawables
    distance.first() = start-distance
    snap-to.first() = pt
  }
  if style.end != none or style.symbol != none {
    let (drawables: end-drawables, distance: end-distance, pos: pt) = place-mark-on-path(
      ctx,
      process-style(ctx, style, "end", path-util.length(segments)),
      segments,
      is-end: true
    )
    drawables += end-drawables
    distance.last() = end-distance
    snap-to.last() = pt
  }
  if distance != (0, 0) {
    segments = path-util.shorten-path(
      segments,
      ..distance,
      mode: if style.flex { "CURVED" } else { "LINEAR" },
      samples: style.position-samples,
      snap-to: snap-to)
  }

  if add-path {
    path.segments = segments
    drawables.insert(0, path)
  }

  // If not transformed pre mark placement,
  // transform everything after mark placement.
  if not is-transformed {
    drawables = drawable.apply-transform(transform, drawables)
  }

  return drawables
}
