# GIF Recording Guide

This directory contains scripts for recording terminal GIFs for the README.

## Prerequisites

Install these tools:

```sh
brew install asciinema agg tmux bat ffmpeg
```

## Quick Start

Run any recording script from the project root:

```sh
bash assets/gif-record/record-hero.sh
bash assets/gif-record/record-features.sh
bash assets/gif-record/record-syntax.sh
bash assets/gif-record/record-watch.sh
```

## Recording Approach

All scripts use the same pattern:

1. **tmux** - Creates terminal sessions with split panes
2. **asciinema** - Records terminal output to `.cast` files
3. **agg** - Converts `.cast` to GIF with dracula theme
4. **ffmpeg** - Crops edges for clean output

## Unified Dimensions

All GIFs use consistent dimensions:
- **Columns:** 164
- **Rows:** 32
- **Font size:** 16
- **Theme:** dracula

This produces ~1600px wide GIFs that display well in the README.

## Caveats & Solutions

### 1. Bypassing asciinema's 80-column headless limit

asciinema defaults to 80x24 in headless mode. We use `script` + `stty` to create a PTY with custom size:

```bash
script -q /dev/null bash -c "
  stty cols $COLS rows $ROWS 2>/dev/null
  asciinema rec --overwrite -c 'tmux attach -t $SESSION' output.cast
" &
```

### 2. Clean shell prompts

Use `zsh -f` to start zsh without rc files, then set a minimal prompt:

```bash
tmux new-session -d -s $SESSION -x $COLS -y $ROWS "zsh -f"
tmux send-keys -t $SESSION "PS1='$ '" Enter
tmux send-keys -t $SESSION "clear" Enter
```

### 3. Avoiding "[terminated]" or "[exited]" artifacts

Don't send exit commands to shells. Instead:
1. Kill the recording process while content is displayed
2. Trim the last 4 lines from the cast file

```bash
kill $RECORD_PID 2>/dev/null || true
wait $RECORD_PID 2>/dev/null || true
tmux kill-session -t $SESSION 2>/dev/null || true

# Trim termination artifacts
LINES=$(wc -l < output.cast)
head -n $((LINES - 4)) output.cast > output_trimmed.cast
mv output_trimmed.cast output.cast
```

Note: macOS `head` doesn't support `head -n -4`, so we calculate the line count first.

### 4. Preventing content flicker in split panes

When displaying static content (like syntax examples), run the display commands BEFORE starting the recording:

```bash
# Display content first
tmux send-keys -t $SESSION:0.0 "bat -pp -l html file.lustre" Enter
sleep 1
tmux send-keys -t $SESSION:0.1 "bat -pp -l rust file.gleam" Enter
sleep 1

# Then start recording - content is already on screen
script -q /dev/null bash -c "..." &
```

### 5. Syntax highlighting

Use `bat` with appropriate language flags:
- `.lustre` files: `-l html` (close enough)
- `.gleam` files: `-l rust` (similar syntax highlighting)
- Use `-pp` for plain output (no line numbers, no paging)

### 6. Cropping edge artifacts

agg sometimes produces corner artifacts. Crop 4 pixels from each edge:

```bash
ffmpeg -y -i input.gif \
  -vf "crop=in_w-8:in_h-8:4:4,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  output.gif 2>/dev/null
```

The `palettegen/paletteuse` filter chain maintains GIF quality.

### 7. Timing considerations

- Allow 0.3s after prompt setup commands
- Allow 1s after `bat` commands for content to render
- Allow 3-5s for `gleam run` commands to complete
- End recordings with content visible for 3-10s

## Script Template

```bash
#!/bin/bash
set -e
cd "$(dirname "$0")/../.."

# Configuration
COLS=164
ROWS=32
FONT_SIZE=16
SESSION=myrecording

# Ensure output directories exist
mkdir -p assets/tmp assets/gifs

# Setup tmux session
tmux kill-session -t $SESSION 2>/dev/null || true
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
  asciinema rec --overwrite -c 'tmux attach -t $SESSION' assets/tmp/myrecording.cast
" &
RECORD_PID=$!
sleep 3

# === Your recording commands here ===
tmux send-keys -t $SESSION "echo 'Hello World'" Enter
sleep 3

# End recording
kill $RECORD_PID 2>/dev/null || true
wait $RECORD_PID 2>/dev/null || true
tmux kill-session -t $SESSION 2>/dev/null || true

# Trim termination artifacts
LINES=$(wc -l < assets/tmp/myrecording.cast)
head -n $((LINES - 4)) assets/tmp/myrecording.cast > assets/tmp/myrecording_trimmed.cast
mv assets/tmp/myrecording_trimmed.cast assets/tmp/myrecording.cast

# Convert to GIF
agg --theme dracula --font-size $FONT_SIZE assets/tmp/myrecording.cast assets/gifs/myrecording_raw.gif

# Crop edges
ffmpeg -y -i assets/gifs/myrecording_raw.gif \
  -vf "crop=in_w-8:in_h-8:4:4,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  assets/gifs/myrecording.gif 2>/dev/null
rm -f assets/gifs/myrecording_raw.gif assets/tmp/myrecording.cast

echo "Done! Created assets/gifs/myrecording.gif"
```

## Output Files

- **assets/gifs/** - Final GIFs (committed to repo)
- **assets/tmp/** - Intermediate files (gitignored)

## Current GIFs

| Script | Output | Description |
|--------|--------|-------------|
| record-hero.sh | hero.gif | Generation command → split view with template & code |
| record-features.sh | features.gif | Hash-based caching: run twice, second is instant |
| record-syntax.sh | syntax.gif | All control flow patterns ({#if}, {#each}, {#case}) |
| record-watch.sh | watch.gif | Watch mode with live file editing |
| record-cleanup.sh | cleanup.gif | Auto cleanup: delete .lustre, .gleam auto-removed |
