# Tyler's Talent & Toolbox Thunder
## User Manual

**Version:** 1.0.0  
**Date:** 2025-12-31

---

## Table of Contents

1. [Overview](#1-overview)
   - 1.1 [Introduction](#11-introduction)
   - 1.2 [Purpose](#12-purpose)
   - 1.3 [How It Works](#13-how-it-works)

2. [Package Contents](#2-package-contents)
   - 2.1 [Directory Tree](#21-directory-tree)
   - 2.2 [File Descriptions](#22-file-descriptions)
   - 2.3 [Definitions](#23-definitions)

3. [Installation](#3-installation)
   - 3.1 [Requirements](#31-requirements)
   - 3.2 [Setup Steps](#32-setup-steps)
   - 3.3 [Verification](#33-verification)

4. [The Chain](#4-the-chain)
   - 4.1 [What Is The Chain](#41-what-is-the-chain)
   - 4.2 [Stage 1: README to Information](#42-stage-1-readme-to-information)
   - 4.3 [Stage 2: Information to Menu](#43-stage-2-information-to-menu)
   - 4.4 [Stage 3: Menu to Index](#44-stage-3-menu-to-index)
   - 4.5 [The DIFF System](#45-the-diff-system)

5. [Commands](#5-commands)
   - 5.1 [status](#51-status)
   - 5.2 [scan](#52-scan)
   - 5.3 [approve](#53-approve)
   - 5.4 [create-tool](#54-create-tool)
   - 5.5 [run](#55-run)

6. [Creating a Tool](#6-creating-a-tool)
   - 6.1 [The README File](#61-the-readme-file)
   - 6.2 [The Manifest Block](#62-the-manifest-block)
   - 6.3 [Schema Fields](#63-schema-fields)
   - 6.4 [Complete Example](#64-complete-example)

7. [The Menu System](#7-the-menu-system)
   - 7.1 [Master Menu vs Order Form](#71-master-menu-vs-order-form)
   - 7.2 [Using The Menu](#72-using-the-menu)

8. [Running Tools](#8-running-tools)
   - 8.1 [Placing Configs](#81-placing-configs)
   - 8.2 [Execution](#82-execution)
   - 8.3 [Receipts](#83-receipts)

9. [Troubleshooting](#9-troubleshooting)
   - 9.1 [Common Issues](#91-common-issues)
   - 9.2 [Log Files](#92-log-files)

---

## 1. Overview

### 1.1 Introduction

This manual explains how to use Tyler's Talent & Toolbox Thunder, a system for managing reusable tools. The system tracks tools through a chain of files, from creation to execution, logging every change along the way.

The core idea: you write one file (the README), and the system generates everything else automatically.

### 1.2 Purpose

The toolbox serves three purposes:

1. **Tool Management** - Organize tools in a standard structure so they can be found and understood quickly.

2. **Change Tracking** - Every modification flows through a chain of files, creating a log of what changed and when.

3. **Menu Generation** - Automatically build a menu of all available tools with their requirements, so you know what each tool needs before running it.

### 1.3 How It Works

The system uses a three-stage chain. Each stage requires a scan and an approval:

```
README → information.json → menu.json → index.json → log.csv
```

This creates a delay between stages. When you change a README, it takes three scan/approve cycles before that change appears in the final index. This delay is intentional - it gives you time to review changes before they propagate.

---

## 2. Package Contents

### 2.1 Directory Tree

When you unzip the package, you will see this structure:

```
toolbox/
│
├── .cauldron/                    [A]
│   └── toolbox-menu.json
│
├── .outbox/                      [B]
│   └── _receipts/
│
├── log/                          [C]
│   ├── toolbox-menu.json
│   ├── toolbox-index.json
│   └── log.csv
│
├── run.sh                        [D]
├── run.ps1                       [D]
├── run.cmd                       [D]
├── README.md                     [E]
│
└── openai-api-call/              [F]
    ├── openai-api-call-information.json
    ├── openai-api-call-license.txt
    ├── openai-api-call-instructions/
    │   └── openai-api-call-model-readme.md
    └── openai-api-call-examples/
```

### 2.2 File Descriptions

Each lettered section in the tree above serves a specific purpose:

**[A] .cauldron/ - Input Directory**

This is where you place configuration files before running tools. It also contains a copy of the menu that you can use to see what tools are available and what they require.

| File | Purpose |
|------|---------|
| toolbox-menu.json | Copy of the menu for reference and ordering |
| *.request.json | Configuration files you place here for tool runs |

**[B] .outbox/ - Output Directory**

This is where tool outputs appear after a run. The `_receipts/` subdirectory stores records of each run.

| File | Purpose |
|------|---------|
| (artifacts) | Output files created by tools |
| _receipts/*.json | Records of what ran and what was produced |

**[C] log/ - Stable State Directory**

This directory holds the master copies of system files and the change log.

| File | Purpose |
|------|---------|
| toolbox-menu.json | Master menu (source of truth) |
| toolbox-index.json | Stable index (approved snapshot of menu) |
| log.csv | History of all changes (adds, removes, modifications) |

**[D] Runner Scripts**

Three versions of the same script for different environments:

| File | Environment |
|------|-------------|
| run.sh | Linux/Mac (bash) |
| run.ps1 | Windows (PowerShell) |
| run.cmd | Windows (Command Prompt wrapper) |

**[E] README.md**

Documentation for the toolbox itself.

**[F] Tool Directories**

Each tool lives in its own directory. The directory name matches the tool name. Inside each tool directory:

| Item | Purpose |
|------|---------|
| [name]-information.json | Tool data extracted from README |
| [name]-license.txt | License information |
| [name]-instructions/ | Contains the README and any scripts |
| [name]-examples/ | Successful run outputs get copied here |

### 2.3 Definitions

These terms have specific meanings in this system:

| Term | Definition |
|------|------------|
| **Talent** | A tool package. Contains a README, scripts, and generated files. |
| **Toolbox** | The collection of all talents in one directory. |
| **Chain** | The flow of data from README through information, menu, index, to log. |
| **Scan** | The command that moves data one step through the chain. |
| **Pending** | A file waiting for approval (has `.pending` extension). |
| **Approve** | The command that accepts pending files, making them active. |
| **Cauldron** | The input directory where you place configs before running tools. |
| **Outbox** | The output directory where tool results appear. |
| **Menu** | The list of all tools with their requirements. |
| **Index** | The approved snapshot of the menu, used for DIFF comparison. |
| **DIFF** | The comparison between the current menu and the last approved index. |
| **Manifest** | The JSON block inside a README that defines the tool's properties. |

---

## 3. Installation

### 3.1 Requirements

**For Linux/Mac:**
- Bash shell
- Python 3.x (for JSON parsing)

**For Windows:**
- PowerShell 5.1 or later

### 3.2 Setup Steps

1. **Extract the package**
   
   Unzip `toolbox.zip` to your desired location.

2. **Make the script executable** (Linux/Mac only)
   
   ```bash
   chmod +x run.sh
   ```

3. **Verify the installation**
   
   ```bash
   ./run.sh status
   ```
   
   Or on Windows:
   ```powershell
   .\run.ps1 status
   ```

### 3.3 Verification

A successful installation shows output like this:

```
=== TOOLBOX STATUS ===
Root: /path/to/toolbox

Tools: 1
  openai-api-call : ready

No pending files.

Log dir:
  menu:  exists
  index: exists
  log:   exists
```

This tells you:
- The toolbox root directory
- How many tools are installed
- The state of each tool
- Whether any files are waiting for approval
- Whether the log files exist

---

## 4. The Chain

### 4.1 What Is The Chain

The chain is the path data travels from when you create or modify a tool until that change is recorded in the log. It has three stages:

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   README ──scan──> information.json                         │
│                         │                                   │
│                      approve                                │
│                         │                                   │
│                         ▼                                   │
│   information.json ──scan──> menu.json                      │
│                                │                            │
│                             approve                         │
│                                │                            │
│                                ▼                            │
│   menu.json ──scan──> index.json ──DIFF──> log.csv          │
│                            │                                │
│                         approve                             │
│                            │                                │
│                            ▼                                │
│                        COMPLETE                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

Each arrow represents one scan command. Each "approve" represents the approve command. A change takes three scan/approve cycles to fully propagate.

### 4.2 Stage 1: README to Information

**What happens:** The scan command reads the README file, extracts the JSON manifest block, and creates `information.json.pending`.

**Input:** `[tool]/[tool]-instructions/[tool]-model-readme.md`

**Output:** `[tool]/[tool]-information.json.pending`

**Example:**
```
=== SCANNING ===
  my-tool : readme → information.json.pending

Moved 1 item(s). Run 'approve' to apply.
```

After approving, `information.json.pending` becomes `information.json`.

### 4.3 Stage 2: Information to Menu

**What happens:** The scan command reads all `information.json` files from all tools and combines them into a single menu file.

**Input:** All `[tool]/[tool]-information.json` files

**Output:** `log/toolbox-menu.json.pending`

**Example:**
```
=== SCANNING ===
  menu : information.json(s) → toolbox-menu.json.pending

Moved 1 item(s). Run 'approve' to apply.
```

After approving:
- `toolbox-menu.json.pending` becomes `toolbox-menu.json` in the log directory
- A copy is placed in `.cauldron/` for reference

### 4.4 Stage 3: Menu to Index

**What happens:** The scan command compares the menu to the existing index, calculates what changed (the DIFF), creates a new index, and logs the changes.

**Input:** `log/toolbox-menu.json`

**Output:** 
- `log/toolbox-index.json.pending`
- `log/log.csv` (appended)

**Example:**
```
=== SCANNING ===
  index : menu → toolbox-index.json.pending
    added: my-tool

Moved 1 item(s). Run 'approve' to apply.
```

### 4.5 The DIFF System

When Stage 3 runs, it compares the new menu against the old index and reports:

| Change Type | Meaning |
|-------------|---------|
| added | A new tool appeared in the menu |
| removed | A tool was deleted from the toolbox |
| modified | A tool's information.json content changed |

These changes are recorded in `log/log.csv`:

```csv
timestamp_utc,action,added,removed,modified
2025-12-31T10:00:00Z,scan,my-tool,,
2025-12-31T11:00:00Z,scan,,old-tool,
2025-12-31T12:00:00Z,scan,,,updated-tool
```

---

## 5. Commands

### 5.1 status

**Purpose:** Show the current state of the toolbox.

**Usage:**
```bash
./run.sh status
```

**Output explains:**
- Which tools exist and their current state
- Any pending files waiting for approval
- Whether log files exist

**Tool states:**

| State | Meaning |
|-------|---------|
| readme only (needs scan) | Tool has README but no information.json yet |
| info.pending (needs approve) | Scan extracted data, waiting for approval |
| ready | Tool is fully processed and in the menu |
| no readme | Tool directory exists but has no README file |

### 5.2 scan

**Purpose:** Move data one step through the chain.

**Usage:**
```bash
./run.sh scan
```

**What it does:**
1. Checks each tool for a README without an information.json
2. Extracts manifest data and creates `.pending` files
3. If all tools have information.json, builds menu.pending
4. If menu exists, builds index.pending and calculates DIFF

**One step only:** Each scan moves data exactly one step. Run it multiple times to propagate changes through all stages.

### 5.3 approve

**Purpose:** Accept pending files, making them active.

**Usage:**
```bash
# Show pending files without approving
./run.sh approve

# Approve each file individually (prompts for each)
./run.sh approve -PerFile

# Approve all pending files at once
./run.sh approve -Yes
```

**What it does:**
1. Finds all files with `.pending` extension
2. For each pending file:
   - Creates a backup of the existing file (`.bak`)
   - Renames the pending file to remove `.pending`

### 5.4 create-tool

**Purpose:** Create a new tool directory with the standard structure.

**Usage:**
```bash
./run.sh create-tool my-tool-name
```

**What it creates:**
```
my-tool-name/
├── my-tool-name-license.txt
├── my-tool-name-instructions/
│   └── my-tool-name-model-readme.md    (template)
└── my-tool-name-examples/
```

**Next steps after creating:**
1. Edit the README file to fill in the manifest
2. Run scan to extract the manifest
3. Run approve to create information.json
4. Repeat scan/approve to add to menu and index

### 5.5 run

**Purpose:** Execute tools. (Not yet implemented in this version)

**Future functionality:**
- Read an order file specifying which tools to run
- Execute each tool's scripts in sequence
- Collect outputs in .outbox
- Generate receipts
- Copy successful outputs to tool examples directories

---

## 6. Creating a Tool

### 6.1 The README File

Every tool's README file follows the same structure:

```markdown
# tool-name

Description of what this tool does.

## Definitions
- term: definition

## Requirements
- what files must be in .cauldron

## Outputs
- what files appear in .outbox

---

<<<begin-tool-name-manifest-file_1_of_1>>>
{
  ... JSON manifest ...
}
<<<end-tool-name-manifest-file_1_of_1>>>
```

The text above the markers is documentation for humans. The JSON between the markers is data for the system.

### 6.2 The Manifest Block

The manifest must be between these exact markers:

```
<<<begin-TOOLNAME-manifest-file_1_of_1>>>
```
and
```
<<<end-TOOLNAME-manifest-file_1_of_1>>>
```

Replace `TOOLNAME` with your actual tool name (lowercase, hyphens for spaces).

The scan command searches for these markers and extracts the JSON between them.

### 6.3 Schema Fields

The manifest JSON must contain these fields:

| Field | Type | Description |
|-------|------|-------------|
| NAME | string | Tool name (must match directory name) |
| Description | string | What this tool does (100+ words recommended) |
| Requirements | array | Files that must be in .cauldron before running |
| Stacks_with | array | Other tools this one works well with |
| Historical_Runs | array | Auto-populated run history |
| Common_Uses | array | Typical use cases |
| Needs_Improvements | boolean/string | Known issues or enhancement requests |
| Model_Notes | array | Important information for using this tool |
| CLASS | string | Category for grouping similar tools |
| Paired | array | Tools that typically run together with this one |
| Requested_Edits | array | Change requests (logged to requested-edits.log) |

**Requirements array format:**
```json
{
  "name": "config-file.json",
  "path": ".cauldron/config-file.json",
  "type": "json",
  "schema": {
    "field1": "description of field1",
    "field2": "description of field2"
  }
}
```

### 6.4 Complete Example

Here is a complete README for a tool called `document-formatter`:

```markdown
# document-formatter

This tool formats documents according to court filing requirements.

## Definitions
- template: The base document with placeholder fields
- config: JSON file specifying which template and what values to insert

## Requirements
- document-formatter.request.json in .cauldron

## Outputs
- formatted-document.docx in .outbox

---

<<<begin-document-formatter-manifest-file_1_of_1>>>
{
  "NAME": "document-formatter",
  "Description": "Formats legal documents for court filing. Reads a configuration file from .cauldron that specifies the template path and field values. Applies the values to the template and produces a formatted document in .outbox. Supports DOCX format. Validates that all required fields are present before processing. Used for briefs, declarations, and motions.",
  "Requirements": [
    {
      "name": "document-formatter.request.json",
      "path": ".cauldron/document-formatter.request.json",
      "type": "json",
      "schema": {
        "template_path": "string - path to template file",
        "output_name": "string - name for output file",
        "fields": "object - key-value pairs for template fields"
      }
    }
  ],
  "Stacks_with": ["openai-api-call"],
  "Historical_Runs": [],
  "Common_Uses": [
    "Formatting appellate briefs",
    "Creating declarations",
    "Generating cover pages"
  ],
  "Needs_Improvements": false,
  "Model_Notes": [
    "Template must be DOCX format",
    "All placeholder fields use {{field_name}} syntax"
  ],
  "CLASS": "document-processing",
  "Paired": ["openai-api-call"],
  "Requested_Edits": []
}
<<<end-document-formatter-manifest-file_1_of_1>>>
```

---

## 7. The Menu System

### 7.1 Master Menu vs Order Form

The menu exists in two locations:

| Location | Purpose |
|----------|---------|
| `log/toolbox-menu.json` | Master copy. Source of truth. |
| `.cauldron/toolbox-menu.json` | Working copy. Use this to see available tools. |

The master in `log/` only changes through the scan/approve chain. The copy in `.cauldron/` is updated automatically when you approve a new menu.

### 7.2 Using The Menu

Open `.cauldron/toolbox-menu.json` to see all available tools. Each tool entry contains:

```json
{
  "toolname": "openai-api-call",
  "paths": {
    "root": "openai-api-call",
    "instructions": "openai-api-call/openai-api-call-instructions",
    "examples": "openai-api-call/openai-api-call-examples"
  },
  "information": {
    "NAME": "openai-api-call",
    "Description": "...",
    "Requirements": [...],
    ...
  }
}
```

The `Requirements` array tells you exactly what config files you need to place in `.cauldron/` before running that tool.

---

## 8. Running Tools

### 8.1 Placing Configs

Before running a tool, check its Requirements in the menu. Create the required config files in `.cauldron/`.

Example for openai-api-call:
```json
// .cauldron/openai-api-call.request.json
{
  "prompt_id": "pmpt_xxxx",
  "model": "gpt-5.2",
  "reasoning_effort": "xhigh",
  "input": "Your message here"
}
```

### 8.2 Execution

The run command executes tools and collects their outputs. (Implementation details for future versions.)

### 8.3 Receipts

After a successful run, a receipt is created in `.outbox/_receipts/` containing:

| Field | Content |
|-------|---------|
| timestamp_utc | When the run completed |
| artifact | Name of the output file |
| artifact_sha256 | Hash of the output for verification |
| tools_ran | Which tools were executed |
| configs_used | Which config files were read |

Receipts and their artifacts are also copied to each participating tool's `examples/` directory, creating a history of successful runs.

---

## 9. Troubleshooting

### 9.1 Common Issues

**"readme has no valid manifest"**

The scan could not find or parse the JSON manifest in the README. Check that:
- Markers are exactly `<<<begin-TOOLNAME-manifest-file_1_of_1>>>` and `<<<end-...>>>`
- TOOLNAME matches your actual tool name
- JSON is valid (no trailing commas, proper quotes)

**"no readme"**

The tool directory exists but there is no README file. The file must be at:
```
[toolname]/[toolname]-instructions/[toolname]-model-readme.md
```

**"Nothing to move"**

The scan found nothing to do. This happens when:
- All READMEs already have information.json files
- Menu matches all current information.json files
- Index matches the current menu

Run `status` to see the current state.

**Pending files not appearing**

Pending files only appear in specific situations:
- information.json.pending: README exists but information.json does not
- menu.pending: At least one information.json has changed since last menu
- index.pending: Menu has changed since last index

### 9.2 Log Files

**log/log.csv**

Contains one row per scan that detected changes:

```csv
timestamp_utc,action,added,removed,modified
```

Use this to see the history of tool additions, removals, and modifications.

**Backup files (.bak)**

When you approve a pending file, the existing file is backed up with a `.bak` extension. If something goes wrong, you can restore from the backup.

---

## End of Manual
