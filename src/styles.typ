#let resolve(current, new, root: none) = {
  let global
  if root != none and type(current) == dictionary {
    (global, current) = (current, current.at(root, default: (:)))
  }
  if new == auto {
    return current
  } else if type(current) != dictionary {
    return new
  }
  assert.ne(current, none, message: repr((global, current, new, root)))
  for (k, v) in new {
    current.insert(
      k,
      if k in current and type(current.at(k)) == dictionary and type(v) == dictionary {
        resolve(current.at(k), v)
      } else {
        v
      }
    )
  }

  if root != none {
    for (k, v) in current {
      if k in global {
        if v == auto {
          current.insert(
            k,
            global.at(k)
          )
        } else if type(v) == dictionary {
          // panic(global, v, k)
          current.insert(k, resolve(global, v, root: k))
        }
      }
    }
  }
  return current
}

#let default = (
  fill: none,
  stroke: black + 1pt,
  radius: 1,
  mark: (
    size: .15,
    start: none,
    end: none,
    fill: auto,
    stroke: auto
  ),
  line: (
    fill: auto,
    stroke: auto,
    mark: auto,
  ),
  rect: (
    fill: auto,
    stroke: auto,
  ),
  arc: (
    fill: auto,
    stroke: auto,

    radius: auto,
    mode: "OPEN",
  ),
  circle: (
    fill: auto,
    stroke: auto,

    radius: auto
  ),
  content: (
    padding: 0em,
    frame: none,

    fill: auto,
    stroke: auto,
  ),
  bezier: (
    fill: auto,
    stroke: auto,
    mark: auto,
  ),
  shadow: (
    color: gray,
    offset-x: .1,
    offset-y: -.1,
  ),
)
