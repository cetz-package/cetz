#import "/src/coordinate.typ"
#import "/src/matrix.typ"
#import "/src/vector.typ"
#import "/src/util.typ"

/// Sets the transformation matrix
///
/// - mat (none,matrix): The 4x4 transformation matrix to set. If `none` is
///   passed, the transformation matrix is set to the identity matrix (
///   `matrix.ident()`).
#let set-transform(mat) = {
  let mat = if mat == none {
    matrix.ident()
  } else {
    mat
  }

  assert(type(mat) == array,
    message: "Transformtion matrix must be of type array. Got " + repr(mat))
  assert.eq(mat.len(), 4,
    message: "Transformation matrix must be of size 4x4")

  (ctx => {
    ctx.transform = mat
    return (ctx: ctx)
  },)
}

#let rotate(..angles) = {
  assert(angles.pos().len() == 1 or angles.named().len() > 0,
    message: "Rotate takes a single z-angle or angles (x, y, z or yaw, pitch, roll) as named arguments")

  let named = angles.named()
  let names = named.keys()

  let mat = if angles.pos().len() == 1 {
    matrix.transform-rotate-z(angles.pos().at(0))
  } else if names.all(n => n in ("x", "y", "z")) {
    matrix.transform-rotate-xyz(named.at("x", default: 0deg),
                                named.at("y", default: 0deg),
                                named.at("z", default: 0deg))
  } else if names.all(n => n in ("yaw", "pitch", "roll")) {
    matrix.transform-rotate-ypr(named.at("yaw", default: 0deg),
                                named.at("pitch", default: 0deg),
                                named.at("roll", default: 0deg))
  } else {
    panic("Invalid rotate arguments." +
          "Rotate expects: A single (z-axis) angle or any combination of x, y,z or any combination of yaw, pitch, roll. " +
          "Got: " + repr(named))
  }

  (ctx => {
    ctx.transform = matrix.mul-mat(ctx.transform, mat)
    return (ctx: ctx)
  },)
}

#let translate(vec, pre: true) = {
  (ctx => {
    let (x, y, z) = if type(vec) == "dictionary" {
      (
        vec.at("x", default: 0),
        vec.at("y", default: 0),
        vec.at("z", default: 0),
      )
    } else if type(vec) == "array" {
      vec
      if vec.len() <= 2 {
        (0,)
      }
    } else {
      panic("Invalid angle format '" + repr(vec) + "'")
    }
    
    
    let transforms = (matrix.transform-translate(x, -y, z), ctx.transform)
    if not pre {
      transforms = transforms.rev()
    }
    ctx.transform = matrix.mul-mat(..transforms)
    
    return (ctx: ctx)
  },)
}

#let scale(factor) = {
  (
    ctx => {
      ctx.transform = matrix.mul-mat(ctx.transform, matrix.transform-scale(factor))
      return (ctx: ctx)
    },
  )
}

#let set-origin(origin) = {
  (
    ctx => {
      let (ctx, c) = coordinate.resolve(ctx, origin)
      let (x, y, z) = vector.sub(
        util.apply-transform(ctx.transform, c),
        util.apply-transform(ctx.transform, (0, 0, 0)),
      )
      ctx.transform = matrix.mul-mat(matrix.transform-translate(x, y, z), ctx.transform)
      return (ctx: ctx)
    },
  )
}

#let move-to(pt) = {
  let t = coordinate.resolve-system(pt)
  
  return (ctx => {
    let (ctx, pt) = coordinate.resolve(ctx, pt)
    return (ctx: ctx)
  },)
}

#let set-viewport(from, to, bounds: (1, 1, 1)) = {
  (from, to).map(coordinate.resolve-system)

  return (ctx => {
    let bounds = vector.as-vec(bounds, init: (1, 1, 1))
    
    let (ctx, from, to) = coordinate.resolve(ctx, from, to)

    let (fx, fy, fz, tx, ty, tz) = from + to
    
    // Compute scaling
    let (sx, sy, sz) = vector.sub((tx, ty, tz), (fx, fy, fz)).enumerate().map(((i, v)) => if bounds.at(i) == 0 {
      0
    } else {
      v / bounds.at(i)
    })

    ctx.transform = matrix.mul-mat(ctx.transform, matrix.mul-mat(
      matrix.transform-translate(fx, fy, fz),
      matrix.transform-scale((x: sx, y: sy, z: sz)),
    ))
    return (ctx: ctx)
  },)
}

