# VHS tape for syntax showcase GIF
# Shows the template syntax with control flow

Output assets/gifs/syntax.gif

Set Shell "bash"
Set FontSize 13
Set Width 900
Set Height 550
Set Theme "Dracula"
Set Padding 20
Set Framerate 24

# Show a rich template with control flow
Type "# Templates support if/each/case control flow"
Enter
Sleep 500ms

Type "cat test/fixtures/control_flow/full.lustre"
Enter
Sleep 5s

# Now generate and show the output
Type "# Generates clean, type-safe Gleam code"
Enter
Sleep 500ms

Type "gleam run -m lustre_template_gen -- test/fixtures/control_flow"
Enter
Sleep 2s

Type "cat test/fixtures/control_flow/full.gleam"
Enter
Sleep 5s
