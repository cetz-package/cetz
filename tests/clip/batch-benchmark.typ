#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

// Manual performance check:
// typst compile --root . --input mode=batch tests/clip/batch-benchmark.typ /tmp/cetz-batch.png
// typst compile --root . --input mode=single tests/clip/batch-benchmark.typ /tmp/cetz-single.png

#let mode = sys.inputs.at("mode", default: "batch")
#assert(mode in ("batch", "single"), message: "mode must be `batch` or `single`")

#test-case({
  import draw: *

  let count = 100
  let clipping-region = {
    for i in range(16) {
      circle((0.02 * i, 0), radius: 230pt)
    }
  }

  let body-line(i) = {
    line(
      (-0.4, -0.2 + i * 0.004),
      (0.4, -0.2 + i * 0.004),
      stroke: 0.7pt + rgb("#1d4ed8"),
    )
  }

  if mode == "batch" {
    clip(
      clipping-region,
      {
        for i in range(count) {
          body-line(i)
        }
      },
      mode: "inside",
      eps: 1e-6,
    )
  } else {
    for i in range(count) {
      clip(
        clipping-region,
        { body-line(i) },
        mode: "inside",
        eps: 1e-6,
      )
    }
  }
})
