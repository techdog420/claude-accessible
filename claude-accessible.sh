#!/bin/bash
# claude-accessible.sh - Screen reader friendly Claude Code wrapper
# Usage: ./claude-accessible.sh "your prompt here"
#        ./claude-accessible.sh --continue "follow-up prompt"
#        ./claude-accessible.sh --new "start fresh conversation"
#        ./claude-accessible.sh --file prompt.txt
#        cat prompt.txt | ./claude-accessible.sh

SESSION_FILE=".claude-session"
HISTORY_FILE="claude-history.txt"

# Auto-approve these tools to avoid interactive prompts
ALLOWED_TOOLS="Read,Write,Edit,Bash,Grep,Glob,Task"

# Check if this is a continuation or new conversation
FILE_INPUT=""
OPEN_EDITOR=0
if [[ "$1" == "--continue" || "$1" == "-c" ]]; then
    shift
    MODE="continue"
elif [[ "$1" == "--new" || "$1" == "-n" ]]; then
    shift
    MODE="new"
    rm -f "$SESSION_FILE"
elif [[ "$1" == "--file" || "$1" == "-f" ]]; then
    shift
    FILE_INPUT="$1"
    shift
    MODE="auto"
elif [[ "$1" == "--editor" || "$1" == "-e" ]]; then
    OPEN_EDITOR=1
    shift
    MODE="auto"
else
    MODE="auto"
fi

PROMPT="$*"

# Check for file input
if [[ -n "$FILE_INPUT" ]]; then
    if [[ ! -f "$FILE_INPUT" ]]; then
        echo "Error: File not found: $FILE_INPUT"
        exit 1
    fi
    PROMPT=$(cat "$FILE_INPUT")
fi

# Check for stdin input (if no prompt and no file specified)
if [[ -z "$PROMPT" && ! -t 0 ]]; then
    PROMPT=$(cat)
fi

if [[ -z "$PROMPT" ]]; then
    echo "Error: Please provide a prompt"
    echo "Usage: $0 \"your prompt here\""
    echo "       $0 --continue \"follow-up prompt\""
    echo "       $0 --new \"start fresh conversation\""
    echo "       $0 --file prompt.txt"
    echo "       $0 --editor \"prompt to edit in default editor\""
    echo "       cat prompt.txt | $0"
    exit 1
fi

# Log the prompt
echo "========================================" >> "$HISTORY_FILE"
echo "PROMPT: $PROMPT" >> "$HISTORY_FILE"
echo "TIME: $(date)" >> "$HISTORY_FILE"
echo "========================================" >> "$HISTORY_FILE"

# Check if we have an existing session
if [[ -f "$SESSION_FILE" && "$MODE" != "new" ]]; then
    SESSION_ID=$(cat "$SESSION_FILE")
    echo "Continuing session: $SESSION_ID"

    # Continue the conversation
    echo "RESPONSE:" >> "$HISTORY_FILE"
    claude -p "$PROMPT" \
        --resume "$SESSION_ID" \
        --allowedTools "$ALLOWED_TOOLS" \
        | tee -a "$HISTORY_FILE"
else
    echo "Starting new conversation..."

    # Start new conversation with JSON output to capture session ID
    JSON_OUTPUT=$(claude -p "$PROMPT" \
        --allowedTools "$ALLOWED_TOOLS" \
        --output-format json \
        2>&1)

    # Extract and display the result text
    echo "RESPONSE:" >> "$HISTORY_FILE"
    echo "$JSON_OUTPUT" | grep -o '"result":"[^"]*"' | sed 's/"result":"//;s/"$//' | sed 's/\\n/\n/g' | tee -a "$HISTORY_FILE"

    # Extract session ID from JSON
    NEW_SESSION_ID=$(echo "$JSON_OUTPUT" | grep -o '"session_id":"[^"]*"' | sed 's/"session_id":"//;s/"$//')

    if [[ -n "$NEW_SESSION_ID" ]]; then
        echo "$NEW_SESSION_ID" > "$SESSION_FILE"
        echo ""
        echo "Session ID saved: $NEW_SESSION_ID"
        echo "Use --continue flag for follow-up questions"
    else
        echo ""
        echo "Warning: Could not extract session ID from output"
    fi
fi

echo "" >> "$HISTORY_FILE"

# Open in editor if requested
if [[ "$OPEN_EDITOR" == "1" ]]; then
    OUTPUT_FILE="claude-output-$$.txt"
    echo ""
    echo "Opening output in default editor: $OUTPUT_FILE"

    # Extract the last response from history file
    # Get line number of last RESPONSE: marker and extract from there to end
    LAST_LINE=$(grep -n "^RESPONSE:" "$HISTORY_FILE" | tail -1 | cut -d: -f1)
    if [[ -n "$LAST_LINE" ]]; then
        tail -n +$LAST_LINE "$HISTORY_FILE" > "$OUTPUT_FILE"
    else
        echo "No RESPONSE: marker found in history file" > "$OUTPUT_FILE"
    fi

    # Open in default editor (uses xdg-open on Linux, open on Mac)
    if command -v xdg-open &> /dev/null; then
        xdg-open "$OUTPUT_FILE" &
    elif command -v open &> /dev/null; then
        open "$OUTPUT_FILE"
    else
        echo "Warning: Could not find default editor command (xdg-open or open)"
        echo "Output saved to: $OUTPUT_FILE"
    fi
fi
