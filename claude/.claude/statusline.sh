#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values
model=$(echo "$input" | jq -r '.model.display_name')
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Shorten model name (e.g., "Claude Opus 4.5" -> "Opus 4.5")
short_model=$(echo "$model" | sed 's/^Claude //')

# Get git branch
git_branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    git_branch=$(git -C "$cwd" -c core.fileMode=false rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# Calculate context window percentage
context_pct="0%"
usage=$(echo "$input" | jq '.context_window.current_usage // empty')
if [ -n "$usage" ]; then
    current=$(echo "$input" | jq '[.context_window.current_usage.input_tokens, .context_window.current_usage.cache_creation_input_tokens, .context_window.current_usage.cache_read_input_tokens] | map(. // 0) | add')
    size=$(echo "$input" | jq '.context_window.context_window_size // 1')
    if [ "$size" != "0" ] && [ "$size" != "null" ]; then
        pct=$((current * 100 / size))
        context_pct="${pct}%"
    fi
fi

# Define ANSI color codes
PURPLE=$'\e[35m'
GREY=$'\e[90m'
GREEN=$'\e[32m'
RESET=$'\e[0m'

# Build statusline: "Opus 4.5 [18% context]  ·  branch-name"
output="${PURPLE}${short_model}${RESET} ${GREY}[${context_pct} context]${RESET}"
if [ -n "$git_branch" ]; then
    output="${output}  ·  ${GREEN}${git_branch}${RESET}"
fi

echo "$output"
