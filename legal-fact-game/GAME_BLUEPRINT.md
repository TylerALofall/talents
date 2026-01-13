# LEGAL FACT-FINDING CHAMPIONSHIP - SYSTEM BLUEPRINT

## PART 1 OF 5: SYSTEM OVERVIEW & FLOWCHART

### THE SIMPLE TRUTH
This is a PROMPT GAME. The shell scripts just:
- Store data between model calls
- Track whose turn it is
- Display info to models
- Record what models submit

The MODELS do the thinking. Not scripts. Not subprocesses.

---

## HIGH-LEVEL FLOWCHART

```
┌─────────────────────────────────────────────────────────────┐
│                         START GAME                           │
│                    (run: ./game.sh start)                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    LOAD GAME STATE                           │
│         (read current_turn.txt, scores.json, etc)           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    AGENT ROTATION LOOP                       │
│                                                              │
│   ┌──────────────────────────────────────────────────────┐  │
│   │  AGENT 1 TURN                                         │  │
│   │  1. Print prompt header + commands                    │  │
│   │  2. Show message board (last 5 messages)              │  │
│   │  3. Show current scores                               │  │
│   │  4. Wait for model input                              │  │
│   │  5. Process command → store result                    │  │
│   │  6. Model types /end_turn                             │  │
│   └──────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│   ┌──────────────────────────────────────────────────────┐  │
│   │  AGENT 2 TURN (same flow)                             │  │
│   └──────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│   ┌──────────────────────────────────────────────────────┐  │
│   │  AGENT 3 TURN (same flow)                             │  │
│   └──────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│   ┌──────────────────────────────────────────────────────┐  │
│   │  ROUND COMPLETE                                       │  │
│   │  - Update master log                                  │  │
│   │  - Display round summary                              │  │
│   │  - Continue or end game?                              │  │
│   └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    (LOOP BACK TO AGENT 1)
```

---

## COMMAND FLOW FOR EACH AGENT TURN

```
AGENT TURN STARTS
       │
       ▼
┌────────────────────────────────────┐
│  DISPLAY TURN HEADER               │
│  "YOUR TURN! FACT FINDER GAME"     │
│  + Current agent name              │
│  + Round number                    │
└────────────────────────────────────┘
       │
       ▼
┌────────────────────────────────────┐
│  DISPLAY COMMANDS                  │
│  /commands /library /scoreboard    │
│  /record_fact /record_link         │
│  /record_show /notes /end_turn     │
└────────────────────────────────────┘
       │
       ▼
┌────────────────────────────────────┐
│  SHOW MESSAGE BOARD                │
│  (last 3-5 messages from others)   │
└────────────────────────────────────┘
       │
       ▼
┌────────────────────────────────────────────────────┐
│  WAIT FOR COMMAND INPUT                            │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │ /record_fact → Ask for fact details          │  │
│  │               → Save to agent's facts.json   │  │
│  │               → Award points                 │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │ /record_link → Ask for evidence details      │  │
│  │              → Link to existing fact         │  │
│  │              → Save to evidence.json         │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │ /scoreboard → Display current scores         │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │ /record_show → List agent's current facts    │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │ /library → List available documents          │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │ /notes → View/edit personal notepad          │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │ /end_turn → Save state, pass to next agent   │  │
│  └──────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────┘
```

---

## FILE LIST (MINIMAL - ONLY WHAT'S NEEDED)

```
legal-fact-game/
│
├── game.sh                 # Main entry point - runs everything
│
├── config/
│   ├── agents.json         # Agent names and personas
│   └── rules.txt           # Game rules (readable by models)
│
├── state/
│   ├── current_turn.txt    # Which agent's turn (1, 2, or 3)
│   ├── current_round.txt   # What round we're on
│   ├── scores.json         # All agent scores
│   └── message_board.json  # Team messages
│
├── agents/
│   ├── agent1/
│   │   ├── facts.json      # This agent's collected facts
│   │   ├── evidence.json   # This agent's linked evidence
│   │   ├── notes.txt       # Personal notepad
│   │   └── summaries.json  # Document summaries they made
│   ├── agent2/
│   │   └── (same structure)
│   └── agent3/
│       └── (same structure)
│
├── library/
│   └── (PDF documents go here)
│
├── records/
│   ├── master_facts.json   # READ-ONLY combined facts (system writes)
│   ├── master_timeline.json
│   └── session_log.txt     # Full activity log
│
└── templates/
    ├── fact_template.json  # Schema for facts
    └── evidence_template.json
```

TOTAL: 1 shell script + JSON/TXT data files
NO PYTHON. NO SUBPROCESSES. NO COMPLEXITY.

---

## WHAT EACH FILE DOES

| File | Purpose | Who Writes | Who Reads |
|------|---------|------------|-----------|
| game.sh | Main loop, all commands | You (once) | System |
| agents.json | Agent names/personas | You (setup) | System |
| current_turn.txt | Track whose turn | System | System |
| scores.json | Point totals | System | Agents |
| message_board.json | Team chat | Agents | Agents |
| facts.json (per agent) | Their found facts | That agent | That agent |
| evidence.json (per agent) | Their evidence links | That agent | That agent |
| notes.txt (per agent) | Scratch pad | That agent | That agent |
| master_facts.json | Combined verified facts | System only | All agents |
| session_log.txt | Full history | System | You |

---

## NEXT PARTS

- **PART 2**: Detailed JSON schemas (fact template, evidence template)
- **PART 3**: Complete game.sh script with all commands
- **PART 4**: Agent persona setup and message board format
- **PART 5**: Scoring rules and validation system

Ready for Part 2?
