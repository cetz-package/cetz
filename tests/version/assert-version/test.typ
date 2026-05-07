#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/src/version.typ": version
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  assert-version(std.version(0, 5, 0), max: std.version(0, 6, 0), hint: "tests/version/assert-version")
  circle((0, 0))
})
