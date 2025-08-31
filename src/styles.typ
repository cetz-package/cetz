#import "util.typ"

#let default = (
  fill: none,
  fill-rule: "non-zero",
  stroke: black + 1pt,
  radius: 1,
  /// Bezier shortening mode:
  ///   - "LINEAR" Moving the affected point and it's next control point (like TikZ "quick" key)
  ///   - "CURVED" Preserving the bezier curve by calculating new control points
  shorten: "LINEAR",

  // Allowed values:
  //   - none
  //   - Number
  //   - Array: (y, x), (top, y, bottom), (top, right, bottom, left)
  //   - Dictionary: (top:, right:, bottom:, left:)
  padding: none,
  mark: (
    scale: 1,         // A factor that is applied to length, width, and inset.
    length: .2cm,     // The size of the mark along its direction
    width: 0.15cm,    // The size of the mark along the normal of its direction
    inset: .05cm,     // The inner length of some mark shapes, like triangles and brackets
    sep: .1cm,        // The distance between multiple marks along their path
    pos: none,        // Position override on the path (none, number or path-length ratio)
    offset: 0,        // Mark extra offset (number or path-length ratio)
    start: none,      // Mark start symbol(s)
    end: none,        // Mark end symbol(s)
    symbol: none,     // Mark symbol
    xy-up: (0, 0, 1), // Up vector for 2D marks
    z-up: (0, 1, 0),  // Up vector for 3D marks
    stroke: auto,
    fill: auto,
    slant: none,      // Slant factor - 0%: no slant, 100%: 45 degree slant
    harpoon: false,
    flip: false,
    reverse: false,
    /// Max. number of samples to use for calculating curve positions
    /// a higher number gives better results but may slow down compilation.
    position-samples: 20,
    /// Index of the mark the path should get shortened to, or auto
    /// to shorten to the last mark. To apply different values per side,
    /// set the default to `0` and to `auto` for the mark you want to
    /// shorten the path to. Set to `none` to disable path shortening.
    shorten-to: auto,
    /// Apply shape transforms for marks. This is not honored per mark, but
    /// for all marks on a path. If set to false, marks get placed after the
    /// shape they are placed on got transformed, they appear "flat" or two-dimensional.
    transform-shape: false,
    /// Mark anchor used for placement
    /// Possible values are:
    ///   - "tip"
    ///   - "center"
    ///   - "base"
    anchor: "tip",
  ),
  circle: (
    radius: auto,
    stroke: auto,
    fill: auto
  ),
  group: (
    padding: auto,
    fill: auto,
    stroke: auto
  ),
  line: (
    mark: auto,
    fill: auto,
    fill-rule: auto,
    stroke: auto,
  ),
  bezier: (
    stroke: auto,
    fill: auto,
    fill-rule: auto,
    mark: auto,
    shorten: auto,
  ),
  catmull: (
    tension: .5,
    mark: auto,
    shorten: auto,
    stroke: auto,
    fill: auto,
    fill-rule: auto,
  ),
  hobby: (
    /// Curve start and end omega (curlyness)
    omega: (0,0),
    mark: auto,
    shorten: auto,
    stroke: auto,
    fill: auto,
    fill-rule: auto,
  ),
  rect: (
    /// Rect corner radius that supports the following types:
    /// - <radius>: Same x and y radius for all corners
    /// - (west: <radius>, east: <radius>, north: <radius>, south: <radius>,
    ///    north-west: <radius>, north-east: <radius>, south-west: <radius>, south-east: <radius>,
    ///    rest: <radius: 0>)
    ///
    /// A radius can be either a number, a ratio or a tuple of numbers or ratios.
    /// Ratios represent a value relative to the rects height or width.
    /// E.g. the radius `50%` is equal to `(50%, 50%)` and represents a x and y radius
    /// of 50% of the rects width/height.
    radius: 0,
    stroke: auto,
    fill: auto,
  ),
  arc: (
    // Supported values:
    //   - "OPEN"
    //   - "CLOSE"
    //   - "PIE"
    mode: "OPEN",
    update-position: true,
    mark: auto,
    stroke: auto,
    fill: auto,
    radius: auto
  ),
  polygon: (
    radius: auto,
    stroke: auto,
    fill: auto,
    fill-rule: auto,
  ),
  n-star: (
    radius: auto,
    stroke: auto,
    fill: auto,
    // Connect inner points of the star
    show-inner: false,
  ),
  content: (
    padding: auto,
    // Supported values
    //   - none
    //   - "rect"
    //   - "circle"
    frame: none,
    fill: auto,
    stroke: auto,
    // Apply canvas scaling to content
    auto-scale: false,
  ),
)

#let _is-stroke-compatible-type(value) = {
  return (type(value) in (stroke, color, length, gradient, tiling) or
          (type(value) == dictionary and value.keys().all(k => k in (
            "paint", "thickness", "join", "cap", "miter-limit", "dash"
          ))))
}

#let _fold-stroke(bottom, top) = {
  if bottom == none {
    return top
  }

  let bottom-type = type(bottom)
  let top-type = type(top)

  if bottom-type in (color, gradient, tiling) {
    bottom = (paint: bottom)
  } else if bottom-type == length {
    bottom = (thickness: bottom)
  } else {
    bottom = util.resolve-stroke(bottom)
  }

  if top-type in (color, gradient, tiling) {
    top = (paint: top)
  } else if top-type == length {
    top = (thickness: top)
  } else {
    top = util.resolve-stroke(top)
  }

  return util.merge-dictionary(bottom, top)
}


#let _fold-value(bottom, top, merge-dictionary-fn: util.merge-dictionary) = {
  // Inherit base value
  if top == auto {
    return bottom
  }

  // Do not try to fold none values
  if bottom == none or top == none {
    return top
  }

  // Merge dictionaries
  if type(bottom) == dictionary and type(top) == dictionary {
    return merge-dictionary-fn(bottom, top)
  }

  // Fold strokes with compatible types if both values
  // are of different type or both values are strokes.
  //
  // Note: _fold-stroke returns a dictionary!
  if ((type(bottom) != type(top) or type(bottom) == stroke) and
      _is-stroke-compatible-type(bottom) and
      _is-stroke-compatible-type(top)) {
    return _fold-stroke(bottom, top)
  }

  return top
}

/// You can use this to combine the style in `ctx`, the style given by a user for a single element and an element's default style.
///
/// `base` is first merged onto `dict` without overwriting existing values, and if `root` is given it is merged onto that key of `dict`. `merge` is then merged onto `dict` but does overwrite existing entries, if `root` is given it is merged onto that key of `dict`. Then entries in `dict` that are {{auto}} inherit values from their nearest ancestor and entries of type {{dictionary}} are merged with their closest ancestor.
/// ```typ example
/// #let dict = (
///   stroke: "black",
///   fill: none,
///   mark: (stroke: auto, fill: "blue"),
///   line: (stroke: auto, mark: auto, fill: "red")
/// )
/// #cetz.styles.resolve(dict, merge: (mark: (stroke: "yellow")), root: "line")
/// ```
/// The following is a more detailed explanation of how the algorithm works to use as a reference if needed. It should be updated whenever changes are made.
/// Remember that dictionaries are recursively merged, if an entry is any other type it is simply updated. (dict + dict = merged dict, value + dict = dict, dict + value = value)
/// First if `base` is given, it will be merged without overwriting values onto `dict`. If `root` is given it will be merged onto that key of `dict`.
/// Each level of `dict` is then processed with these steps. If `root` is given the level with that key will be the first, otherwise the whole of `dict` is processed.
/// + Values on the corresponding level of `merge` are inserted into the level if the key does not exist on the level or if they are not both dictionaries. If they are both dictionaries their values will be inserted in the same stage at a lower level.
/// + If an entry is `auto` or a dictionary, the tree is travelled back up until an entry with the same key is found. If the current entry is `auto` the value of the ancestor's entry is copied. Or if the current entry and ancestor entry is a dictionary, they are merged with the current entry overwriting any values in it's ancestors.
/// + Each entry that is a dictionary is then resolved from step 1.
///
/// ```typc example
/// get-ctx(ctx => {
///   // Get the current "mark" style
///   content((0,0), [#cetz.styles.resolve(ctx.style, root: "mark")])
/// })
/// ```
///
/// - dict (style): Current context style from `ctx.style`.
/// - merge (style): Style values overwriting the current style. I.e. inline styles passed with an element: `line(.., stroke: red)`.
/// - root (none, str, array): Style root element name or list of nested roots (`("my-package", "my-element")`).
/// - base (none, style): Style values to merge into `dict` without overwriting it.
/// -> style
#let resolve(dict, root: none, merge: (:), base: (:)) = {
  let root-dict = dict
  if root != none {
    dict = dict.at(root, default: none)
  } else {
    root-dict = none
  }

  let stack = (
    root-dict, base, dict, merge,
  ).filter(v => v != none and v != auto and v != (:)).rev()

  // Traverses upwards and folds values with parent values.
  let traverse-up(key, stack) = {
    let value = stack.first().at(key, default: auto)
    for style in stack {
      if root != none and root in style {
        let root-style = style.at(root)
        if root-style != auto {
          value = _fold-value(root-style.at(key, default: auto), value)
        }
      }
      value = _fold-value(style.at(key, default: auto), value)
    }
    return value
  }

  // List of keys the final dictionary contains
  let keys = (dict, base, merge)
    .filter(v => v != none and v != auto)
    .map(v => v.keys())
    .flatten()
    .dedup()

  // Recursively fold a dictionary
  let fold-dict(dict) = {
    let new-stack = (dict,) + stack
    for (key, value) in dict {
      value = traverse-up(key, new-stack)
      if type(value) == dictionary and value != (:) {
        value = fold-dict(value)
      }
      dict.insert(key, value)
    }
    return dict
  }

  let merged = (:)
  for key in keys {
    // Try resolve the value upwards
    let value = traverse-up(key, stack)

    // Recurse into dictionaries
    if type(value) == dictionary {
      value = fold-dict(value)
    }
    merged.insert(key, value)
  }

  return merged
}

/// Merge two style dictionaries by using cetz' style
/// folding logic.
///
/// - bottom (dictionary) Base style dictionary.
/// - top (dictionary) New style dictionary to merge on top of `bottom`.
#let merge(bottom, top) = {
  let merge-recursive(bottom, top) = {
    for (k, v) in top {
      // Fold if bottom is a dictionary _and_ v is not auto!
      // Merging style dicts must preserve auto values.
      if type(bottom) == dictionary and k in bottom and v != auto {
        bottom.insert(k, _fold-value(bottom.at(k), v, merge-dictionary-fn: merge-recursive))
      } else {
        bottom.insert(k, v)
      }
    }
    return bottom
  }

  return merge-recursive(bottom, top)
}
