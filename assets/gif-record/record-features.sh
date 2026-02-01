#!/bin/bash
# Record features GIF: Hash-based caching demo - run twice, second is instant

set -e
cd "$(dirname "$0")/../.."

# Configuration
COLS=164
ROWS=32
FONT_SIZE=16
SESSION=features

# Ensure output directories exist
mkdir -p assets/tmp assets/gifs

# Clean generated files first
rm -f examples/04_control_flow/src/components/*.gleam

tmux kill-session -t $SESSION 2>/dev/null || true

# Create tmux session with clean shell
tmux new-session -d -s $SESSION -x $COLS -y $ROWS "zsh -f"
tmux set -t $SESSION status off
tmux resize-window -t $SESSION -x $COLS -y $ROWS 2>/dev/null || true

# Set minimal prompt
tmux send-keys -t $SESSION "PS1='$ '" Enter
sleep 0.3
tmux send-keys -t $SESSION "clear" Enter
sleep 0.3

# Start recording
script -q /dev/null bash -c "
  stty cols $COLS rows $ROWS 2>/dev/null
  asciinema rec --overwrite -c 'tmux attach -t $SESSION' assets/tmp/features.cast
" &
RECORD_PID=$!
sleep 3

# 1. First run - generates all files
tmux send-keys -t $SESSION "gleam run -m ghtml -- examples/04_control_flow"
sleep 1
tmux send-keys -t $SESSION Enter
sleep 5

# 2. Second run - all cached (instant)
tmux send-keys -t $SESSION "gleam run -m ghtml -- examples/04_control_flow"
sleep 1
tmux send-keys -t $SESSION Enter
sleep 5

# 3. Show the hash in generated file
tmux send-keys -t $SESSION "head -3 examples/04_control_flow/src/components/user_badge.gleam"
sleep 0.5
tmux send-keys -t $SESSION Enter
sleep 4

# End recording - just kill the recording process while content is displayed
kill $RECORD_PID 2>/dev/null || true
wait $RECORD_PID 2>/dev/null || true
tmux kill-session -t $SESSION 2>/dev/null || true

# Trim last 4 lines (termination artifacts) from cast file
LINES=$(wc -l < assets/tmp/features.cast)
head -n $((LINES - 4)) assets/tmp/features.cast > assets/tmp/features_trimmed.cast
mv assets/tmp/features_trimmed.cast assets/tmp/features.cast

# Convert to GIF
agg --theme dracula --font-size $FONT_SIZE assets/tmp/features.cast assets/gifs/features_raw.gif

# Crop edges for clean output
ffmpeg -y -i assets/gifs/features_raw.gif \
  -vf "crop=in_w-8:in_h-8:4:4,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  assets/gifs/features.gif 2>/dev/null
rm -f assets/gifs/features_raw.gif assets/tmp/features.cast

echo "Done! Created assets/gifs/features.gif"
