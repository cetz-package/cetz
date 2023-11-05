# Local Variables:
# mode: makefile
# End:
gallery_dir := "./gallery"
test_dir := "./tests"

package target:
  ./scripts/package "{{target}}"

install:
  ./scripts/package "@local"

test *filter:
  ./scripts/test test {{filter}}

update-test *filter:
  ./scripts/test update {{filter}}

manual:
  typst c manual.typ manual.pdf

gallery:
  for f in "{{gallery_dir}}"/*.typ; do typst c "$f" "${f/typ/png}"; done
