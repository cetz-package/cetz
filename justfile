# Local Variables:
# mode: makefile
# End:
demo_dir := "./demo"
test_dir := "./tests"

test:
  cd {{test_dir}} && ./run test

update-test:
  cd {{test_dir}} && ./run update

demo:
  find "{{demo_dir}}" -iname "*.typ" -exec typst compile {} \;
  find "{{demo_dir}}" -iname "*.pdf" -exec convert {} {}.png \;
