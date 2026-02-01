#!/bin/bash
# Record syntax GIF: All control flow in one example - {#if}, {#each}, {#case}

set -e
cd "$(dirname "$0")/../.."

# Configuration
COLS=164
ROWS=32
FONT_SIZE=16
SESSION=syntax

# Ensure output directories exist
mkdir -p assets/tmp assets/gifs

# Ensure generated file exists and is formatted
gleam run -m ghtml -- examples/04_control_flow > /dev/null 2>&1
gleam format examples/04_control_flow/src/components/demo_all.gleam > /dev/null 2>&1

tmux kill-session -t $SESSION 2>/dev/null || true

# Create tmux session
tmux new-session -d -s $SESSION -x $COLS -y $ROWS "zsh -f"
tmux set -t $SESSION status off
tmux resize-window -t $SESSION -x $COLS -y $ROWS 2>/dev/null || true

# Set minimal prompt and clear
tmux send-keys -t $SESSION "PS1='$ '" Enter
sleep 0.3
tmux send-keys -t $SESSION "clear" Enter
sleep 0.3

# Split window
tmux split-window -h -t $SESSION "zsh -f"
sleep 0.3

# Setup right pane prompt
tmux send-keys -t $SESSION:0.1 "PS1='$ '" Enter
sleep 0.2
tmux send-keys -t $SESSION:0.1 "clear" Enter
sleep 0.3

# Run both bat commands BEFORE recording - content will be on screen
tmux send-keys -t $SESSION:0.0 "bat -pp -l html examples/04_control_flow/src/components/demo_all.ghtml" Enter
sleep 1
tmux send-keys -t $SESSION:0.1 "bat -pp -l rust examples/04_control_flow/src/components/demo_all.gleam" Enter
sleep 1

# Start recording - content is already displayed
script -q /dev/null bash -c "
  stty cols $COLS rows $ROWS 2>/dev/null
  asciinema rec --overwrite -c 'tmux attach -t $SESSION' assets/tmp/syntax.cast
" &
RECORD_PID=$!
sleep 12

# End recording
kill $RECORD_PID 2>/dev/null || true
wait $RECORD_PID 2>/dev/null || true
tmux kill-session -t $SESSION 2>/dev/null || true

# Trim last 4 lines (termination artifacts) from cast file
LINES=$(wc -l < assets/tmp/syntax.cast)
head -n $((LINES - 4)) assets/tmp/syntax.cast > assets/tmp/syntax_trimmed.cast
mv assets/tmp/syntax_trimmed.cast assets/tmp/syntax.cast

# Convert to GIF
agg --theme dracula --font-size $FONT_SIZE assets/tmp/syntax.cast assets/gifs/syntax_raw.gif

# Crop edges
ffmpeg -y -i assets/gifs/syntax_raw.gif \
  -vf "crop=in_w-8:in_h-8:4:4,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  assets/gifs/syntax.gif 2>/dev/null
rm -f assets/gifs/syntax_raw.gif assets/tmp/syntax.cast

echo "Done! Created assets/gifs/syntax.gif"
