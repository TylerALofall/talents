# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tyler's Talent & Toolbox Thunder is a tool management system that organizes reusable tools through a chain-based workflow. The system enforces strict separation between input (`.cauldron/`), output (`.outbox/`), and stable state (`log/`).

**Core Principle:** Models create README files for new tools and drop config files in `.cauldron/` for runs. Models do NOT edit tool files, scripts, or system-managed files directly.

## Commands

### Basic Commands

```bash
# Check status
./run.sh status
.\run.ps1 status

# Scan (moves data one step through the chain)
./run.sh scan
.\run.ps1 scan

# Approve pending files
./run.sh approve -Yes          # approve all
./run.sh approve -PerFile      # approve each individually
.\run.ps1 approve -Yes
.\run.ps1 approve -PerFile

# Create new tool
./run.sh create-tool toolname
.\run.ps1 create-tool -Toolname toolname
```

## The Chain Architecture

Data moves ONE STEP per scan command through a three-stage chain:

```
Stage 1: README → information.json.pending → approve
Stage 2: information.json → log/toolbox-menu.json.pending → approve
Stage 3: menu.json → log/toolbox-index.json.pending + DIFF → log.csv → approve
```

Three scan/approve cycles are required to propagate a change from README to index. This delay is intentional for safety and review.

## Directory Structure

```
toolbox/
├── .cauldron/                      # INPUT: configs for runs, menu copy for ordering
├── .outbox/                        # OUTPUT: run results, receipts
│   └── _receipts/
├── log/                            # STABLE STATE: master menu, index, change log
│   ├── toolbox-menu.json          # Generated from all information.json files
│   ├── toolbox-index.json         # Final index with DIFF tracking
│   └── log.csv                    # Change log
├── run.sh / run.ps1               # Cross-platform runners (DO NOT EDIT)
└── [toolname]/                    # Each tool directory
    ├── [toolname]-information.json          # Generated from README manifest
    ├── [toolname]-license.txt               # Auto-generated
    ├── [toolname]-instructions/
    │   └── [toolname]-model-readme.md      # ABSOLUTE TRUTH - only file models create
    └── [toolname]-examples/
```

## File Naming Convention

All lowercase, hyphens for spaces. Tool name must match directory name exactly.

## Creating a New Tool

When creating a new tool:

1. Run: `./run.sh create-tool toolname` to scaffold the directory
2. Edit the README file at `toolname/toolname-instructions/toolname-model-readme.md`
3. Fill out the manifest block completely (see template below)
4. Run scan/approve cycle three times to propagate to menu and index

### README Template Structure

```markdown
# toolname

Brief description.

## Definitions
- term: definition

## Requirements
- what goes in .cauldron

## Outputs
- what appears in .outbox

---

<<<begin-toolname-manifest-file_1_of_1>>>
{
  "NAME": "toolname",
  "Description": "100+ words describing what this tool does",
  "Requirements": [
    {
      "name": "filename",
      "path": ".cauldron/filename",
      "type": "json",
      "schema": {
        "field": "description"
      }
    }
  ],
  "Stacks_with": [],
  "Historical_Runs": [],
  "Common_Uses": [],
  "Needs_Improvements": false,
  "Model_Notes": [],
  "CLASS": "category",
  "Paired": [],
  "Requested_Edits": []
}
<<<end-toolname-manifest-file_1_of_1>>>
```

### Manifest Field Requirements

- **NAME**: Must exactly match directory name
- **Description**: Minimum 100 words, real content (not placeholder text)
- **Requirements**: Array of objects with name, path, type, and schema
- **Model_Notes**: Only useful notes, no filler

## Critical Rules

### DO NOT

1. Edit `run.sh`, `run.ps1`, or any tool scripts
2. Edit existing README files (they are absolute truth)
3. Edit `information.json` files directly (generated from README)
4. Edit files in `log/` (system-managed)
5. Put outputs in `.cauldron/` (inputs only)
6. Put inputs in `.outbox/` (outputs only)
7. Skip the chain (every change goes through scan/approve)
8. Auto-approve pending files (wait for Tyler)
9. Use mock or placeholder data (all content must be real)

### DO

1. Create README files when creating new tools
2. Create config files in `.cauldron/` for runs
3. Run `status` before making changes
4. Ask questions if requirements are unclear
5. Use exact naming conventions (lowercase, hyphens)

## OpenAI API Tool

The `openai-api-call` tool calls stored prompts via OpenAI Responses API.

Config format in `.cauldron/openai-api-call.request.json`:
```json
{
  "prompt_id": "pmpt_xxxx",
  "version": "4",
  "model": "gpt-5.2",
  "reasoning_effort": "xhigh",
  "input": "additional message"
}
```

- Use `gpt-5.2` with `xhigh` reasoning effort (not Pro - too expensive)
- API key from `OPENAI_API_KEY` environment variable only
- Never log or write the API key

## Manifest Block Extraction

The scan command extracts JSON between these markers:
```
<<<begin-toolname-manifest-file_1_of_1>>>
{...json...}
<<<end-toolname-manifest-file_1_of_1>>>
```

The tool name in the markers must match the directory name exactly.

## Accessibility Notes

Tyler uses voice-to-text and screen reader. Communication should be:
- Direct and concise
- No unnecessary preamble or lectures
- State what you see, state what you plan to do
- Ask one question at a time if clarification needed
