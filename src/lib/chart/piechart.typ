#import "/src/draw.typ"
#import "/src/styles.typ"
#import "/src/intersection.typ"
#import "/src/vector.typ"
#import "/src/util.typ": circle-arclen
#import "/src/lib/palette.typ"

// Piechart Label Kind
#let label-kind = (value: "VALUE", percentage: "%", label: "LABEL")

// Piechart Default Style
#let default-style = (
  stroke: auto,
  fill: auto,
  /// Outer chart radius
  radius: 1,
  /// Inner slice radius
  inner-radius: 0,
  /// Gap between items. This can be a canvas length or an angle
  gap: 0.5deg,
  /// Outset offset, absolute or relative to radius
  outset-offset: 10%,
  /// Pie outset mode:
  ///   - "OFFSET": Offset slice position by outset-offset
  ///   - "RADIUS": Offset slice radius by outset-offset (the slice gets scaled)
  outset-mode: "OFFSET",
  /// Pie start angle
  start: 0deg,
  /// Pie stop angle
  stop: 360deg,
  outer-label: (
    /// Label kind
    /// If set to a function, that function gets called with (value, label) of each item
    content: label-kind.label,
    /// Absolute radius or percentage of radius
    radius: 125%,
    /// Absolute angle or auto to use secant of the slice as direction
    angle: 0deg,
    /// Label anchor
    anchor: "center",
  ),
  inner-label: (
    /// Label kind
    /// If set to a function, that function gets called with (value, label) of each item
    content: none,
    /// Absolute radius or percentage of the mid between radius and inner-radius
    radius: 150%,
    /// Absolute angle or auto to use secant of the slice as direction
    angle: 0deg,
    /// Label anchor
    anchor: "center",
  ),
)

/// Draw a pie- or donut-chart
///
/// #example(```
/// import cetz.chart
/// let data = (24, 31, 18, 21, 23, 18, 27, 17, 26, 13)
/// let colors = gradient.linear(red, blue, green, yellow)
///
/// chart.piechart(
///   data,
///   radius: 1.5,
///   slice-style: colors,
///   inner-radius: .5,
///   outer-label: (content: "%",))
/// ```)
///
/// = Styling
/// *Root* `piechart` \
/// #show-parameter-block("radius", ("number"), [
///   Outer radius of the chart.], default: 1)
/// #show-parameter-block("inner-radius", ("number"), [
///   Inner radius of the chart slices. If greater than zero, the chart becomes
///   a "donut-chart".], default: 0)
/// #show-parameter-block("gap", ("number", "angle"), [
///   Gap between chart slices to leave empty. This does not increase the charts
///   radius by pushing slices outwards, but instead shrinks the slice. Big
///   values can result in slices becoming invisible if no space is left.], default: 0.5deg)
/// #show-parameter-block("outset-offset", ("number", "ratio"), [
///   Absolute, or radius relative distance to push slices marked for
///   "outsetting" outwards from the center of the chart.], default: 10%)
/// #show-parameter-block("outset-offset", ("string"), [
///   The mode of how to perform "outsetting" of slices:
///   - "OFFSET": Offset slice position by `outset-offset`, increasing their gap to their siblings
///   - "RADIUS": Offset slice radius by `outset-offset`, which scales the slice and leaves the gap unchanged], default: "OFFSET")
/// #show-parameter-block("start", ("angle"), [
///   The pie-charts start angle. You can use this to draw charts not forming a full circle.], default: 0deg)
/// #show-parameter-block("stop", ("angle"), [
///   The pie-charts stop angle.], default: 360deg)
/// #show-parameter-block("outer-label.content", ("none","string","function"), [
///   Content to display outsides the charts slices.
///   There are the following predefined values:
///   / LABEL: Display the slices label (see `label-key`)
///   / %: Display the percentage of the items value in relation to the sum of
///     all values, rounded to the next integer
///   / VALUE: Display the slices value
///   If passed a `<function>` of the format `(value, label) => content`,
///   that function gets called with each slices value and label and must return
///   content, that gets displayed.], default: "LABEL")
/// #show-parameter-block("outer-label.radius", ("number","ratio"), [
///   Absolute, or radius relative distance from the charts center to position
///   outer labels at.], default: 125%)
/// #show-parameter-block("outer-label.angle", ("angle","auto"), [
///   The angle of the outer label. If passed `auto`, the label gets rotated,
///   so that the baseline is parallel to the slices secant. ], default: 0deg)
/// #show-parameter-block("outer-label.anchor", ("string"), [
///   The anchor of the outer label to use for positioning.], default: "center")
/// #show-parameter-block("inner-label.content", ("none","string","function"), [
///   Content to display insides the charts slices.
///   See `outer-label.content` for the possible values.], default: none)
/// #show-parameter-block("inner-label.radius", ("number","ratio"), [
///   Distance of the inner label to the charts center. If passed a `<ratio>`,
///   that ratio is relative to the mid between the inner and outer radius (`inner-radius` and `radius`)
///   of the chart], default: 150%)
/// #show-parameter-block("inner-label.angle", ("angle","auto"), [
///   See `outer-label.angle`.], default: 0deg)
/// #show-parameter-block("inner-label.anchor", ("string"), [
///   See `outer-label.anchor`.], default: "center")
///
/// = Anchors
///   The chart places one anchor per item at the radius of it's slice that
///   gets named `"item-<index>"` (outer radius) and `"item-<index>-inner"` (inner radius),
///   where index is the index of the sclice data in `data`.
///
/// - data (array): Array of data items. A data item can be:
///   - A number: A number that is used as the fraction of the slice
///   - An array: An array which is read depending on value-key, label-key and outset-key
///   - A dictionary: A dictionary which is read depending on value-key, label-key and outset-key
/// - value-key (none,int,string): Key of the "value" of a data item. If for example
///   data items are passed as dictionaries, the value-key is the key of the dictionary to
///   access the items chart value.
/// - label-key (none,int,string): Same as the value-key but for getting an items label content.
/// - outset-key (none,int,string): Same as the value-key but for getting if an item should get outset (highlighted). The
///   outset can be a bool, float or ratio. If of type `bool`, the outset distance from the
///   style gets used.
/// - outset (none,int,array): A single or multiple indices of items that should get offset from the center to the outsides
///   of the chart. Only used if outset-key is none!
/// - slice-style (function,array,gradient): Slice style of the following types:
///   - function: A function of the form `index => style` that must return a style dictionary.
///     This can be a `palette` function.
///   - array: An array of style dictionaries or fill colors of at least one item. For each slice the style at the slices
///     index modulo the arrays length gets used.
///   - gradient: A gradient that gets sampled for each data item using the the slices
///     index divided by the number of slices as position on the gradient.
///   If one of stroke or fill is not in the style dictionary, it is taken from the charts style.
#let piechart(data,
              value-key: none,
              label-key: none,
              outset-key: none,
              outset: none,
              slice-style: palette.red,
              name: none,
              ..style) = {
  import draw: *

  // Prepare data by converting it to tuples of the format
  // (value, label, outset)
  data = data.enumerate().map(((i, item)) => (
    if value-key != none {
      item.at(value-key)
    } else {
      item
    },
    if label-key != none {
      item.at(label-key)
    } else {
      none
    },
    if outset-key != none {
      item.at(outset-key, default: false)
    } else if outset != none {
      i == outset or (type(outset) == array and i in outset)
    } else {
      false
    }
  ))

  let sum = data.map(((value, ..)) => value).sum()
  if sum == 0 {
    sum = 1
  }

  group(name: name, ctx => {
    anchor("center", (0,0))

    let style = styles.resolve(ctx,
      merge: style.named(), root: "piechart", base: default-style)

    let gap = style.gap
    if type(gap) != angle {
      gap = gap / (2 * calc.pi * style.radius) * 360deg
    }
    assert(gap < 360deg / data.len(),
      message: "Gap angle is too big for " + str(data.len()) + "items. Maximum gap angle: " + repr(360deg / data.len()))

    let radius = style.radius
    assert(radius > 0,
      message: "Radius must be > 0.")

    let inner-radius = style.inner-radius
    assert(inner-radius >= 0 and inner-radius <= radius,
      message: "Radius must be >= 0 and <= radius.")

    assert(style.outset-mode in ("OFFSET", "RADIUS"),
      message: "Outset mode must be 'OFFSET' or 'RADIUS', but is: " + str(style.outset-mode))

    let style-at = if type(slice-style) == function {
      slice-style
    } else if type(slice-style) == array {
      i => {
        let s = slice-style.at(calc.rem(i, slice-style.len()))
        if type(s) == color {
          (fill: s)
        } else {
          s
        }
      }
    } else if type(slice-style) == gradient {
      i => (fill: slice-style.sample(i / data.len() * 100%))
    }

    let start-angle = style.start
    let stop-angle = style.stop
    let f = (stop-angle - start-angle) / sum

    let get-item-label(item, kind) = {
      let (value, label, ..) = item
      if kind == label-kind.value {
        [#value]
      } else if kind == label-kind.percentage {
        [#{calc.round(value / sum * 100)}%]
      } else if kind == label-kind.label {
        label
      } else if type(kind) == function {
        (kind)(value, label)
      }
    }

    let start = start-angle
    for (i, item) in data.enumerate() {
      let (value, label, outset) = item
      if value == 0 { continue }

      let origin = (0,0)
      let radius = radius
      let inner-radius = inner-radius

      // Calculate item angles
      let delta = f * value
      let end = start + delta

      // Apply item outset
      let outset-offset = if outset == true {
        style.outset-offset
      } else if outset == false {
        0
      } else if type(outset) in (float, ratio) {
        outset
      } else {
        panic("Invalid type for outset. Expected bool, float or ratio, got: " + repr(outset))
      }
      if type(outset-offset) == ratio {
        outset-offset = outset-offset * radius / 100%
      }

      if outset-offset != 0 {
        if style.outset-mode == "OFFSET" {
          let dir = (calc.cos((start + end) / 2), calc.sin((start + end) / 2))
          origin = vector.add(origin, vector.scale(dir, outset-offset))
            radius += outset-offset
        } else {
          radius += outset-offset
          if inner-radius > 0 {
            inner-radius += outset-offset
          }
        }
      }

      // Calculate gap angles
      let outer-gap = gap
      let gap-dist = outer-gap / 360deg * 2 * calc.pi * radius
      let inner-gap = if inner-radius > 0 {
        gap-dist / (2 * calc.pi * inner-radius) * 360deg
      } else {
        1 / calc.pi * 360deg
      }

      // Calculate angle deltas
      let outer-angle = end - start - outer-gap * 2
      let inner-angle = end - start - inner-gap * 2
      let mid-angle = (start + end) / 2

      // Skip negative values
      if outer-angle < 0deg {
        // TODO: Add a warning as soon as Typst is ready!
        continue
      }

      // A sharp item is an item that should be round but is sharp due to the gap being big
      let is-sharp = inner-radius == 0 or circle-arclen(inner-radius, angle: inner-angle) > circle-arclen(radius, angle: outer-angle)

      let inner-origin = vector.add(origin, if inner-radius == 0 {
        if gap-dist >= 0 {
          let outer-end = vector.scale((calc.cos(end - outer-gap), calc.sin(end - outer-gap)), radius)
          let inner-end = vector.scale((calc.cos(end - inner-gap), calc.sin(end - inner-gap)), gap-dist)
          let outer-start = vector.scale((calc.cos(start + outer-gap), calc.sin(start + outer-gap)), radius)
          let inner-start = vector.scale((calc.cos(start + inner-gap), calc.sin(start + inner-gap)), gap-dist)

          intersection.line-line(outer-end, inner-end, outer-start, inner-start, ray: true)
        } else {
          (0,0)
        }
      } else if is-sharp {
        let outer-end = vector.scale((calc.cos(end - outer-gap), calc.sin(end - outer-gap)), radius)
        let inner-end = vector.scale((calc.cos(end - inner-gap), calc.sin(end - inner-gap)), inner-radius)
        let outer-start = vector.scale((calc.cos(start + outer-gap), calc.sin(start + outer-gap)), radius)
        let inner-start = vector.scale((calc.cos(start + inner-gap), calc.sin(start + inner-gap)), inner-radius)

        intersection.line-line(outer-end, inner-end, outer-start, inner-start, ray: true)
      } else {
        (0,0)
      })

      // Draw one segment
      let stroke = style-at(i).at("stroke", default: style.stroke)
      let fill = style-at(i).at("fill", default: style.fill)
      if data.len() == 1 {
        // If the chart has only one segment, we may have to fake a path
        // with a hole in it by using a combination of multiple arcs.
        if inner-radius > 0 {
          // Split the circle/arc into two arcs
          // and fill them
          merge-path({
            arc(origin, start: start-angle, stop: mid-angle, radius: radius, anchor: "origin")
            arc(origin, stop: start-angle, start: mid-angle, radius: inner-radius, anchor: "origin")
          }, close: false, fill:fill, stroke: none)
          merge-path({
            arc(origin, start: mid-angle, stop: stop-angle, radius: radius, anchor: "origin")
            arc(origin, stop: mid-angle, start: stop-angle, radius: inner-radius, anchor: "origin")
          }, close: false, fill:fill, stroke: none)

          // Create arcs for the inner and outer border and stroke them.
          // If the chart is not a full circle, we have to merge two arc
          // at their ends to create closing lines
          if stroke != none {
            if stop-angle - start-angle != 360deg {
              merge-path({
                arc(origin, start: start, stop: end, radius: inner-radius, anchor: "origin")
                arc(origin, start: end, stop: start, radius: radius, anchor: "origin")
              }, close: true, fill: none, stroke: stroke)
            } else {
              arc(origin, start: start, stop: end, radius: inner-radius, fill: none, stroke: stroke, anchor: "origin")
              arc(origin, start: start, stop: end, radius: radius, fill: none, stroke: stroke, anchor: "origin")
            }
          }
        } else {
          arc(origin, start: start, stop: end, radius: radius, fill: fill, stroke: stroke, mode: "PIE", anchor: "origin")
        }
      } else {
        // Draw a normal segment
        if inner-origin != none {
          merge-path({
            arc(origin, start: start + outer-gap, stop: end - outer-gap, anchor: "origin",
              radius: radius)
            if inner-radius > 0 and not is-sharp {
              if inner-angle < 0deg {
                arc(inner-origin, stop: end - inner-gap, delta: inner-angle, anchor: "origin",
                  radius: inner-radius)
              } else {
                arc(inner-origin, start: end - inner-gap, delta: -inner-angle, anchor: "origin",
                  radius: inner-radius)
              }
            } else {
              line((rel: (end - outer-gap, radius), to: origin),
                   inner-origin,
                   (rel: (start + outer-gap, radius), to: origin))
            }
          }, close: true, fill: fill, stroke: stroke)
        }
      }

      // Place outer label
      let outer-label = get-item-label(item, style.outer-label.content)
      if outer-label != none {
        let r = style.outer-label.radius
        if type(r) == ratio {r = r * radius / 100%}

        let dir = (r * calc.cos(mid-angle), r * calc.sin(mid-angle))
        let pt = vector.add(origin, dir)

        let angle = style.outer-label.angle
        if angle == auto {
          angle = vector.add(pt, (dir.at(1), -dir.at(0)))
        }

        content(pt, outer-label, angle: angle, anchor: style.outer-label.anchor)
      }

      // Place inner label
      let inner-label = get-item-label(item, style.inner-label.content)
      if inner-label != none {
        let r = style.inner-label.radius
        if type(r) == ratio {r = r * (radius + inner-radius) / 200%}

        let dir = (r * calc.cos(mid-angle), r * calc.sin(mid-angle))
        let pt = vector.add(origin, dir)

        let angle = style.inner-label.angle
        if angle == auto {
          angle = vector.add(pt, (dir.at(1), -dir.at(0)))
        }

        content(pt, inner-label, angle: angle, anchor: style.inner-label.anchor)
      }

      // Place item anchor
      anchor("item-" + str(i), (rel: (mid-angle, radius), to: origin))
      anchor("item-" + str(i) + "-inner", (rel: (mid-angle, inner-radius), to: origin))

      start = end
    }
  })
}
