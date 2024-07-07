#set page(width: auto, height: auto)
#import "/src/lib.typ": matrix

#{
  let m = (
    (3, 2, 1),
    (1, 0, 2),
  )
  let v = (
    1, 0, 4
  )
  let r = (
    7, 9
  )

  assert(matrix.mul-vec(m, v) == r)
}
