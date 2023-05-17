#import "./vector.typ"
#import "./util.typ"

// Coordinate System Types
#let CS-types = (
  "xyz",
  "polar",
  "rel"
)

#let resolve-xyz(data) = {
  assert(
    data.len() > 0
    and data.len() <= 3
    and data.keys().all(k => k in ("x", "y", "z")),
    message: "Unkown xyz coordinate format: " + repr(data)
  )
  return (
    if "x" in data { data.x } else { 0 },
    if "y" in data { data.y } else { 0 },
    if "z" in data { data.z } else { 0 },
  )
}

#let resolve-polar(data) = {
  assert(
    "angle" in data
    and (
      "radius" in data 
      or (
        "x radius" in data 
        and "y radius" in data
      )
    ),
    message: "Unkown polar coordinate format: " + repr(data)
  )
  let angle = data.angle
  let (xr, yr) = if "radius" in data {(data.radius,data.radius)} else {(data.at("x radius"), data.at("y radius"))}
  return (
    xr * calc.cos(angle),
    yr * calc.sin(angle),
    0
  )
}

#let resolve-relative(resolve, ctx, c) = {
  let update = if "update" in c { c.update } else { true }
  c = vector.add(resolve(ctx, c.rel), ctx.prev.pt)
  if not update {
    c.insert(0, false)
  }
  return c
}

#let resolve-node(ctx, data) = {
  // data: (name: string, anchor?: string)
  assert(type(data) == "dictionary" and ((data.len() == 1 and "name" in data) or (data.len() == 2 and "name" in data and "anchor" in data)), message: "Unkown node coordinate form: " + repr(data))

  // Check if node is known
  assert(data.name in ctx.anchors, message: "Unknown node '" + data.name + "' in nodes " + repr(ctx.anchors))

  let node = ctx.anchors.at(data.name)
  return util.revert-transform(
    ctx.transform,
    if "anchor" in data {
      assert(data.anchor in node,
                message: "Unknown anchor '" + data.anchor + "' of " + repr(node))
      node.at(data.anchor)
    } else {
      node.default
    }
  )
}

#let resolve(ctx, c) = {
  if c == () {
    return ctx.prev.pt
  }

  // c: (<coordinate-system>: <data>, ..)
  let explicit = type(c) == "dictionary"
  // Convert implicit coordinates to explicit
  if not explicit {
    // Done is used as `c` is just reassigned then passes through, a function is not used because of the XYZ
    let done = false
    if type(c) == "array" {
      if c.all(x => type(x) in ("integer", "float")) and c.len() >= 2 and c.len() <= 3 {
        // XYZ
        // The implicit version is the vector form of the explicit, just make sure it has 3 dimensions
        return vector.as-vec(c)
      } else if type(c.first()) == "angle" and c.len() == 2 {
        // polar
        c = (
          polar: (
            angle: c.first(),
            radius: c.last()
          )
        )
        done = true
      } else if type(c.first()) == "function" {
        // Function
        return resolve(ctx, c.first()(..c.slice(1).map(resolve.with(ctx))))
      }
    } else if type(c) == "string" {
      let parts = c.split(".")
      c = (:)
      if parts.len() == 1 {
        c.node = (name: parts.first())
      } else {
        c.node = (name: parts.slice(0, -1).join("."), anchor: parts.last())
      }
      done = true
    }

    if not done {
      panic("Unknown implicit coordinate: " + repr(c))
    }
  }

  
  // cs = coordinate system
  // (<cs>: <data>)
  let cs = c.keys().first()
  let data = c.values().first()
  if cs == "xyz" {
    return resolve-xyz(data)
  } else if cs == "polar" {
    return resolve-polar(data)
  } else if cs == "rel" {
    return resolve-relative(resolve, ctx, c)
  } else if cs == "node" {
    return resolve-node(ctx, data)
  }
  panic("")
}