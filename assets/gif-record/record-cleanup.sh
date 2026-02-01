#!/bin/bash
# Record cleanup GIF: Auto cleanup demo - delete .lustre file, .gleam file auto-removed

set -e
cd "$(dirname "$0")/../.."

# Configuration
COLS=164
ROWS=32
FONT_SIZE=16
SESSION=cleanup

# Ensure output directories exist
mkdir -p assets/tmp assets/gifs

# Store original content for restoration
TEMPLATE_FILE="examples/01_simple/src/components/greeting.lustre"
GENERATED_FILE="examples/01_simple/src/components/greeting.gleam"
ORIGINAL_CONTENT=$(cat "$TEMPLATE_FILE")

# Ensure both files exist at start
echo "$ORIGINAL_CONTENT" > "$TEMPLATE_FILE"
(cd examples/01_simple && gleam run -m lustre_template_gen 2>/dev/null) || true

tmux kill-session -t $SESSION 2>/dev/null || true

# Create tmux session with split panes
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
  asciinema rec --overwrite -c 'tmux attach -t $SESSION' assets/tmp/cleanup.cast
" &
RECORD_PID=$!
sleep 3

# Left pane: Start watch mode
tmux send-keys -t $SESSION:0.0 "gleam run -m lustre_template_gen -- watch examples/01_simple"
sleep 0.5
tmux send-keys -t $SESSION:0.0 Enter
sleep 4

# Right pane: Show both files exist
tmux send-keys -t $SESSION:0.1 "ls examples/01_simple/src/components/" Enter
sleep 2

# Right pane: Delete the .lustre file
tmux send-keys -t $SESSION:0.1 "rm examples/01_simple/src/components/greeting.lustre"
sleep 0.5
tmux send-keys -t $SESSION:0.1 Enter
sleep 3

# Right pane: Show .gleam file is gone
tmux send-keys -t $SESSION:0.1 "ls examples/01_simple/src/components/" Enter
sleep 5

# End recording
kill $RECORD_PID 2>/dev/null || true
wait $RECORD_PID 2>/dev/null || true
tmux kill-session -t $SESSION 2>/dev/null || true

# Restore original files
echo "$ORIGINAL_CONTENT" > "$TEMPLATE_FILE"
(cd examples/01_simple && gleam run -m lustre_template_gen 2>/dev/null) || true

# Trim last 4 lines (termination artifacts) from cast file
LINES=$(wc -l < assets/tmp/cleanup.cast)
head -n $((LINES - 4)) assets/tmp/cleanup.cast > assets/tmp/cleanup_trimmed.cast
mv assets/tmp/cleanup_trimmed.cast assets/tmp/cleanup.cast

# Convert to GIF
agg --theme dracula --font-size $FONT_SIZE assets/tmp/cleanup.cast assets/gifs/cleanup_raw.gif

# Crop edges
ffmpeg -y -i assets/gifs/cleanup_raw.gif \
  -vf "crop=in_w-8:in_h-8:4:4,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  assets/gifs/cleanup.gif 2>/dev/null
rm -f assets/gifs/cleanup_raw.gif assets/tmp/cleanup.cast

echo "Done! Created assets/gifs/cleanup.gif"
