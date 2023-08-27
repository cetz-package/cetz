#import "util.typ"

// TODO: I do not really like how styling works.
//       Maybe have something more CSS like, i.e.
//       inheriting flat attributes in classes.

// Traverse the style dictionary and inherit all values
// of `new` with value "inherit" from `base` or `global`.
#let inherit(global, base, new) = {
  if type(new) == "dictionary" {
    for (k, v) in new {
      if k in base {
        if v == "inherit" {
          let b = base.at(k)
          if b == "inherit" {
            b = global.at(k, default: none)
          }

          new.insert(k, inherit(global, base, b))
        } else {
          new.insert(k, inherit(global, base, v))
        }
      } else {
        assert(v != "inherit",
          message: "Can not inherit style attribute '" + k + "' from: " + repr(base))
      }
    }
  }

  new
}

// Resolve style recursive
#let resolve-rec(current, new, root: none) = {
  let global
  if root != none and type(current) == "dictionary" {
    (global, current) = (current, current.at(root, default: (:)))
  }
  if new == auto {
    return current
  } else if type(current) != "dictionary" {
    return new
  }
  assert.ne(current, none, message: repr((global, current, new, root)))
  for (k, v) in new {
    current.insert(
      k,
      if k in current and type(current.at(k)) == "dictionary" and
         type(v) == "dictionary" {
        resolve-rec(current.at(k), v)
      } else {
        v
      }
    )
  }

  if root != none {
    for (k, v) in current {
      if k in global {
        if type(v) == "dictionary" {
          current.insert(k, resolve-rec(global, v, root: k))
        }
      }
    }
  }
  return current
}

/// Resolve style
///
/// - current (style): Current style dictionary
/// - new (style): Style to merge onto current
/// - root (string,none): Style root key
/// - inject (style, none): Inject new style at `root`
#let resolve(current, new, root: none, inject: none) = {
  let s = current
  if inject != none {
    assert(root != none,
      message: "When injecting a new base style, root must be set!")
    let new = (:); new.insert(root, inject)
    s = util.merge-dictionary(new, s)
  }
  s = resolve-rec(s, new, root: root)
  return inherit(current, s, s)
}

#let default = (
  fill: none,
  stroke: black + 1pt,
  radius: 1,
  mark: (
    size: .15,
    start: none,
    end: none,
    fill: "inherit",
    stroke: "inherit",
  ),
  line: (
    fill: "inherit",
    stroke: "inherit",
    mark: "inherit",
  ),
  rect: (
    fill: "inherit",
    stroke: "inherit",
  ),
  arc: (
    fill: "inherit",
    stroke: "inherit",

    radius: "inherit",
    mode: "OPEN",
  ),
  circle: (
    fill: "inherit",
    stroke: "inherit",

    radius: "inherit"
  ),
  content: (
    padding: 0em,
    frame: none,

    fill: "inherit",
    stroke: "inherit",
  ),
  bezier: (
    fill: "inherit",
    stroke: "inherit",
    mark: "inherit",
  ),
  shadow: (
    color: gray,
    offset-x: .1,
    offset-y: -.1,
  ),
)
