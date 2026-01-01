# Tyler's Talent & Toolbox Thunder

## Quick Start

```bash
# Check what's there
./run.sh status

# Scan (moves one step)
./run.sh scan

# Approve pending files
./run.sh approve -Yes      # approve all
./run.sh approve -PerFile  # approve each

# Create new tool
./run.sh create-tool my-new-tool
```

Windows:
```powershell
.\run.ps1 status
.\run.ps1 scan
.\run.ps1 approve -Yes
.\run.ps1 create-tool -Toolname my-new-tool
```

## The Chain

Each scan moves ONE step:

```
Scan 1: readme → information.json.pending → approve
Scan 2: information.json → menu.pending → approve  
Scan 3: menu → index.pending → DIFF → log.csv → approve
```

Three scans to go from readme to index. Safety delay built in.

## Structure

```
toolbox/
├── .cauldron/           # Menu copy for ordering, configs go here
├── .outbox/             # Run outputs
├── log/
│   ├── toolbox-menu.json    # Master menu
│   ├── toolbox-index.json   # Stable index
│   └── log.csv              # DIFF log
└── [toolname]/
    ├── [toolname]-information.json
    ├── [toolname]-license.txt
    ├── [toolname]-instructions/
    │   └── [toolname]-model-readme.md   # ABSOLUTE TRUTH
    └── [toolname]-examples/
```

## Creating a Tool

1. `./run.sh create-tool my-tool`
2. Edit `my-tool/my-tool-instructions/my-tool-model-readme.md`
3. Fill out the manifest JSON between the markers
4. Run scan/approve three times to propagate

The readme is the ONLY file a model produces. Everything else auto-generates.
