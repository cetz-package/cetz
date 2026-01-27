# Local Variables:
# mode: makefile
# End:
gallery_dir := "./gallery"

build:
  cd cetz-core; \
  cargo build --release \
    --target wasm32-unknown-unknown; \
  cp target/wasm32-unknown-unknown/release/cetz_core.wasm cetz_core.wasm

package target *options: build
  ./common/scripts/package "{{target}}" {{options}}

install target="@local": build
  ./common/scripts/package "{{target}}"

test *filter: build
  tt run {{filter}}

update-test *filter: build
  tt update {{filter}}

gallery: build
  for f in "{{gallery_dir}}"/*.typ; do echo "Rendering: $f"; typst c "$f" "${f/typ/png}"; done

manual: build
  typst compile --root . manual.typ

docs: build
  typst query --root . manual.typ "<metadata>" --field value | python ./docs/genhtml.py -o ./docs/_generated
