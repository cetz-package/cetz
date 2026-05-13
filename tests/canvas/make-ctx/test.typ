#import "/src/lib.typ" as cetz

assert.ne(cetz.make-ctx(), none)

assert.eq(cetz.make-ctx().transform, cetz.matrix.ident(4))
assert.eq(cetz.make-ctx(x: 2, y: 2, z: 2).transform,
  ((2, 0, 0, 0), (0, 2, 0, 0), (0, 0, 2, 0), (0, 0, 0, 1)))
assert.eq(cetz.make-ctx(x: (1, 2, 3), y: (2, 3, 4), z: (3, 4, 5)).transform,
  ((1, 2, 3, 0), (2, 3, 4, 0), (3, 4, 5, 0), (0, 0, 0, 1)))
