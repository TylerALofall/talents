#!/bin/bash
# LEGAL FACT-FINDING CHAMPIONSHIP
# Main game controller - NO PYTHON, NO SUBPROCESSES

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Game directories
GAME_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$GAME_DIR/config"
STATE_DIR="$GAME_DIR/state"
AGENTS_DIR="$GAME_DIR/agents"
LIBRARY_DIR="$GAME_DIR/library"
RECORDS_DIR="$GAME_DIR/records"

# ============================================
# INITIALIZATION
# ============================================

init_game() {
    echo -e "${CYAN}Initializing Legal Fact-Finding Championship...${NC}"

    # Create directories if they don't exist
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$STATE_DIR"
    mkdir -p "$AGENTS_DIR/agent1"
    mkdir -p "$AGENTS_DIR/agent2"
    mkdir -p "$AGENTS_DIR/agent3"
    mkdir -p "$LIBRARY_DIR"
    mkdir -p "$RECORDS_DIR"

    # Initialize state files if they don't exist
    if [ ! -f "$STATE_DIR/current_turn.txt" ]; then
        echo "1" > "$STATE_DIR/current_turn.txt"
    fi

    if [ ! -f "$STATE_DIR/current_round.txt" ]; then
        echo "1" > "$STATE_DIR/current_round.txt"
    fi

    # Initialize agents.json if it doesn't exist
    if [ ! -f "$CONFIG_DIR/agents.json" ]; then
        cat > "$CONFIG_DIR/agents.json" << 'EOF'
{
  "agents": [
    {"id": 1, "name": "QWEN3", "custom_name": "", "persona": "", "score": 0, "facts_found": 0},
    {"id": 2, "name": "DOODLES", "custom_name": "", "persona": "", "score": 0, "facts_found": 0},
    {"id": 3, "name": "TURBO", "custom_name": "", "persona": "", "score": 0, "facts_found": 0}
  ]
}
EOF
    fi

    # Initialize scores.json if it doesn't exist
    if [ ! -f "$STATE_DIR/scores.json" ]; then
        cat > "$STATE_DIR/scores.json" << 'EOF'
{
  "round": 1,
  "phase": "EXTRACTION",
  "scores": {
    "agent1": {"total": 0, "facts": 0, "evidence": 0},
    "agent2": {"total": 0, "facts": 0, "evidence": 0},
    "agent3": {"total": 0, "facts": 0, "evidence": 0}
  }
}
EOF
    fi

    # Initialize message board if it doesn't exist
    if [ ! -f "$STATE_DIR/message_board.json" ]; then
        echo '{"messages": []}' > "$STATE_DIR/message_board.json"
    fi

    # Initialize agent facts files
    for i in 1 2 3; do
        if [ ! -f "$AGENTS_DIR/agent$i/facts.json" ]; then
            echo '{"events": []}' > "$AGENTS_DIR/agent$i/facts.json"
        fi
        if [ ! -f "$AGENTS_DIR/agent$i/evidence.json" ]; then
            echo '{"evidence": []}' > "$AGENTS_DIR/agent$i/evidence.json"
        fi
        if [ ! -f "$AGENTS_DIR/agent$i/notes.txt" ]; then
            touch "$AGENTS_DIR/agent$i/notes.txt"
        fi
    done

    # Initialize session log
    if [ ! -f "$RECORDS_DIR/session_log.txt" ]; then
        echo "=== LEGAL FACT-FINDING CHAMPIONSHIP ===" > "$RECORDS_DIR/session_log.txt"
        echo "Started: $(date)" >> "$RECORDS_DIR/session_log.txt"
        echo "" >> "$RECORDS_DIR/session_log.txt"
    fi

    echo -e "${GREEN}Game initialized!${NC}"
}

# ============================================
# DISPLAY FUNCTIONS
# ============================================

show_header() {
    local agent_num=$1
    local agent_name=$(get_agent_name $agent_num)
    local round=$(cat "$STATE_DIR/current_round.txt")

    clear
    echo -e "${YELLOW}************************************************************${NC}"
    echo -e "${YELLOW}*     LEGAL FACT-FINDING CHAMPIONSHIP - ROUND $round           *${NC}"
    echo -e "${YELLOW}************************************************************${NC}"
    echo ""
    echo -e "${GREEN}YOUR TURN: $agent_name${NC}"
    echo ""
}

show_commands() {
    echo -e "${CYAN}AVAILABLE COMMANDS:${NC}"
    echo "  /commands        - Show this list"
    echo "  /library         - List available documents"
    echo "  /scoreboard      - View current standings"
    echo "  /record_fact     - Submit a new fact"
    echo "  /record_link     - Link evidence to a fact"
    echo "  /record_show     - View your current facts"
    echo "  /notes           - View/edit personal notepad"
    echo "  /message         - Post to team message board"
    echo "  /view_messages   - See recent messages"
    echo "  /end_turn        - Finish your turn"
    echo ""
}

show_scoreboard() {
    echo -e "${CYAN}=== CURRENT SCOREBOARD ===${NC}"
    echo ""

    # Read scores and display
    if [ -f "$STATE_DIR/scores.json" ]; then
        echo "Agent 1 (QWEN3):   $(grep -o '"agent1".*"total": [0-9]*' "$STATE_DIR/scores.json" | grep -o '[0-9]*$' || echo 0) points"
        echo "Agent 2 (DOODLES): $(grep -o '"agent2".*"total": [0-9]*' "$STATE_DIR/scores.json" | grep -o '[0-9]*$' || echo 0) points"
        echo "Agent 3 (TURBO):   $(grep -o '"agent3".*"total": [0-9]*' "$STATE_DIR/scores.json" | grep -o '[0-9]*$' || echo 0) points"
    else
        echo "No scores recorded yet."
    fi
    echo ""
}

show_library() {
    echo -e "${CYAN}=== DOCUMENT LIBRARY ===${NC}"
    echo ""

    if [ -d "$LIBRARY_DIR" ] && [ "$(ls -A $LIBRARY_DIR 2>/dev/null)" ]; then
        ls -1 "$LIBRARY_DIR" | while read file; do
            echo "  - $file"
        done
    else
        echo "  No documents in library."
        echo "  Add PDF files to: $LIBRARY_DIR"
    fi
    echo ""
}

show_messages() {
    echo -e "${CYAN}=== MESSAGE BOARD (Last 5) ===${NC}"
    echo ""

    if [ -f "$STATE_DIR/message_board.json" ]; then
        # Simple display of messages
        grep '"message":' "$STATE_DIR/message_board.json" | tail -5 | while read line; do
            echo "  $line"
        done
    fi
    echo ""
}

# ============================================
# AGENT FUNCTIONS
# ============================================

get_agent_name() {
    local agent_num=$1
    case $agent_num in
        1) echo "QWEN3" ;;
        2) echo "DOODLES" ;;
        3) echo "TURBO" ;;
        *) echo "UNKNOWN" ;;
    esac
}

get_agent_folder() {
    local agent_num=$1
    echo "$AGENTS_DIR/agent$agent_num"
}

# ============================================
# FACT RECORDING
# ============================================

record_fact() {
    local agent_num=$1
    local agent_folder=$(get_agent_folder $agent_num)
    local agent_name=$(get_agent_name $agent_num)

    echo -e "${CYAN}=== RECORD NEW FACT ===${NC}"
    echo ""

    # Get fact count for this agent
    local fact_count=$(grep -c '"EVENT_ID"' "$agent_folder/facts.json" 2>/dev/null || echo 0)
    local new_id=$((fact_count + 1))
    local event_id=$(printf "EVENT_%03d" $new_id)

    # Prompt for details
    echo -n "Document name: "
    read doc_name

    echo -n "Page number: "
    read page_num

    echo -n "Description of event: "
    read description

    echo -n "Date of event (YYYY-MM-DD or UNKNOWN): "
    read date_of_event

    # Generate temp ID
    local temp_id="${doc_name}-p${page_num}-n${new_id}"

    # Create fact entry
    local timestamp=$(date -Iseconds)

    # Append to facts.json (simple append for now)
    local fact_entry="{\"EVENT_ID\": \"$event_id\", \"TEMP_FACT_ID\": \"$temp_id\", \"DOE\": \"$date_of_event\", \"DESCRIPTION\": \"$description\", \"CREATED_BY\": \"$agent_name\", \"CREATED_AT\": \"$timestamp\", \"STATUS\": \"PENDING\"}"

    # Save to agent's facts file
    echo "$fact_entry" >> "$agent_folder/facts.txt"

    # Update score
    update_score $agent_num 10 "facts"

    # Log it
    log_action "$agent_name" "Created $event_id: $description"

    echo ""
    echo -e "${GREEN}FACT RECORDED!${NC}"
    echo "Event ID: $event_id"
    echo "Temp ID: $temp_id"
    echo "+10 points!"
    echo ""
}

# ============================================
# EVIDENCE LINKING
# ============================================

record_link() {
    local agent_num=$1
    local agent_folder=$(get_agent_folder $agent_num)
    local agent_name=$(get_agent_name $agent_num)

    echo -e "${CYAN}=== LINK EVIDENCE ===${NC}"
    echo ""

    # Show current facts first
    echo "Your current facts:"
    if [ -f "$agent_folder/facts.txt" ]; then
        cat "$agent_folder/facts.txt"
    else
        echo "No facts recorded yet."
        return
    fi
    echo ""

    echo -n "Event ID to link evidence to: "
    read event_id

    echo -n "Document name: "
    read doc_name

    echo -n "Page number: "
    read page_num

    echo -n "Line number (or N/A): "
    read line_num

    echo -n "Exact quote from document: "
    read quote

    # Create evidence entry
    local timestamp=$(date -Iseconds)
    local evidence_entry="{\"LINKED_TO\": \"$event_id\", \"DOCUMENT\": \"$doc_name\", \"PAGE\": \"$page_num\", \"LINE\": \"$line_num\", \"QUOTE\": \"$quote\", \"LINKED_BY\": \"$agent_name\", \"LINKED_AT\": \"$timestamp\"}"

    # Save to agent's evidence file
    echo "$evidence_entry" >> "$agent_folder/evidence.txt"

    # Update score
    update_score $agent_num 5 "evidence"

    # Log it
    log_action "$agent_name" "Linked evidence to $event_id from $doc_name p$page_num"

    echo ""
    echo -e "${GREEN}EVIDENCE LINKED!${NC}"
    echo "+5 points!"
    echo ""
}

# ============================================
# VIEW FUNCTIONS
# ============================================

show_my_facts() {
    local agent_num=$1
    local agent_folder=$(get_agent_folder $agent_num)
    local agent_name=$(get_agent_name $agent_num)

    echo -e "${CYAN}=== $agent_name's FACTS ===${NC}"
    echo ""

    if [ -f "$agent_folder/facts.txt" ] && [ -s "$agent_folder/facts.txt" ]; then
        cat "$agent_folder/facts.txt"
    else
        echo "No facts recorded yet."
    fi
    echo ""
}

# ============================================
# NOTES SYSTEM
# ============================================

handle_notes() {
    local agent_num=$1
    local agent_folder=$(get_agent_folder $agent_num)

    echo -e "${CYAN}=== PERSONAL NOTEPAD ===${NC}"
    echo ""

    if [ -f "$agent_folder/notes.txt" ] && [ -s "$agent_folder/notes.txt" ]; then
        echo "Current notes:"
        cat "$agent_folder/notes.txt"
    else
        echo "(Empty)"
    fi
    echo ""

    echo -n "Add note (or press Enter to skip): "
    read new_note

    if [ -n "$new_note" ]; then
        echo "[$(date +%H:%M:%S)] $new_note" >> "$agent_folder/notes.txt"
        echo -e "${GREEN}Note added!${NC}"
    fi
    echo ""
}

# ============================================
# MESSAGE BOARD
# ============================================

post_message() {
    local agent_num=$1
    local agent_name=$(get_agent_name $agent_num)

    echo -n "Your message: "
    read message

    if [ -n "$message" ]; then
        local timestamp=$(date -Iseconds)
        echo "{\"from\": \"$agent_name\", \"message\": \"$message\", \"time\": \"$timestamp\"}" >> "$STATE_DIR/messages.txt"

        log_action "$agent_name" "Message: $message"
        echo -e "${GREEN}Message posted!${NC}"
    fi
    echo ""
}

# ============================================
# SCORING
# ============================================

update_score() {
    local agent_num=$1
    local points=$2
    local category=$3

    # Simple score tracking with a text file
    local score_file="$STATE_DIR/score_agent$agent_num.txt"

    if [ ! -f "$score_file" ]; then
        echo "0" > "$score_file"
    fi

    local current=$(cat "$score_file")
    local new_score=$((current + points))
    echo "$new_score" > "$score_file"
}

get_score() {
    local agent_num=$1
    local score_file="$STATE_DIR/score_agent$agent_num.txt"

    if [ -f "$score_file" ]; then
        cat "$score_file"
    else
        echo "0"
    fi
}

# ============================================
# LOGGING
# ============================================

log_action() {
    local agent=$1
    local action=$2
    local timestamp=$(date +"%H:%M:%S")

    echo "[$timestamp] $agent: $action" >> "$RECORDS_DIR/session_log.txt"
}

# ============================================
# TURN MANAGEMENT
# ============================================

run_agent_turn() {
    local agent_num=$1
    local agent_name=$(get_agent_name $agent_num)

    show_header $agent_num
    show_commands

    # Show recent messages
    if [ -f "$STATE_DIR/messages.txt" ] && [ -s "$STATE_DIR/messages.txt" ]; then
        echo -e "${CYAN}Recent messages:${NC}"
        tail -3 "$STATE_DIR/messages.txt"
        echo ""
    fi

    # Command loop
    while true; do
        echo -n "> "
        read cmd

        case $cmd in
            /commands)
                show_commands
                ;;
            /library)
                show_library
                ;;
            /scoreboard)
                echo ""
                echo "Agent 1 (QWEN3):   $(get_score 1) points"
                echo "Agent 2 (DOODLES): $(get_score 2) points"
                echo "Agent 3 (TURBO):   $(get_score 3) points"
                echo ""
                ;;
            /record_fact)
                record_fact $agent_num
                ;;
            /record_link)
                record_link $agent_num
                ;;
            /record_show)
                show_my_facts $agent_num
                ;;
            /notes)
                handle_notes $agent_num
                ;;
            /message)
                post_message $agent_num
                ;;
            /view_messages)
                if [ -f "$STATE_DIR/messages.txt" ]; then
                    echo ""
                    tail -10 "$STATE_DIR/messages.txt"
                    echo ""
                fi
                ;;
            /end_turn)
                log_action "$agent_name" "Ended turn"
                echo -e "${YELLOW}$agent_name's turn complete!${NC}"
                sleep 1
                return
                ;;
            /quit)
                echo "Exiting game..."
                exit 0
                ;;
            *)
                echo "Unknown command. Type /commands for help."
                ;;
        esac
    done
}

# ============================================
# MAIN GAME LOOP
# ============================================

main_loop() {
    local round=$(cat "$STATE_DIR/current_round.txt")

    echo -e "${YELLOW}Starting Round $round${NC}"
    log_action "SYSTEM" "--- ROUND $round ---"

    # Run each agent's turn
    run_agent_turn 1
    run_agent_turn 2
    run_agent_turn 3

    # Round complete
    echo ""
    echo -e "${GREEN}=== ROUND $round COMPLETE ===${NC}"
    echo ""
    echo "Scores:"
    echo "  QWEN3:   $(get_score 1) points"
    echo "  DOODLES: $(get_score 2) points"
    echo "  TURBO:   $(get_score 3) points"
    echo ""

    # Update round counter
    round=$((round + 1))
    echo "$round" > "$STATE_DIR/current_round.txt"

    echo -n "Continue to Round $round? (y/n): "
    read continue

    if [ "$continue" = "y" ] || [ "$continue" = "Y" ]; then
        main_loop
    else
        echo ""
        echo -e "${GREEN}Game session saved!${NC}"
        echo "Resume later with: ./game.sh"
    fi
}

# ============================================
# ENTRY POINT
# ============================================

echo ""
echo -e "${YELLOW}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║     LEGAL FACT-FINDING CHAMPIONSHIP                   ║${NC}"
echo -e "${YELLOW}║     The Ultimate Evidence Discovery Game              ║${NC}"
echo -e "${YELLOW}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Initialize if needed
init_game

# Start the game
main_loop
