# VHS tape for watch mode GIF
# Shows watch mode detecting a file change

Output assets/gifs/watch.gif

Set Shell "bash"
Set FontSize 13
Set Width 900
Set Height 500
Set Theme "Dracula"
Set Padding 20
Set Framerate 24

# Setup (hidden) - ensure file exists, then schedule a modification
Hide
Type "gleam run -m lustre_template_gen -- examples/01_simple 2>/dev/null"
Enter
Sleep 2s
# Schedule a file touch in 4 seconds to trigger watch
Type "(sleep 4 && touch examples/01_simple/src/components/greeting.lustre) &"
Enter
Sleep 300ms
Type "clear"
Enter
Sleep 300ms
Show

# Show watch mode
Type "# Watch mode: auto-regenerates on file changes"
Enter
Sleep 500ms

Type "gleam run -m lustre_template_gen -- watch examples/01_simple"
Enter

# Wait for the scheduled touch to trigger regeneration
Sleep 7s

# Stop with Ctrl+C
Ctrl+C
Sleep 1s
