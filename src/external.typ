///
#let external-state = state("cetz-external-state", "show")

///
#let external(name, filename, ..args) = {
  let meta = (
    name: name,
    file: filename,
  )

  [ #metadata(meta) #label("cetz-external") ]
  external-state.display(s => {
    if s == "show" {
      let path = "/.cetz-external/" + name + ".svg"
      image(path, ..args.named())
    } else {
      []
    }
  })
}
