#!/bin/bash
# Record watch GIF: Watch mode demo - edit file, see instant regeneration

set -e
cd "$(dirname "$0")/../.."

# Configuration
COLS=164
ROWS=32
FONT_SIZE=16
SESSION=watch

# Ensure output directories exist
mkdir -p assets/tmp assets/gifs

# Store original content for restoration
TEMPLATE_FILE="examples/01_simple/src/components/greeting.ghtml"
ORIGINAL_CONTENT=$(cat "$TEMPLATE_FILE")

# Clean generated file and ensure original content
rm -f examples/01_simple/src/components/greeting.gleam
echo "$ORIGINAL_CONTENT" > "$TEMPLATE_FILE"

tmux kill-session -t $SESSION 2>/dev/null || true

# Create tmux session with split panes from the start
tmux new-session -d -s $SESSION -x $COLS -y $ROWS "zsh -f"
tmux set -t $SESSION status off
tmux resize-window -t $SESSION -x $COLS -y $ROWS 2>/dev/null || true

# Set minimal prompt in left pane
tmux send-keys -t $SESSION "PS1='$ '" Enter
sleep 0.3
tmux send-keys -t $SESSION "clear" Enter
sleep 0.3

# Split and setup right pane
tmux split-window -h -t $SESSION "zsh -f"
sleep 0.3
tmux send-keys -t $SESSION "PS1='$ '" Enter
sleep 0.2
tmux send-keys -t $SESSION "clear" Enter
sleep 0.2

# Go back to left pane
tmux select-pane -t $SESSION:0.0

# Start recording
script -q /dev/null bash -c "
  stty cols $COLS rows $ROWS 2>/dev/null
  asciinema rec --overwrite -c 'tmux attach -t $SESSION' assets/tmp/watch.cast
" &
RECORD_PID=$!
sleep 3

# Left pane: Start watch mode
tmux send-keys -t $SESSION:0.0 "gleam run -m ghtml -- watch examples/01_simple"
sleep 0.5
tmux send-keys -t $SESSION:0.0 Enter
sleep 4

# Right pane: Show current template
tmux send-keys -t $SESSION:0.1 "cat $TEMPLATE_FILE" Enter
sleep 3

# Right pane: Run sed to make the edit (visible command)
tmux send-keys -t $SESSION:0.1 "sed -i '' 's/Hello/Hi there/' $TEMPLATE_FILE"
sleep 1
tmux send-keys -t $SESSION:0.1 Enter
sleep 3

# Right pane: Show the diff
tmux send-keys -t $SESSION:0.1 "cat $TEMPLATE_FILE"
sleep 0.5
tmux send-keys -t $SESSION:0.1 Enter
sleep 5

# End recording - just kill the recording process while content is displayed
kill $RECORD_PID 2>/dev/null || true
wait $RECORD_PID 2>/dev/null || true
tmux kill-session -t $SESSION 2>/dev/null || true

# Restore original content
echo "$ORIGINAL_CONTENT" > "$TEMPLATE_FILE"

# Trim last 4 lines (termination artifacts) from cast file
LINES=$(wc -l < assets/tmp/watch.cast)
head -n $((LINES - 4)) assets/tmp/watch.cast > assets/tmp/watch_trimmed.cast
mv assets/tmp/watch_trimmed.cast assets/tmp/watch.cast

# Convert to GIF
agg --theme dracula --font-size $FONT_SIZE assets/tmp/watch.cast assets/gifs/watch_raw.gif

# Crop edges
ffmpeg -y -i assets/gifs/watch_raw.gif \
  -vf "crop=in_w-8:in_h-8:4:4,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  assets/gifs/watch.gif 2>/dev/null
rm -f assets/gifs/watch_raw.gif assets/tmp/watch.cast

echo "Done! Created assets/gifs/watch.gif"
