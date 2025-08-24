#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

/// Place marks on zero-length paths. Must not yield
/// a division-by-zero error.
#test-case({
  import draw: *

  let marks = (mark: (begin: ">", end: ">"))

  line((0,0), (0,0), ..marks)
  bezier((0,0), (0,0), (0,0), ..marks)
})
