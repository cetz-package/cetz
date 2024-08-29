---
title: The Canvas
---

The [`canvas`](/api/internal/canvas) function is what handles all of the logic and processing in order to produce drawings. It's usually called with a code block `{...}` as argument. The content of the curly braces is the _body_ of the canvas. Import all the draw functions you need at the top of the body:

```typ
#cetz.canvas({
  import cetz.draw: *

})
```

You can now call the draw functions within the body and they'll produce some graphics! Typst will evaluate the code block and pass the result to the `canvas` function for rendering.

The canvas does not have typical `width` and `height` parameters. Instead its size will grow and shrink to fit the drawn graphic.

By default 1 [coordinate](/basics/coordinate-systems) unit is `1cm`, this can be changed by setting the `length` parameter. If a ratio is given, the length will be the size of the canvas parent's width!
