# Claude Code Instructions: Tyler's Talent & Toolbox Thunder

## Project Overview

You are working on a tool management system called "Tyler's Talent & Toolbox Thunder." This system manages reusable tools (called Talents) through a chain of files that track every change.

**Core Principle:** Models do not edit tool files directly. They only create README files for new tools and drop config files in `.cauldron/` for runs.

---

## Directory Structure

```
toolbox/
├── .cauldron/                    # Input: configs go here, menu copy lives here
├── .outbox/                      # Output: run results appear here
│   └── _receipts/
├── log/                          # Stable state: master menu, index, change log
│   ├── toolbox-menu.json
│   ├── toolbox-index.json
│   └── log.csv
├── run.sh                        # Bash runner
├── run.ps1                       # PowerShell runner
└── [toolname]/                   # Each tool
    ├── [toolname]-information.json
    ├── [toolname]-license.txt
    ├── [toolname]-instructions/
    │   └── [toolname]-model-readme.md
    └── [toolname]-examples/
```

---

## The Chain

Data moves ONE STEP per scan command:

```
Scan 1: README → information.json.pending → approve
Scan 2: information.json → menu.json.pending → approve
Scan 3: menu.json → index.json.pending + DIFF → log.csv → approve
```

Three scan/approve cycles to propagate a change. This delay is intentional for safety.

---

## Rules

### DO NOT

1. **Do not edit scripts** - `run.sh`, `run.ps1`, and any tool scripts are locked
2. **Do not edit existing README files** - Once created, README is absolute truth
3. **Do not edit information.json directly** - It's generated from README by scan
4. **Do not edit files in log/** - These are system-managed
5. **Do not put outputs in .cauldron/** - That's for inputs only
6. **Do not put inputs in .outbox/** - That's for outputs only
7. **Do not skip the chain** - Every change goes through scan/approve
8. **Do not auto-approve** - Wait for Tyler to approve pending files
9. **Do not use mock data** - All content must be real and functional
10. **Do not build before discussing** - Plan first, confirm, then build

### DO

1. **Create new README files** when asked to create a new tool
2. **Create config files** in `.cauldron/` when setting up a run
3. **Run status** to check current state before making changes
4. **Ask questions** if requirements are unclear
5. **Explain what you're about to do** before doing it
6. **Use the exact naming convention** - all lowercase, hyphens for spaces

---

## Creating a New Tool

When Tyler asks for a new tool:

1. **First**, confirm the tool name and purpose
2. **Run** `./run.sh create-tool toolname` to scaffold the directory
3. **Create** the README with a complete manifest block
4. **Tell Tyler** to run scan/approve three times

### README Template

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
  "Requirements": [],
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

| Field | Required Content |
|-------|------------------|
| NAME | Exact match to directory name |
| Description | 100+ words, real content, not placeholder |
| Requirements | Array of objects with name, path, type, schema |
| Model_Notes | Useful notes only, no filler |

---

## Commands Reference

```bash
./run.sh status        # Check current state
./run.sh scan          # Move data one step through chain
./run.sh approve -Yes  # Approve all pending files
./run.sh approve -PerFile  # Approve each file individually
./run.sh create-tool name  # Scaffold new tool directory
```

On Windows use `.\run.ps1` instead.

---

## Communication Style

1. **State what you see** - "I see 2 tools, one has pending files"
2. **State what you plan to do** - "I will create the README for new-tool"
3. **Wait for confirmation** on significant changes
4. **Don't lecture** - Tyler knows the system, just execute
5. **Ask one question at a time** if clarification needed
6. **Be direct** - No unnecessary preamble

---

## Common Tasks

### "Create a tool for X"

1. Confirm: "Creating tool named `x-tool`, correct?"
2. Run: `./run.sh create-tool x-tool`
3. Write complete README to `x-tool/x-tool-instructions/x-tool-model-readme.md`
4. Report: "Tool scaffolded. Run `./run.sh scan` then `./run.sh approve -Yes` three times to add to menu."

### "Check the toolbox status"

1. Run: `./run.sh status`
2. Report what you see

### "Add this tool to the menu"

1. Run: `./run.sh scan`
2. Report what moved
3. Tell Tyler to approve if there are pending files

### "What tools are available?"

1. Read: `.cauldron/toolbox-menu.json`
2. List tool names and brief descriptions

### "Set up a run for tool X"

1. Read the tool's Requirements from the menu
2. Create the required config file in `.cauldron/`
3. Report: "Config placed. Ready to run."

---

## File Naming

All lowercase. Hyphens for spaces. Tool name must match directory name.

```
toolname/
├── toolname-information.json
├── toolname-license.txt
├── toolname-instructions/
│   └── toolname-model-readme.md
└── toolname-examples/
```

---

## Error Recovery

If something breaks:

1. **Check status first** - `./run.sh status`
2. **Look at pending files** - They show what's waiting
3. **Check log/log.csv** - Shows recent changes
4. **Backup files exist** - `.bak` extension, can restore if needed
5. **Ask Tyler** before attempting fixes

---

## Tyler's Preferences

- No mock data, ever
- No piecemeal delivery - complete solutions
- No changing working code to fix something else
- No guessing - ask if unsure
- Plan before building
- Direct communication, no lectures
- Accessibility: Tyler uses voice-to-text and screen reader

---

## OpenAI API Tool

The included `openai-api-call` tool calls stored prompts. Config format:

```json
{
  "prompt_id": "pmpt_xxxx",
  "version": "4",
  "model": "gpt-5.2",
  "reasoning_effort": "xhigh",
  "input": "message"
}
```

- Use `gpt-5.2` with `xhigh`, not Pro (too expensive)
- API key from environment variable `OPENAI_API_KEY` only
- Never log or write the API key anywhere
