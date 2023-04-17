# Local Variables:
# mode: makefile
# End:
demo_dir := "./demo"

demo:
    find "{{demo_dir}}" -iname "*.typ" -exec typst compile {} \;
    find "{{demo_dir}}" -iname "*.pdf" -exec convert {} {}.png \;
