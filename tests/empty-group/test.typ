#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  group(none)
  group(ctx => none)
})

#test-case({
  import draw: *
  group({
    group(name: "group-1", none)
    copy-anchors("group-1")
  })
  group({
    group(name: "group-2", {
      anchor("default", (0,1))
    })
    copy-anchors("group-2")
  })
})
