# Auto Cleanup Demo - Split Pane
Output cleanup.gif

Set Shell "bash"
Set FontSize 14
Set Width 1000
Set Height 550
Set Theme "Catppuccin Mocha"
Set Padding 10

Hide
Type "cd examples/01_simple"
Enter
Sleep 300ms
# Ensure we have the generated file
Type "gleam run -m lustre_template_gen 2>/dev/null"
Enter
Sleep 2s
Show

# Start tmux with horizontal split
Type "tmux new-session -d -s cleanup -x 100 -y 25 && tmux split-window -h -t cleanup && tmux attach -t cleanup"
Enter
Sleep 1s

# Left pane: show files
Ctrl+b
Type "o"
Sleep 300ms
Type "ls src/components/"
Enter
Sleep 1s

# Right pane: start watch mode
Ctrl+b
Type "o"
Sleep 300ms
Type "gleam run -m lustre_template_gen -- watch"
Enter
Sleep 2s

# Switch to left pane
Ctrl+b
Type "o"
Sleep 500ms

# Show both files exist
Type "echo '--- Before ---' && ls src/components/"
Enter
Sleep 1.5s

# Delete the .lustre file
Type "rm src/components/greeting.lustre"
Enter
Sleep 2s

# Show .gleam is gone
Type "echo '--- After ---' && ls src/components/"
Enter
Sleep 2s

# Restore the file
Hide
Type "git checkout src/components/greeting.lustre"
Enter
Sleep 500ms
Ctrl+b
Type "o"
Sleep 200ms
Ctrl+c
Sleep 500ms
Type "exit"
Enter
Sleep 200ms
Type "exit"
Enter
Sleep 200ms
Type "tmux kill-session -t cleanup 2>/dev/null"
Enter
Show
