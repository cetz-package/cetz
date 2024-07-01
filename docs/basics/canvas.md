---
title: The Canvas
---

The `canvas` function is what handles all of the logic and processing in order to produce drawings.

To use it, call the function like any other except place a pair of curly braces `{}` inside the brackets with a new line, these braces are now the *body* of the canvas. Then import all the draw functions you need at the top of the body.
```typ
#cetz.canvas({
  import cetz.draw: *
  
})
```
You can now call the draw functions within the body and they'll produce some graphics!

The canvas does not have typical `width` and `height` parameters. Instead its size will grow and shrink to fit the drawn graphic.

By default 1 [coordinate](/basics/coordinate-systems) unit is `1cm`, this can be changed by setting the `length` parameter. If a ratio is given, the length will be the size of the canvas parent's width!

