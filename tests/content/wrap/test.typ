#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  set-style(content: (wrap: text.with(red, 14pt)))
  content((), [Test text.])
})

#test-case({
  import draw: *

  set-style(content: (wrap: none))
  content((), [No wrapper.])
})
