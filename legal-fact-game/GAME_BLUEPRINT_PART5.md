# LEGAL FACT-FINDING CHAMPIONSHIP - PART 5 OF 5

## SCORING SYSTEM & TEMPLATES

---

## SCORING FORMULAS

### Base Point Values
| Action | Points |
|--------|--------|
| New fact recorded | +10 |
| Evidence linked to fact | +5 |
| Document summary completed | +3 |
| Message posted | +1 |

### Bonus Points
| Achievement | Bonus |
|-------------|-------|
| First to find a fraud | +20 |
| Criminal violation discovered | +25 |
| Complete UID chain (all elements) | +15 |
| Collaboration lead that pays off | +10 |
| Correct challenge (caught error) | +15 |

### Penalties
| Mistake | Penalty |
|---------|---------|
| Duplicate fact submitted | -10 |
| Challenge lost (you were wrong) | -5 |
| Incorrect quote/citation | -10 |
| Missing required summary | -5 |

---

## FACT TEMPLATE (What agents fill out)

```
/record_fact

DOCUMENT NAME: _______________
PAGE NUMBER: _______________
DESCRIPTION OF EVENT: _______________
DATE OF EVENT (YYYY-MM-DD or UNKNOWN): _______________
DEFENDANTS INVOLVED (optional): _______________
DUTY BREACHED (optional): _______________
```

### System Generates:
```
EVENT_ID: EVENT_001
TEMP_FACT_ID: {DOC}-p{PAGE}-n{SEQ}
CREATED_BY: {AGENT}
CREATED_AT: {TIMESTAMP}
STATUS: PENDING
UID: UNKNOWN (assigned later)
```

---

## EVIDENCE TEMPLATE

```
/record_link

LINK TO EVENT ID: _______________
DOCUMENT NAME: _______________
PAGE NUMBER: _______________
LINE NUMBER (or N/A): _______________
EXACT QUOTE: _______________
```

### System Generates:
```
EVIDENCE_ID: EVD_001
LINKED_TO: {EVENT_ID}
ECF: (if applicable)
SCREENSHOT_STATUS: PENDING
VALIDATED: false
```

---

## VALIDATION CHECKLIST

Before a fact is marked VALIDATED, check:

```
□ Evidence directly supports the fact claim
□ Citation matches actual document content
□ Quote is word-for-word (no paraphrasing)
□ Page/line numbers are accurate
□ UID elements are logically connected
□ No contradictory information exists
□ Not a duplicate of existing fact
```

---

## DOCUMENT SUMMARY TEMPLATE

When agent reads a document, they must provide:

```
DOCUMENT: _______________
PAGES REVIEWED: _______________

PAGE SUMMARIES:
- Page 3: [2-3 sentences about this page]
- Page 4: [2-3 sentences about this page]
- Page 13: [2-3 sentences about this page]

KEY ARGUMENTS FOUND:
1. _______________
2. _______________
3. _______________

POTENTIAL FACTS SPOTTED:
1. _______________
2. _______________
```

---

## 10 IMPROVEMENTS TO CONSIDER

After reviewing the entire system, here are 10 enhancements:

1. **Add /challenge command**
   - Allow agents to formally challenge each other's facts
   - Require evidence for the challenge
   - Moderator grades the dispute

2. **Add /steal command**
   - If someone misses part of a fact, another agent can complete it
   - Partial credit sharing

3. **Add /team_up command**
   - Formal collaboration mode
   - Split points on shared discoveries

4. **Add fact validation queue**
   - Facts start as PENDING
   - Move to VALIDATED after evidence linked
   - Move to CONFIRMED after challenge period

5. **Add UID assignment workflow**
   - Once fact is confirmed, assign permanent UID
   - UID format: CLAIM_ID-ELEMENT_ID-DEFENDANT_ID

6. **Add document view tracking**
   - Track which pages each agent has reviewed
   - Prevent duplicate work
   - Show coverage map

7. **Add screenshot placeholder**
   - Mark facts as NEEDS_SCREENSHOT
   - Track which have visual evidence

8. **Add timeline view**
   - /timeline command
   - Shows all facts in chronological order
   - Helps spot gaps

9. **Add fact editing**
   - /edit_fact {EVENT_ID}
   - Update description, date, etc.
   - Log all edits

10. **Add export function**
    - /export
    - Creates summary report
    - Exports to printable format

---

## COMPLETE FILE LIST

```
legal-fact-game/
├── game.sh                     # Main game script
├── GAME_BLUEPRINT.md           # Part 1 - Flowchart
├── GAME_BLUEPRINT_PART2.md     # Part 2 - Schemas
├── GAME_BLUEPRINT_PART3.md     # Part 3 - Script details
├── GAME_BLUEPRINT_PART4.md     # Part 4 - Personas/Rules
├── GAME_BLUEPRINT_PART5.md     # Part 5 - Scoring/Templates
│
├── config/
│   ├── agents.json             # Agent definitions
│   ├── personas.txt            # Custom names/descriptions
│   └── rules.txt               # Game rules (agent readable)
│
├── state/
│   ├── current_turn.txt        # Which agent's turn (1/2/3)
│   ├── current_round.txt       # Current round number
│   ├── score_agent1.txt        # Agent 1 score
│   ├── score_agent2.txt        # Agent 2 score
│   ├── score_agent3.txt        # Agent 3 score
│   └── messages.txt            # Message board
│
├── agents/
│   ├── agent1/
│   │   ├── facts.txt           # Agent 1's facts
│   │   ├── evidence.txt        # Agent 1's evidence
│   │   ├── notes.txt           # Agent 1's notepad
│   │   └── summaries.txt       # Agent 1's doc summaries
│   ├── agent2/
│   │   └── (same structure)
│   └── agent3/
│       └── (same structure)
│
├── library/
│   └── (PDF documents here)
│
├── records/
│   ├── session_log.txt         # Full activity log
│   ├── master_facts.txt        # Combined verified facts
│   └── master_timeline.txt     # Chronological ordering
│
└── templates/
    ├── fact_template.txt       # Blank fact form
    └── evidence_template.txt   # Blank evidence form
```

---

## READY TO BUILD

The system is now fully designed. Run:

```bash
cd /home/user/talents/legal-fact-game
./game.sh
```

The script will:
1. Create all folders automatically
2. Initialize all state files
3. Start the agent rotation loop
4. Track everything to text files

NO PYTHON. NO SUBPROCESSES. JUST SHELL AND TEXT.
