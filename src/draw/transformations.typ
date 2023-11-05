#import "/src/coordinate.typ"
#import "/src/matrix.typ"
#import "/src/vector.typ"
#import "/src/util.typ"

#let rotate(angle) = {
  (
    ctx => {
      ctx.transform = matrix.mul-mat(ctx.transform, if type(angle) == "angle" {
        matrix.transform-rotate-z(-angle)
      } else if type(angle) == "dictionary" {
        matrix.transform-rotate-xyz(
          -angle.at("x", default: 0deg),
          -angle.at("y", default: 0deg),
          -angle.at("z", default: 0deg),
        )
      } else {
        panic("Invalid angle format '" + repr(angle) + "'")
      })
      
      return (ctx: ctx)
    },
  )
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

