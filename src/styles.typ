#import "util.typ"

#let default = (
  root: (
    fill: none,
    stroke: black + 1pt,
    radius: 1,
  ),
  line: (
    mark: (
      size: .15,
      start: none,
      end: none,
      stroke: auto,
      fill: none,
    ),
  ),
  bezier: (
    mark: (
      size: .15,
      start: none,
      end: none,
      stroke: auto,
      fill: none,
    ),
  ),
  mark: (
    size: .15,
    start: none,
    end: none,
    stroke: auto,
    fill: none,
  ),
  arc: (
    mode: "OPEN",
  ),
  content: (
    padding: 0em,
    frame: none,
    fill: auto,
    stroke: auto,
  ),
  shadow: (
    color: gray,
    offset-x: .1,
    offset-y: -.1,
  ),
)

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
