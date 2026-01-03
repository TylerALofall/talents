#!/bin/bash
# Tyler's Talent & Toolbox Thunder - Bash version for testing
# THE CHAIN (one move per scan):
# Scan 1: readme → information.json.pending
# Scan 2: information.json → log/toolbox-menu.json.pending  
# Scan 3: menu → log/toolbox-index.json.pending + DIFF → log.csv

set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
CAULDRON="$ROOT/.cauldron"
OUTBOX="$ROOT/.outbox"
LOGDIR="$ROOT/log"
PENDING=".pending"
BACKUP=".bak"

# Ensure dirs
mkdir -p "$CAULDRON" "$OUTBOX/_receipts" "$LOGDIR"

# Get all tool directories
get_tools() {
    find "$ROOT" -maxdepth 1 -type d ! -name ".cauldron" ! -name ".outbox" ! -name "log" ! -name ".*" ! -path "$ROOT" -printf "%f\n" 2>/dev/null | sort
}

# Extract JSON from readme markers
extract_manifest() {
    local file="$1"
    local tool="$2"
    # Use grep and sed to extract between markers
    sed -n "/<<<begin-${tool}-manifest-file_/,/<<<end-${tool}-manifest-file_/p" "$file" | \
        grep -v "<<<" | tr -d '\r'
}

# ============================================================================
# STATUS
# ============================================================================
cmd_status() {
    echo "=== TOOLBOX STATUS ==="
    echo "Root: $ROOT"
    echo ""
    
    tools=$(get_tools)
    count=$(echo "$tools" | grep -c . || echo 0)
    echo "Tools: $count"
    
    for t in $tools; do
        name=$(echo "$t" | tr '[:upper:]' '[:lower:]')
        readme="$ROOT/$t/$name-instructions/$name-model-readme.md"
        info="$ROOT/$t/$name-information.json"
        info_pending="$info$PENDING"
        
        if [ -f "$info_pending" ]; then
            state="info.pending (needs approve)"
        elif [ -f "$info" ]; then
            state="ready"
        elif [ -f "$readme" ]; then
            state="readme only (needs scan)"
        else
            state="no readme"
        fi
        
        echo "  $name : $state"
    done
    
    echo ""
    pending_count=$(find "$ROOT" -name "*$PENDING" -type f 2>/dev/null | wc -l)
    if [ "$pending_count" -gt 0 ]; then
        echo "Pending files: $pending_count"
        find "$ROOT" -name "*$PENDING" -type f 2>/dev/null | while read f; do
            echo "  ${f#$ROOT/}"
        done
    else
        echo "No pending files."
    fi
    
    echo ""
    echo "Log dir:"
    [ -f "$LOGDIR/toolbox-menu.json" ] && echo "  menu:  exists" || echo "  menu:  not yet"
    [ -f "$LOGDIR/toolbox-index.json" ] && echo "  index: exists" || echo "  index: not yet"
    [ -f "$LOGDIR/log.csv" ] && echo "  log:   exists" || echo "  log:   not yet"
}

# ============================================================================
# SCAN
# ============================================================================
cmd_scan() {
    echo "=== SCANNING ==="
    moved=0
    
    tools=$(get_tools)
    
    # STAGE 1: readme → information.json.pending
    for t in $tools; do
        name=$(echo "$t" | tr '[:upper:]' '[:lower:]')
        readme="$ROOT/$t/$name-instructions/$name-model-readme.md"
        info="$ROOT/$t/$name-information.json"
        info_pending="$info$PENDING"
        
        if [ -f "$readme" ] && [ ! -f "$info" ] && [ ! -f "$info_pending" ]; then
            manifest=$(extract_manifest "$readme" "$name")
            if [ -n "$manifest" ] && echo "$manifest" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
                echo "$manifest" | python3 -c "import sys,json; json.dump(json.load(sys.stdin), sys.stdout, indent=2)" > "$info_pending"
                echo "  $name : readme → information.json.pending"
                moved=$((moved + 1))
            else
                echo "  $name : readme has no valid manifest"
            fi
        fi
    done
    
    # STAGE 2: Build menu from approved information.json files
    menu_master="$LOGDIR/toolbox-menu.json"
    menu_pending="$menu_master$PENDING"
    
    # Build menu JSON
    menu_tools=""
    for t in $tools; do
        name=$(echo "$t" | tr '[:upper:]' '[:lower:]')
        info="$ROOT/$t/$name-information.json"
        
        if [ -f "$info" ]; then
            tool_json=$(python3 -c "
import json
with open('$info') as f:
    data = json.load(f)
tool = {
    'toolname': '$name',
    'paths': {
        'root': '$name',
        'instructions': '$name/$name-instructions',
        'examples': '$name/$name-examples'
    },
    'information': data
}
print(json.dumps(tool))
" 2>/dev/null)
            if [ -n "$tool_json" ]; then
                [ -n "$menu_tools" ] && menu_tools="$menu_tools,"
                menu_tools="$menu_tools$tool_json"
            fi
        fi
    done
    
    if [ -n "$menu_tools" ]; then
        new_menu="{\"_generated_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"tools\":[$menu_tools]}"
        
        # Compare with current menu
        if [ -f "$menu_master" ]; then
            old_tools=$(python3 -c "import json; print(json.dumps(json.load(open('$menu_master'))['tools'], sort_keys=True))" 2>/dev/null || echo "")
        else
            old_tools=""
        fi
        new_tools=$(echo "$new_menu" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin)['tools'], sort_keys=True))" 2>/dev/null || echo "")
        
        if [ "$old_tools" != "$new_tools" ] && [ ! -f "$menu_pending" ]; then
            echo "$new_menu" | python3 -c "import sys,json; json.dump(json.load(sys.stdin), sys.stdout, indent=2)" > "$menu_pending"
            echo "  menu : information.json(s) → toolbox-menu.json.pending"
            moved=$((moved + 1))
            
            # Copy to .cauldron
            cp "$menu_pending" "$CAULDRON/toolbox-menu.json"
        fi
    fi
    
    # STAGE 3: Menu → Index + DIFF
    index_master="$LOGDIR/toolbox-index.json"
    index_pending="$index_master$PENDING"
    
    if [ -f "$menu_master" ] && [ ! -f "$index_pending" ]; then
        # Get tool names from menu and index
        menu_names=$(python3 -c "import json; print(' '.join([t['toolname'] for t in json.load(open('$menu_master'))['tools']]))" 2>/dev/null || echo "")
        
        if [ -f "$index_master" ]; then
            index_names=$(python3 -c "import json; print(' '.join([t['toolname'] for t in json.load(open('$index_master'))['tools']]))" 2>/dev/null || echo "")
        else
            index_names=""
        fi
        
        # Simple diff
        added=""
        for n in $menu_names; do
            echo "$index_names" | grep -qw "$n" || added="$added $n"
        done
        
        removed=""
        for n in $index_names; do
            echo "$menu_names" | grep -qw "$n" || removed="$removed $n"
        done
        
        if [ -n "$added" ] || [ -n "$removed" ] || [ ! -f "$index_master" ]; then
            # Create new index
            python3 -c "
import json
with open('$menu_master') as f:
    menu = json.load(f)
index = {
    '_generated_at': '$(date -u +%Y-%m-%dT%H:%M:%SZ)',
    '_tool_count': len(menu['tools']),
    'tools': menu['tools']
}
print(json.dumps(index, indent=2))
" > "$index_pending"
            
            echo "  index : menu → toolbox-index.json.pending"
            [ -n "$added" ] && echo "    added:$added"
            [ -n "$removed" ] && echo "    removed:$removed"
            moved=$((moved + 1))
            
            # Log to CSV
            log_csv="$LOGDIR/log.csv"
            if [ ! -f "$log_csv" ]; then
                echo "timestamp_utc,action,added,removed,modified" > "$log_csv"
            fi
            echo "$(date -u +%Y-%m-%dT%H:%M:%SZ),scan,${added# },${removed# }," >> "$log_csv"
        fi
    fi
    
    echo ""
    if [ "$moved" -eq 0 ]; then
        echo "Nothing to move. Run 'approve' if there are pending files."
    else
        echo "Moved $moved item(s). Run 'approve' to apply."
    fi
}

# ============================================================================
# APPROVE
# ============================================================================
cmd_approve() {
    pending_files=$(find "$ROOT" -name "*$PENDING" -type f 2>/dev/null)
    
    if [ -z "$pending_files" ]; then
        echo "No pending files."
        return
    fi
    
    echo "=== APPROVE ==="
    
    for p in $pending_files; do
        rel="${p#$ROOT/}"
        target="${p%$PENDING}"
        
        if [ "$1" = "-Yes" ]; then
            [ -f "$target" ] && cp "$target" "$target$BACKUP"
            mv "$p" "$target"
            echo "  Approved: $rel"
        elif [ "$1" = "-PerFile" ]; then
            read -p "Approve $rel ? (y/n) " answer
            if [ "$answer" = "y" ]; then
                [ -f "$target" ] && cp "$target" "$target$BACKUP"
                mv "$p" "$target"
                echo "  Approved: $rel"
            fi
        else
            echo "  $rel"
        fi
    done
    
    if [ "$1" != "-Yes" ] && [ "$1" != "-PerFile" ]; then
        echo ""
        echo "Use -Yes to approve all, or -PerFile to approve each."
    fi
}

# ============================================================================
# CREATE-TOOL
# ============================================================================
cmd_create_tool() {
    name="$1"
    if [ -z "$name" ]; then
        read -p "Tool name (lowercase): " name
    fi
    
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    tool_dir="$ROOT/$name"
    
    if [ -d "$tool_dir" ]; then
        echo "Already exists: $name"
        return 1
    fi
    
    echo "Creating: $name"
    
    mkdir -p "$tool_dir/$name-instructions"
    mkdir -p "$tool_dir/$name-examples"
    
    # License
    cat > "$tool_dir/$name-license.txt" << EOF
$name
License: MIT
Created: $(date +%Y-%m-%d)
EOF
    
    # README template
    cat > "$tool_dir/$name-instructions/$name-model-readme.md" << EOF
# $name

ABSOLUTE TRUTH. Models do not edit this file.

## Definitions
- (your terms here)

## Requirements
- (what goes in .cauldron)

## Outputs
- (what appears in .outbox)

---

<<<begin-$name-manifest-file_1_of_1>>>
{
  "NAME": "$name",
  "Description": "WRITE 100+ WORDS describing what this tool does",
  "Requirements": [],
  "Stacks_with": [],
  "Historical_Runs": [],
  "Common_Uses": [],
  "Needs_Improvements": false,
  "Model_Notes": [],
  "CLASS": "uncategorized",
  "Paired": [],
  "Requested_Edits": []
}
<<<end-$name-manifest-file_1_of_1>>>
EOF
    
    echo "Created: $name"
    echo ""
    echo "Next:"
    echo "  1. Edit $name/$name-instructions/$name-model-readme.md"
    echo "  2. ./run.sh scan"
    echo "  3. ./run.sh approve -PerFile"
}

# ============================================================================
# MAIN
# ============================================================================
case "$1" in
    status)      cmd_status ;;
    scan)        cmd_scan ;;
    approve)     cmd_approve "$2" ;;
    create-tool) cmd_create_tool "$2" ;;
    run)         echo "Run not implemented yet." ;;
    *)           echo "Usage: $0 {status|scan|approve|create-tool|run}" ;;
esac
