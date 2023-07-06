# Local Variables:
# mode: makefile
# End:
demo_dir := "./demo"
test_dir := "./tests"

package target:
  ./scripts/package "{{target}}"

install:
  ./scripts/package "@local"

test:
  ./scripts/test test

update-test:
  ./scripts/test update

demo:
  find "{{demo_dir}}" -iname "*.typ" -exec typst compile {} \;
  find "{{demo_dir}}" -iname "*.pdf" -exec convert {} {}.png \;
