# Local Variables:
# mode: makefile
# End:
gallery_dir := "./gallery"

build:
  cd cetz-core; \
  cargo build --release \
    --target wasm32-unknown-unknown; \
  cp target/wasm32-unknown-unknown/release/cetz_core.wasm cetz_core.wasm

package target *options:
  ./common/scripts/package "{{target}}" {{options}}

install target="@local": build
  ./common/scripts/package "{{target}}"

test *filter: build
  tt run {{filter}}

update-test *filter:
  tt update {{filter}}

gallery:
  for f in "{{gallery_dir}}"/*.typ; do typst c "$f" "${f/typ/png}"; done

docs:
  typst query --root . manual.typ "<metadata>" --field value | python ./docs/genhtml.py
