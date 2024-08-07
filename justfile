# Local Variables:
# mode: makefile
# End:
gallery_dir := "./gallery"

package target *options:
  ./common/scripts/package "{{target}}" {{options}}

install target="@local":
  ./common/scripts/package "{{target}}"

test *filter:
  typst-test run {{filter}}

update-test *filter:
  typst-test update {{filter}}

gallery:
  for f in "{{gallery_dir}}"/*.typ; do typst c "$f" "${f/typ/png}"; done
