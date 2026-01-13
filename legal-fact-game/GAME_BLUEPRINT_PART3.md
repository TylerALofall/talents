# LEGAL FACT-FINDING CHAMPIONSHIP - PART 3 OF 5

## THE WORKING GAME.SH SCRIPT

The `game.sh` script has been created with the following logic:

---

## SCRIPT FUNCTIONS EXPLAINED

### 1. INITIALIZATION (init_game)
```
Creates all folders:
- config/     - Game settings
- state/      - Current game state
- agents/     - Agent workspaces (agent1, agent2, agent3)
- library/    - PDF documents
- records/    - Session logs

Creates initial files:
- agents.json      - Agent names and personas
- scores.json      - Score tracking
- message_board.json - Team messages
- facts.json       - Per agent facts
- evidence.json    - Per agent evidence
- notes.txt        - Per agent notepad
- session_log.txt  - Full activity log
```

### 2. DISPLAY FUNCTIONS
```
show_header()     - Shows game title, round, current agent
show_commands()   - Lists all available commands
show_scoreboard() - Displays current point totals
show_library()    - Lists PDF files in library folder
show_messages()   - Shows last 5 team messages
```

### 3. FACT RECORDING (record_fact)
```
Input:
- Document name
- Page number
- Description of event
- Date of event

Output:
- Creates EVENT_XXX with TEMP_FACT_ID
- Saves to agent's facts.txt
- Awards +10 points
- Logs action to session_log.txt
```

### 4. EVIDENCE LINKING (record_link)
```
Input:
- Event ID to link to
- Document name
- Page number
- Line number
- Exact quote

Output:
- Creates evidence entry
- Saves to agent's evidence.txt
- Awards +5 points
- Logs action to session_log.txt
```

### 5. TURN MANAGEMENT (run_agent_turn)
```
Flow:
1. Show header with agent name
2. Show command list
3. Show recent messages
4. Enter command loop
5. Process commands until /end_turn
6. Log turn end
7. Return to main loop
```

### 6. MAIN GAME LOOP (main_loop)
```
Flow:
1. Show current round
2. Run Agent 1 turn
3. Run Agent 2 turn
4. Run Agent 3 turn
5. Show round summary
6. Ask to continue
7. Loop or exit
```

---

## COMMAND PROCESSING

| Command | What It Does |
|---------|--------------|
| /commands | Displays the command list |
| /library | Lists PDFs in library/ folder |
| /scoreboard | Shows all three agent scores |
| /record_fact | Prompts for fact details, saves, awards points |
| /record_link | Prompts for evidence details, links to fact |
| /record_show | Displays current agent's facts |
| /notes | View or add to personal notepad |
| /message | Post to team message board |
| /view_messages | See last 10 messages |
| /end_turn | Saves state, passes to next agent |
| /quit | Exits the game |

---

## HOW DATA IS STORED

### Facts (facts.txt per agent)
Each fact is one line of JSON:
```
{"EVENT_ID": "EVENT_001", "TEMP_FACT_ID": "OB-p7-n1", "DOE": "2022-03-04", "DESCRIPTION": "Officer arrested without warrant", "CREATED_BY": "QWEN3", "CREATED_AT": "2024-01-15T14:30:00Z", "STATUS": "PENDING"}
```

### Evidence (evidence.txt per agent)
Each evidence link is one line of JSON:
```
{"LINKED_TO": "EVENT_001", "DOCUMENT": "Opening_Brief.pdf", "PAGE": "7", "LINE": "23", "QUOTE": "Officer failed to obtain warrant", "LINKED_BY": "QWEN3", "LINKED_AT": "2024-01-15T14:35:00Z"}
```

### Scores (score_agentX.txt)
Simple number:
```
45
```

### Session Log (session_log.txt)
Plain text timeline:
```
[14:30:00] QWEN3: Created EVENT_001: Officer arrested without warrant
[14:30:15] QWEN3: +10 points (new fact)
[14:30:30] QWEN3: Ended turn
```

---

## TO RUN THE GAME

```bash
cd /home/user/talents/legal-fact-game
./game.sh
```

---

## WHAT'S NEXT (PART 4)

Part 4 will add:
- Agent persona configuration (pick name, write description)
- Game rules file for agents to read
- Challenge system between agents
