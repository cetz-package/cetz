#import "util.typ"

// Default mark style
//
// Assuming a mark ">" is pointing directly to the right:
//   - length Sets the length of the mark along its direction (in this case, its horizontal size)
//   - width  Sets the size of the mark along the normal of its direction
//   - inset  Sets the inner length of triangular shaped marks
//   - scale  A factor that is applied to all of the three attributes above
//   - sep    Is the distance between multiple marks along their path
//
// If a mark is pointing to positive or negative z, the mark will be drawn
// with width on the axis perpendicular to its direction and the styles `z-up`
// vector.
#let _default-mark = (
  scale: 1,     // Scaling factor
  length: .2,   // Length
  width: 0.15,  // Width
  inset: .05,   // Arrow mark base inset
  sep: .1,      // Extra distance between marks
  z-up: (0,1,0),// Z-Axis upwards vector
  start: none,  // Mark start symbol(s)
  end: none,    // Mark end symbol(s)
  stroke: auto,
  fill: none,
)

#let default = (
  root: (
    fill: none,
    stroke: black + 1pt,
    radius: 1,
  ),
  mark: _default-mark,
  group: (
    padding: none,
  ),
  line: (
    mark: _default-mark,
  ),
  bezier: (
    mark: (
      .._default-mark,
      /// If true, the mark points in the direction of the secant from
      /// its base to its tip. If false, the tangent at the marks tip is used.
      flex: true,
      /// Max. number of samples to use for calculating curve positions
      /// a higher number gives better results but may slow down compilation.
      position-samples: 30,
    ),
    /// Bezier shortening mode:
    ///   - "LINEAR" Moving the affected point and it's next control point (like TikZ "quick" key)
    ///   - "CURVED" Preserving the bezier curve by calculating new control points
    shorten: "LINEAR",
  ),
  catmull: (
    tension: .5,
    mark: (
      .._default-mark,
      /// If true, the mark points in the direction of the secant from
      /// its base to its tip. If false, the tangent at the marks tip is used.
      flex: true,
      /// Max. number of samples to use for calculating curve positions
      /// a higher number gives better results but may slow down compilation.
      position-samples: 30,
    ),
    shorten: "LINEAR",
  ),
  hobby: (
    /// Curve start and end omega (curlyness)
    omega: (1,1),
    /// Rho function, see /src/hobby.typ for details
    rho: auto,
    mark: (
      .._default-mark,
      /// If true, the mark points in the direction of the secant from
      /// its base to its tip. If false, the tangent at the marks tip is used.
      flex: true,
      /// Max. number of samples to use for calculating curve positions
      /// a higher number gives better results but may slow down compilation.
      position-samples: 30,
    ),
    shorten: "LINEAR",
  ),
  arc: (
    // Supported values:
    //   - "OPEN"
    //   - "CLOSE"
    //   - "PIE"
    mode: "OPEN",
    mark: _default-mark,
    update-position: true,
  ),
  content: (
    // Allowed values:
    //   - none
    //   - Number
    //   - Array: (y, x), (top, y, bottom), (top, right, bottom, left)
    //   - Dictionary: (top:, right:, bottom:, left:)
    padding: 0,
    // Supported values
    //   - none
    //   - "rect"
    //   - "circle"
    frame: none,
    fill: auto,
    stroke: auto,
  ),
)

/// Resolve the current style root
///
/// #example(```
/// get-ctx(ctx => {
///   // Get the current "mark" style
///   content((0,0), [#cetz.styles.resolve(ctx.style, (:), root: "mark")])
/// })
/// ```)
///
/// - current (style): Current context style (`ctx.style`).
/// - new (style): Style values overwriting the current style (or an empty dict).
///                I.e. inline styles passed with an element: `line(.., stroke: red)`.
/// - root (none, str): Style root element name.
/// - base (none, style): Base style. For use with custom elements, see `lib/angle.typ` as an example.
#let resolve(current, new, root: none, base: none) = {
  if base != none {
    if root != none {
      let default = default
      default.insert(root, base)
      base = default
    } else {
      base = util.merge-dictionary(default, base)
    }
  } else {
    base = default
  }

  let resolve-auto(hier, dict) = {
    if type(dict) != dictionary { return dict }
    for (k, v) in dict {
      if v == auto {
        for i in range(0, hier.len()) {
          let parent = hier.at(i)
          if k in parent {
            v = parent.at(k)
            if v != auto {
              dict.insert(k, v)
              break
            }
          }
        }
      }
      if type(v) == dictionary {
        dict.insert(k, resolve-auto((dict,) + hier, v))
      }
    }
    return dict
  }

  let s = base.root
  if root != none and root in base {
    s = util.merge-dictionary(s, base.at(root))
  } else {
    s = util.merge-dictionary(s, base)
  }
  if root != none and root in current {
    s = util.merge-dictionary(s, current.at(root))
  } else {
    s = util.merge-dictionary(s, current)
  }
  
  s = util.merge-dictionary(s, new)
  s = resolve-auto((current, s, base.root), s)
  return s
}
