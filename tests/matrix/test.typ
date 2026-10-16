#set page(width: auto, height: auto)
#import "/src/lib.typ": matrix

// matrix.ident
#assert.eq(matrix.ident(1), ((1.0,),))
#assert.eq(matrix.ident(2), ((1.0, 0), (0, 1.0)))
#assert.eq(matrix.ident(3), ((1.0, 0, 0), (0, 1.0, 0), (0, 0, 1.0)))
#assert.eq(matrix.ident(5), ((1.0, 0, 0, 0, 0), (0, 1.0, 0, 0, 0), (0, 0, 1.0, 0, 0), (0, 0, 0, 1.0, 0), (0, 0, 0, 0, 1.0)))

// matrix.is-identity
#for i in range(1, 8) {
  assert(matrix.is-identity(matrix.ident(i)))
}
#assert(not matrix.is-identity(((1.1,),)))
#assert(not matrix.is-identity(((1, 0), (1, 2))))

// matrix.diag
#assert.eq(matrix.diag(1), ((1,),))
#assert.eq(matrix.diag(1, 2), ((1, 0), (0, 2)))
#assert.eq(matrix.diag(1, 2, 3), ((1, 0, 0), (0, 2, 0), (0, 0, 3)))

// matrix.dim
#assert.eq(matrix.dim(((1,),)), (1, 1))
#assert.eq(matrix.dim(((1, 2),)), (1, 2))
#assert.eq(matrix.dim(((1,), (2,))), (2, 1))

// matrix.column
#assert.eq(matrix.column(matrix.ident(3), 1), (0.0, 1.0, 0.0))

// matrix.inverse
#assert.eq(matrix.inverse(matrix.ident(4)), matrix.ident(4))
#assert.eq(matrix.inverse(((2, 1), (6, 4))), ((2, -1/2), (-3, 1)))

// matrix.mul-vec
#assert.eq(matrix.mul-vec(matrix.ident(3), (1, 0, 4)), (1, 0, 4))
#assert.eq(matrix.mul-vec(((3, 2, 1), (1, 0, 2)), (1, 0, 4)), (7, 9))

// matrix.mul-mat
#assert.eq(matrix.mul-mat(((3, 2, 1), (1, 0, 2)), ((1, 2), (0, 1), (4, 0))), ((7, 8), (9, 2)))
#assert.eq(matrix.mul-mat(matrix.inverse(((2, 1), (6, 4))), ((2, 1), (6, 4))), matrix.ident(2)) // A A^(-1) = I
