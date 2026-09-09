#import "/src/draw.typ"
#import "/src/styles.typ"
#import "/src/util.typ"
#import "/src/vector.typ"
#import "/src/matrix.typ"
#import "/src/path-measure.typ"
#import "path.typ": get-segments
#import "text-layout.typ"

#let text-along-default-style = (
  start: 0%,
  stop: 100%,
  align: left,
  raise: 0,
  reverse: false,
  reverse-text: false,
  upright: auto,
  spacing: "natural",
  tracking: 0,
  overflow: "hide",
  corners: "pad",
  corner-threshold: 30deg,
  kerning: true,
)

/// Place text along a named path or an inline path element.
///
/// ```example
/// bezier((0, 0), (4, 0), (1, 1), (3, -1), name: "wave", stroke: gray)
/// cetz.decorations.text-along("wave", [Text along a path], raise: .2, align: center)
/// ```
///
/// Your text splits into grapheme clusteres. Styles and wrappers stay split.
/// More content (math, or boxes) doesn't split. You may pass an array for custom pieces.
/// Empty text doesn't place. Line/pararaph breaks convert to spaces.
///
/// Each individual piece is shaped alone, and rotates rigid with the tangent.
/// Outlines do not bend. Pair widths *approximate* kerning.
/// No cross-piece ligatures, box words to shape at once.
///
/// Text uses Typst text and CeTZ content styles, including wrap,
/// padding, and auto-scale.
///
/// - target (str, element): Named path or one inline path element; must contain a single subpath
/// - body (str, content, array): Text, content, or rigid pieces
/// - name (none, str): Optional group name, with the usual group anchors
/// - ..style (style): Text placement styles
///
/// == Styling
/// *Root*: `text-along`
///
/// / start (ratio, number, length) = `0%`: Start distance along travel.
/// / stop (ratio, number, length) = `100%`: End distance; requires `0 <= start <= stop <= length`.
/// / align (alignment, ratio) = `left`: Horizontal alignment or ratio of unused space.
/// / raise (number, length) = `0`: Offset left of travel; negative moves right.
/// / reverse (bool) = `false`: Travel from end to start.
/// / reverse-text (bool) = `false`: Reverse piece order.
/// / upright (auto, bool) = `auto`: `auto` flips upside-down pieces, `true` keeps horizontal,
///   `false` follows the tangent. Side of the path never changes.
/// / spacing (str) = `"natural"`: `"natural"`, `"fit"` (widen all gaps), `"fit-spaces"`
///   (widen whitespace), or `"equidistant"` (equal center spacing). Fit never shrinks.
/// / tracking (number, length) = `0`: Extra space between pieces, no trailing gap.
/// / overflow (str) = `"hide"`: `"hide"` drops outside pieces,
///   `"clamp"` moves them inside, `"error"` rejects overflow.
/// / corners (str) = `"pad"`: `"pad"` shifts blocks clear of joins,
///   `"skip"` drops crossing pieces, `"ignore"` keeps positions.
/// / corner-threshold (angle) = `30deg`: Turn angle that counts as a corner.
/// / kerning (bool) = `true`: Pair kerning between pieces.
/// -> elements
#let text-along(target, body, name: none, ..style) = draw.get-ctx(ctx => {
  assert(style.pos() == (), message: "decorations.text-along: unexpected positional arguments")
  for key in style.named().keys() {
    assert(key in text-along-default-style,
      message: "decorations.text-along: unknown style " + repr(key))
  }
  let style = styles.resolve(ctx.style, merge: style.named(),
    base: text-along-default-style, root: "text-along")
  for (key, choices) in (
    spacing: ("natural", "fit", "fit-spaces", "equidistant"),
    overflow: ("hide", "clamp", "error"),
    corners: ("pad", "skip", "ignore"),
    upright: (auto, true, false),
    reverse: (true, false), reverse-text: (true, false), kerning: (true, false),
  ) {
    assert(style.at(key) in choices,
      message: "decorations.text-along: " + key + " must be one of " + repr(choices))
  }
  let _ = text-layout.align-factor(style.align)

  let (segments: segments, close: _) = get-segments(ctx, target)
  assert(segments.len() == 1,
    message: "decorations.text-along: target must contain exactly one subpath")
  let measure = path-measure.build(segments, corner-threshold: style.corner-threshold).first()
  assert(measure.xy-planar,
    message: "decorations.text-along: target must lie in a plane parallel to the canvas")
  let start = text-layout.resolve-bound(ctx, style.start, measure.total)
  let stop = text-layout.resolve-bound(ctx, style.stop, measure.total)
  assert(0 <= start and start <= stop and stop <= measure.total,
    message: "decorations.text-along: expected 0 <= start <= stop <= path length")
  let available = stop - start
  let raise = text-layout.resolve-distance(ctx, style.raise)
  let tracking = text-layout.resolve-distance(ctx, style.tracking)
  let clusters = text-layout.tokenize(body)
  if style.reverse-text { clusters = clusters.rev() }
  if clusters == () { return () }
  assert(measure.total > 0, message: "decorations.text-along: path has zero length")

  // Same body and size as draw.content. Apply styles once.
  let content-style = styles.resolve(ctx.style, root: "content")
  let wrap = content-style.at("wrap", default: none)
  let padding = util.map-dict(util.as-padding-dict(content-style.padding), (_, value) =>
    util.resolve-number(ctx, value))
  let content-scale = if content-style.auto-scale == true { (
    vector.len(matrix.column(ctx.transform, 0)),
    vector.len(matrix.column(ctx.transform, 1)),
  ) }
  let render-style = content-style
  render-style.wrap = none
  render-style.auto-scale = false
  let spaces = clusters.map(text-layout.is-space)
  let kernable = clusters.map(text-layout.is-text-cluster)
  clusters = clusters.enumerate().map(((i, c)) => {
    if type(wrap) == function { c = wrap(c) }
    if content-scale != none {
      c = scale(x: content-scale.first() * 100%, y: content-scale.last() * 100%, c, reflow: true)
    }
    // No ligatures across pair-measured graphemes. Rigid pieces keep shaping.
    if kernable.at(i) { text(ligatures: false, c) } else { c }
  })
  let measured = text-layout.measure-advances(ctx, clusters, kerning: style.kerning,
    kernable: kernable, tracking: tracking, padding: padding)
  let widths = measured.widths
  let distances = text-layout.layout-distances(measured.advances, widths, available,
    spacing: style.spacing, align: style.align, spaces: spaces)
  let source-corners = measure.corners
  // A closed seam is one join at 0 and total. Keep both copies.
  if measure.closed {
    source-corners += measure.corners.filter(c => c.s == 0).map(c => (
      s: measure.total, angle: c.angle, side: c.side,
    ))
  }
  let corners = source-corners.map(c => (
    s: (if style.reverse { measure.total - c.s } else { c.s }) - start,
    angle: c.angle,
    side: if style.reverse { -c.side } else { c.side },
  ))
  distances = text-layout.apply-corners(distances, widths, corners, available,
    raise: raise, above: measured.above, below: measured.below, policy: style.corners)
  distances = text-layout.apply-overflow(distances, widths, available, policy: style.overflow)

  let elements = ()
  for (i, distance) in distances.enumerate() {
    if distance == none { continue }
    let info = path-measure.point-at(measure, start + distance, reverse: style.reverse)
    let (dx, dy, _) = info.direction
    let angle = calc.atan2(dx, dy)
    if style.upright == true { angle = 0deg }
    else if style.upright == auto and (angle > 90deg or angle < -90deg) { angle += 180deg }
    // Tangent from point-at is unit length in the canvas plane.
    let normal = (-dy, dx, 0)
    let position = vector.add(info.point, vector.scale(normal, raise))
    elements += draw.content(util.revert-transform(ctx.transform, position), clusters.at(i),
      angle: angle, anchor: "base",
      _metrics: (
        width: widths.at(i) - padding.left - padding.right,
        baseline: measured.above.at(i) - padding.top,
        bounds: measured.above.at(i) + measured.below.at(i) - padding.top - padding.bottom,
      ),
      _resolved-style: render-style,
      _resolved-padding: padding,
    )
  }
  if name == none { elements } else { draw.group(elements, name: name) }
})
