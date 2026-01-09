# Claude Code Accessible Wrapper

Screen reader friendly wrapper scripts for [Claude Code](https://claude.ai/code), designed to make AI-assisted development accessible to blind and visually impaired developers.

## Problem Statement

The standard Claude Code CLI tool uses interactive terminal prompts that can crash or freeze screen readers. These wrapper scripts solve this issue by:
- Auto-approving safe tool usage to eliminate interactive prompts
- Maintaining linear, screen-reader-friendly output
- Logging all interactions to a reviewable history file
- Supporting alternative input methods (files, stdin)

## Features

- **Auto-approval**: Pre-approves safe tools (Read, Write, Edit, Bash, Grep, Glob, Task) to avoid prompts
- **Session management**: Automatic conversation continuity with `.claude-session` file
- **History logging**: Complete interaction log in `claude-history.txt` with timestamps
- **Multiple input methods**:
  - Command-line arguments (standard)
  - File input (`--file` flag)
  - Standard input redirection (pipe support)
- **Editor integration**: Option to open responses in your default editor (`--editor` flag)
- **Cross-platform**: Identical functionality on Windows (batch) and Linux/Mac (bash)

## Installation

1. Download the appropriate script for your platform:
   - Windows: `claude-accessible.bat`
   - Linux/Mac: `claude-accessible.sh`

2. Ensure the Claude Code CLI is installed and available in your PATH:
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```

3. Make the script executable (Linux/Mac only):
   ```bash
   chmod +x claude-accessible.sh
   ```

## Usage

### Basic Usage

**Windows:**
```batch
claude-accessible.bat "your prompt here"
```

**Linux/Mac:**
```bash
./claude-accessible.sh "your prompt here"
```

### Continuing a Conversation

```batch
# Explicit continuation
claude-accessible.bat --continue "follow-up question"
claude-accessible.bat -c "follow-up question"

# Auto-continuation (default if session exists)
claude-accessible.bat "follow-up question"
```

### Starting a Fresh Conversation

```batch
claude-accessible.bat --new "start fresh"
claude-accessible.bat -n "start fresh"
```

### Using File Input

```batch
# Using --file flag
claude-accessible.bat --file prompt.txt

# Using stdin redirection
type prompt.txt | claude-accessible.bat        # Windows
cat prompt.txt | ./claude-accessible.sh        # Linux/Mac
```

### Opening Output in Editor

```batch
claude-accessible.bat --editor "your prompt"
claude-accessible.bat -e "your prompt"
```

This saves the response to a temporary file and opens it in your default editor (Notepad on Windows, or xdg-open/open on Linux/Mac).

## Configuration

### Customizing Auto-Approved Tools

Edit the `ALLOWED_TOOLS` variable in the script:

**Windows (claude-accessible.bat):**
```batch
set ALLOWED_TOOLS=Read,Write,Edit,Bash,Grep,Glob,Task
```

**Linux/Mac (claude-accessible.sh):**
```bash
ALLOWED_TOOLS="Read,Write,Edit,Bash,Grep,Glob,Task"
```

## Files Created

- `.claude-session` - Stores the current session ID for conversation continuity
- `claude-history.txt` - Complete log of all prompts and responses with timestamps
- `claude-output-*.txt` - Temporary files when using `--editor` flag

## Accessibility Notes

These scripts are specifically designed for screen reader users:
- All output is linear and sequential (no cursor movement or interactive elements)
- History file can be reviewed independently at any time
- No visual-only indicators (all information is text-based)
- Compatible with JAWS, NVDA, VoiceOver, and other screen readers

## Contributing

Contributions are welcome! Please ensure that any changes maintain the accessibility features:
- No interactive prompts
- All output must be loggable
- Maintain session persistence
- Test with screen readers when possible

## License

MIT License - see LICENSE file for details

## Support

For issues, questions, or feature requests, please open an issue on GitHub.

## Acknowledgments

Built to support the blind developer community in using AI-assisted development tools effectively.
