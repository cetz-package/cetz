#let typst-length = length

#import "drawable.typ"
#import "vector.typ"
#import "matrix.typ"
#import "util.typ"
#import "path-util.typ"
#import "styles.typ"
#import "mark-shapes.typ": get-mark

#let check-mark(style) = (style.start, style.end, style.symbol).any(v => v != none)

#let process-style(ctx, style, root) = {
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
    flex: auto,
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

    for (k, v) in style {
      if k in ("length", "width", "inset", "sep") {
        style.insert(k, if type(v) == ratio {
          style.stroke.thickness * v
        } else {
          util.resolve-number(ctx, v)
        } * style.scale)
      }
    }
    out.push(style)
  }
  return out
}

#let transform-mark(mark, pos, angle, flip: false, reverse: false, slant: none) = {
  mark.drawables = drawable.apply-transform(
    matrix.mul-mat(
      ..(
        matrix.transform-translate(..pos),
        matrix.transform-rotate-z(angle),
        matrix.transform-translate(if reverse { mark.length } else { mark.tip-offset }, 0, 0),
        if slant not in (none, 0deg) {
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

/// Places a mark with the given style at a position pointing towards in the direction of the given angle.
/// - style (dictionary): A dictionary of keys in order to style the mark. The following are the required keys.
///   - stroke
///   - fill
///   - width
///   - length
///   - symbol
///   - inset
/// - pos (vector): The position to place the mark at.
/// - angle (angle): The direction to point the mark towards.
/// -> A dictionary with the keys:
///   - drawables (drawables): The transformed drawables of the mark.
///   - distance: The distance between the tip of the mark and the end.
#let place-mark(ctx, style, pos, angle) = {
  let (mark-fn, reverse) = get-mark(ctx, style.symbol)
  style.reverse = (style.reverse or reverse) and not (style.reverse and reverse)
  let (drawables, distance, tip-offset) = mark-fn(style)

  return (
    drawables: drawable.apply-transform(
      matrix.mul-mat(
        matrix.transform-translate(..pos),
        matrix.transform-rotate-z(angle),
        matrix.transform-translate(tip-offset, 0, 0)
      ),
      drawables
    ),
    distance: distance + tip-offset
  )
}

#let place-mark-on-path(ctx, styles, segments, is-end: false) = {
  if type(styles) != array {
    styles = (styles,)
  }
  let distance = 0
  let drawables = ()
  for (i, style) in styles.enumerate() {
    let is-last = i + 1 == styles.len()
    if style.symbol == none {
      continue
    }
    let (mark-fn, reverse) = get-mark(ctx, style.symbol)
    style.reverse = (style.reverse or reverse) and not (style.reverse and reverse)
    let mark = mark-fn(style)
    mark.length = mark.distance + mark.tip-offset

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
        }
      )
    } else {
      let (_, dir) = path-util.direction(
        segments,
        if is-end {
          100%
        } else {
          0%
        })
      let pt = if is-end {
        path-util.segment-end(segments.last())
      } else {
        path-util.segment-start(segments.first())
      }
      vector.add(pt, vector.scale(vector.norm(dir), distance))
    }

    let angle = if style.flex {
      vector.angle2(
        pos,
        path-util.point-on-path(
          segments,
          (mark.length + distance) * if is-end { -1 } else { 1 },
          samples: style.position-samples
        )
      )
    } else {
      let (_, dir) = path-util.direction(
        segments,
        if is-end {
          100%
        } else {
          0%
        }
      )
      calc.atan2(dir.at(0), dir.at(1)) + if is-end { 180deg }
    }

    mark = transform-mark(
      mark,
      pos,
      angle,
      reverse: style.reverse,
      slant: style.slant, flip: style.flip
    )
    drawables += mark.drawables
    distance += mark.length
    if not is-last {
      distance += style.sep
    } else if not style.reverse {
      // The last mark with an inset needs to offset the
      // distance, so that the path connects to the tip
      distance -= mark.at("inset", default: 0)
    }
  }

  return (
    drawables: drawables,
    distance: distance
  )
}

#let place-marks-along-path(ctx, style, segments) = {
  let distance = (0, 0)
  let drawables = ()
  if style.start != none or style.symbol != none {
    let (drawables: start-drawables, distance: start-distance) = place-mark-on-path(
      ctx,
      process-style(ctx, style, "start"),
      segments
    )
    drawables += start-drawables
    distance.first() = start-distance
  }
  if style.end != none or style.symbol != none {
    let (drawables: end-drawables, distance: end-distance) = place-mark-on-path(
      ctx,
      process-style(ctx, style, "end"),
      segments,
      is-end: true
    )
    drawables += end-drawables
    distance.last() = end-distance
  }
  if distance != (0, 0) {
    segments = path-util.shorten-path(segments, ..distance, mode: if style.flex { "CURVED" } else { "LINEAR" }, samples: style.position-samples)
  }

  return (drawables, segments)
}
