# VHS tape for hero GIF - Side-by-side comparison

Output assets/gifs/hero.gif

Set Shell "bash"
Set FontSize 13
Set Width 950
Set Height 420
Set Theme "Dracula"
Set Padding 20
Set Framerate 24

# Setup (hidden)
Hide
Type "rm -f examples/01_simple/src/components/greeting.gleam"
Enter
Sleep 300ms
Type "gleam run -m lustre_template_gen -- examples/01_simple 2>/dev/null"
Enter
Sleep 2s
Type "clear"
Enter
Sleep 300ms
Show

# Show side by side using pr
Type "pr -m -t -w 115 <(echo '── template ──────────────────────────'; cat examples/01_simple/src/components/greeting.lustre) <(echo '── generated ─────────────────────────'; cat examples/01_simple/src/components/greeting.gleam)"
Enter
Sleep 5s
