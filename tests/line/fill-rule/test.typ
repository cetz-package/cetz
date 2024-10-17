#set page(width: auto, height: auto)

#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  line((25pt, 0pt),
       (10pt, 50pt),
       (50pt, 20pt),
       (0pt, 20pt),
       (40pt, 50pt), close: true, fill: blue, fill-rule: "non-zero")
})

#test-case({
  import draw: *

  line((25pt, 0pt),
       (10pt, 50pt),
       (50pt, 20pt),
       (0pt, 20pt),
       (40pt, 50pt), close: true, fill: blue, fill-rule: "even-odd")
})
