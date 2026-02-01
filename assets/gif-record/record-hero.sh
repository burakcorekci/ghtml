#!/bin/bash
# Record hero GIF: generation → split view with template & generated code

set -e
cd "$(dirname "$0")/../.."

# Configuration - adjust for desired output size
# Using script+stty to create PTY with custom size (bypasses asciinema 80x24 limit)
# ~1600px width at font-size 16 (~9.7px/col)
# Note: generated code has long lines that will wrap slightly in 81-col panes
COLS=164
ROWS=32
FONT_SIZE=16

# Ensure output directories exist
mkdir -p assets/tmp assets/gifs

# 1. Clean generated files (not recorded)
rm -f examples/01_simple/src/components/greeting.gleam

tmux kill-session -t hero 2>/dev/null || true

# Create tmux session with zsh (no startup noise)
tmux new-session -d -s hero -x $COLS -y $ROWS "zsh -f"
tmux set -t hero status off

# Resize window to ensure correct dimensions
tmux resize-window -t hero -x $COLS -y $ROWS 2>/dev/null || true

# Set minimal prompt
tmux send-keys -t hero "PS1='$ '" Enter
sleep 0.3
tmux send-keys -t hero "clear" Enter
sleep 0.3

# Start recording using script to create PTY with custom size
script -q /dev/null bash -c "
  stty cols $COLS rows $ROWS 2>/dev/null
  asciinema rec --overwrite -c 'tmux attach -t hero' assets/tmp/hero.cast
" &
RECORD_PID=$!

# Wait for recording to fully start and show empty prompt
sleep 3

# 2. Generate the files (recorded) - type command with visible pause before Enter
tmux send-keys -t hero "gleam run -m ghtml -- examples/01_simple"
sleep 1
tmux send-keys -t hero Enter

# Wait for generation to complete
sleep 4

# Format the generated code silently (outside tmux, not recorded)
gleam format examples/01_simple/src/components/greeting.gleam > /dev/null 2>&1

# 3. Split pane first (before showing files)
tmux send-keys -t hero "clear" Enter
sleep 0.3
tmux split-window -h -t hero "zsh -f"
sleep 0.3

# Set minimal prompt in right pane
tmux send-keys -t hero "PS1='$ '" Enter
sleep 0.2
tmux send-keys -t hero "clear" Enter
sleep 0.2

# Go back to left pane and show template (use HTML highlighting for lustre)
tmux select-pane -t hero:0.0
tmux send-keys -t hero "bat -pp -l html examples/01_simple/src/components/greeting.ghtml" Enter
sleep 1

# Go to right pane and show generated (use Rust highlighting for gleam - similar syntax)
tmux select-pane -t hero:0.1
tmux send-keys -t hero "bat -pp -l rust examples/01_simple/src/components/greeting.gleam" Enter

sleep 10

# End recording - just kill the recording process while content is displayed
kill $RECORD_PID 2>/dev/null || true
wait $RECORD_PID 2>/dev/null || true
tmux kill-session -t hero 2>/dev/null || true

# Trim last 4 lines (termination artifacts) from cast file
LINES=$(wc -l < assets/tmp/hero.cast)
head -n $((LINES - 4)) assets/tmp/hero.cast > assets/tmp/hero_trimmed.cast
mv assets/tmp/hero_trimmed.cast assets/tmp/hero.cast

# Convert to GIF
agg --theme dracula --font-size $FONT_SIZE assets/tmp/hero.cast assets/gifs/hero_raw.gif

# Crop 4 pixels from each edge to remove corner artifacts (with proper palette for quality)
ffmpeg -y -i assets/gifs/hero_raw.gif -vf "crop=in_w-8:in_h-8:4:4,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" assets/gifs/hero.gif 2>/dev/null
rm -f assets/gifs/hero_raw.gif assets/tmp/hero.cast

echo "Done! Created assets/gifs/hero.gif (${COLS}x${ROWS} @ font-size ${FONT_SIZE})"
