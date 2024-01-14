#let typst-length = length

#import "drawable.typ"
#import "vector.typ"
#import "matrix.typ"
#import "util.typ"
#import "path-util.typ"
#import "styles.typ"
#import "mark-shapes.typ": get-mark

#let check-mark(style) = style != none and (style.start, style.end, style.symbol).any(v => v != none)

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
    position-samples: auto
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
          style.stroke.thickness * v
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

  mark.drawables = drawable.apply-transform(
    matrix.mul-mat(
      ..(
        matrix.transform-translate(..pos),
        matrix.transform-rotate-dir(dir, up),
        matrix.transform-rotate-z(90deg),
        matrix.transform-translate(if reverse { mark.length } else { mark.tip-offset }, 0, 0),
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
        }
      ).filter(e => e != none)
    ),
    mark.drawables
  )
  return mark
}

/// Places one or more marks with the given styles on path segments.
/// - ctx (context):
/// - styles (dictionary): A dictionary of keys in order to style the mark. The following are the required keys.
///   - stroke
///   - fill
///   - width
///   - length
///   - symbol
///   - inset
/// - segments (array): List of path segments
/// - is-end (bool): If false, marks get placed in the direction from the first segment to the last
///   segment; in reverse order if true.
/// -> A dictionary with the keys:
///   - drawables (drawables): The transformed drawables of the mark.
///   - distance (float): The distance between the tip of the mark and the end.
///   - pos (vector): The position the path segments must get shortened to.
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

    let (mark-fn, reverse) = get-mark(ctx, style.symbol)
    style.reverse = (style.reverse or reverse) and not (style.reverse and reverse)

    let mark = mark-fn(style)
    mark.length = mark.distance + if style.reverse {
      mark.at("base-offset", default: style.stroke.thickness / 2)
    } else {
      mark.at("tip-offset", default: style.stroke.thickness / 2)
    }

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

#let place-marks-along-path(ctx, style, segments) = {
  let distance = (0, 0)
  let snap-to = (none, none)
  let drawables = ()
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

  return (drawables, segments)
}
