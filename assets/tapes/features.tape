# VHS tape for features overview GIF
# Quick showcase of key features - caching demo

Output assets/gifs/features.gif

Set Shell "bash"
Set FontSize 14
Set Width 800
Set Height 450
Set Theme "Dracula"
Set Padding 20
Set Framerate 24

# First, remove the generated file (hidden from recording)
Hide
Type "rm -f examples/01_simple/src/components/greeting.gleam"
Enter
Sleep 300ms
Type "clear"
Enter
Sleep 300ms
Show

# Show caching feature
Type "# First run: generates the file"
Enter
Sleep 500ms

Type "gleam run -m lustre_template_gen -- examples/01_simple"
Enter
Sleep 2500ms

Type "# Second run: skipped (unchanged)!"
Enter
Sleep 500ms

Type "gleam run -m lustre_template_gen -- examples/01_simple"
Enter
Sleep 2500ms

Type "# Force mode regenerates anyway"
Enter
Sleep 500ms

Type "gleam run -m lustre_template_gen -- force examples/01_simple"
Enter
Sleep 2500ms
