#import "./vector.typ"
#import "./util.typ"

#let resolve-xyz(data, implicit: false) = {
  if implicit {
    return vector.as-vec(data)
  }
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

#let resolve-polar(data, implicit: false) = {
  if not implicit {
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
  }

  let (angle, xr, yr) = if implicit {
    // Don't need to use +/.join because of typst join rules, also because typst rules
    data
    (data.last(),)
  } else {
    (data.angle,)
    if "radius" in data {
      (data.radius,data.radius)
    } else {
      (data.at("x radius"), data.at("y radius"))
    }
  }
  return (
    xr * calc.cos(angle),
    yr * calc.sin(angle),
    0
  )
}



#let resolve-node(ctx, data, implicit: false) = {

  if not implicit {
    // data: (name: string, anchor?: string)
    assert(type(data) == "dictionary" and ((data.len() == 1 and "name" in data) or (data.len() == 2 and "name" in data and "anchor" in data)), message: "Unkown node coordinate form: " + repr(data))
  }
  let (name, anchor) = if implicit {
    let parts = data.split(".")
    if parts.len() == 1 {
      (parts.first(), none)
    } else {
      (parts.slice(0, -1).join("."), parts.last())
    }
  }

  // Check if node is known
  assert(name in ctx.anchors, message: "Unknown node '" + name + "' in nodes " + repr(ctx.anchors))

  let node = ctx.anchors.at(name)
  return util.revert-transform(
    ctx.transform,
    if anchor != none {
      assert(anchor in node,
                message: "Unknown anchor '" + anchor + "' of " + repr(node))
      node.at(anchor)
    } else {
      node.default
    }
  )
}

#let resolve-barycentric(ctx, data) = {
  assert(type(data) == "dictionary" and data.len() >= 1)

  // let vecs = data.keys()//.map(resolve-node.with(ctx, implicit: true))
  // let nums = data.values()
  // let sum = nums.sum()

  return vector.scale(
    data.pairs().fold(
      vector.new(3),
      (vec, (k, v)) => {
          vector.add(
            vec,
            vector.scale(
              resolve-node(ctx, k, implicit: true),
              v
            )
          )
        }
      ),
    1/data.values().sum()
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

#let resolve-tangent(resolve, ctx, data) = {
  // data: (node: <string>, point: <coordinate>, solution: <integer>)

  // https://stackoverflow.com/a/69641745/7142815
  let (C, P) = (resolve-node(ctx, data.node, implicit: true), resolve(ctx, data.point))
  // Radius
  let r = vector.len(vector.sub(resolve-node(ctx, data.node + ".top", implicit: true), C))
  // Vector between C and P
  let D = vector.sub(P, C) // C - P
  // Distance between C and P
  let pc = vector.len(D)
  if pc < r {
    panic("No solution")
  }
  // Distance between P and X0
  let d = r*r / pc
  // Distance between X0 and X1(X2)
  let h = calc.sqrt(r*r - d*d)

  return if data.solution == 1 {
    (
      C.at(0) + (D.at(0) * d - D.at(1) * h) / pc,
      C.at(1) + (D.at(1) * d + D.at(0) * h) / pc,
      0
    )
  } else {
    (
      C.at(0) + (D.at(0) * d + D.at(1) * h) / pc,
      C.at(1) + (D.at(1) * d - D.at(0) * h) / pc,
      0
    )
  }
}

#let resolve(ctx, c) = {
  if c == () {
    return ctx.prev.pt
  }

  if type(c) != "dictionary" {
    if type(c) == "array" {
      if c.all(x => type(x) in ("integer", "float")) and c.len() >= 2 and c.len() <= 3 {
        // xyz
        return resolve-xyz(c, implicit: true)
      } else if type(c.first()) == "angle" and c.len() == 2 {
        // polar
        return resolve-polar(c, implicit: true)
      } else if type(c.first()) == "function" {
        // function
        return resolve(ctx, c.first()(..c.slice(1).map(resolve.with(ctx))))
      }
    } else if type(c) == "string" {
      return resolve-node(ctx, c, implicit: true)
    }
    panic("Unknown implicit coordinate format: " + repr(c))
  } else {
    // cs -> coordinate system
    // (<cs>: <data>)
    let cs = c.keys().first()
    let data = c.values().first()
    return if cs == "xyz" {
      resolve-xyz(data)
    } else if cs == "polar" {
      resolve-polar(data)
    } else if cs == "barycentric" {
      resolve-barycentric(ctx, data)
    } else if cs == "node" {
      resolve-node(ctx, data)
    } else if cs == "rel" {
      resolve-relative(resolve, ctx, c)
    } else if cs == "tangent" {
      resolve-tangent(resolve, ctx, data)
    }
  }
  panic("Failed to resolve coordinate of format: " + repr(c))
}