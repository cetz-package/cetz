#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#set text(dir: rtl)

#test-case({
  import draw: *

  line((0,0), (1,0), mark: (end: ">"))
  content((0,1), [This is an example of RTL.])
  line((0,0), (45deg, 1), mark: (end: ">"))
})
