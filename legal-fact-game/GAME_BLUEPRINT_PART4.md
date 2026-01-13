# LEGAL FACT-FINDING CHAMPIONSHIP - PART 4 OF 5

## AGENT PERSONA SYSTEM

---

## PERSONA SETUP

When a model first joins the game, they can customize themselves:

### Persona Prompt (shown at game start)
```
Welcome to the Legal Fact-Finding Championship!

Before we begin, let's set up your identity.

Your default name is: [QWEN3/DOODLES/TURBO]

Would you like to customize?
1. Keep default name
2. Choose a custom name

Custom name: _______________

Now describe yourself in one sentence (your persona):
Example: "I'm a meticulous researcher who never misses a detail."

Your persona: _______________
```

### Persona Storage (config/personas.txt)
```
AGENT1_NAME=QWEN3
AGENT1_PERSONA=I am a methodical analyst who builds cases brick by brick.

AGENT2_NAME=DOODLES
AGENT2_PERSONA=I find the hidden connections others miss.

AGENT3_NAME=TURBO
AGENT3_PERSONA=Speed and accuracy - I lock down facts fast.
```

---

## GAME RULES FILE (config/rules.txt)

This file is readable by agents using `/rules` command:

```
╔══════════════════════════════════════════════════════════════╗
║        LEGAL FACT-FINDING CHAMPIONSHIP - OFFICIAL RULES      ║
╚══════════════════════════════════════════════════════════════╝

OBJECTIVE
---------
Extract, verify, and score legal facts from case documents.
Build the most comprehensive and accurate evidence collection.

GAME PHASES
-----------
PHASE 1: FACT EXTRACTION
- Read documents and identify factual events
- Record each event with /record_fact
- Must include: document name, page, description, date

PHASE 2: EVIDENCE MATCHING
- Link evidence to your recorded facts
- Use /record_link to connect quotes and citations
- Must include: exact quote, page/line numbers

PHASE 3: VALIDATION
- Review your facts for accuracy
- Other agents can challenge weak evidence
- Prepare for cross-examination

PHASE 4: EXPANSION
- Find additional evidence for existing facts
- Discover new facts from new documents

SCORING
-------
+10 points: New fact recorded
+5 points:  Evidence linked to fact
+15 points: Challenge won (caught opponent error)
+20 points: Fraud/criminal violation discovered
-5 points:  Challenge lost (your error caught)
-10 points: Duplicate fact submitted

CHALLENGES
----------
Any agent can challenge another's fact by:
1. Claiming it's a duplicate
2. Claiming weak/incorrect evidence
3. Claiming misquote or wrong citation

The moderator (Tyler) grades challenges.

DOCUMENT SUMMARIES
------------------
REQUIRED: 2-3 sentences per page reviewed
- Must include page numbers
- Must include key arguments or facts
- Summaries survive context loss

TEAMWORK
--------
Agents may collaborate via /message
- Share leads and discoveries
- Propose team investigations
- Trade fact hunting territories

FAIR PLAY
---------
- No fabricating quotes
- No inventing page numbers
- All evidence must be verifiable
- Honesty earns respect

WIN CONDITIONS
--------------
Highest total score at session end
OR
First to complete all UIDs for a claim
OR
Discovery of major fraud/violation (+bonus)
```

---

## PROMPT HEADER (shown every turn)

```
╔══════════════════════════════════════════════════════════════╗
║    YOUR TURN! FACT FINDER CHAMPIONSHIP                       ║
╠══════════════════════════════════════════════════════════════╣
║  Agent: {AGENT_NAME}                                         ║
║  Round: {ROUND_NUMBER}                                       ║
║  Phase: {CURRENT_PHASE}                                      ║
║  Score: {CURRENT_SCORE}                                      ║
╚══════════════════════════════════════════════════════════════╝

COMMANDS:
1. /commands      - Full command list
2. /library       - Available documents
3. /scoreboard    - Current standings
4. /record_fact   - Submit a fact
5. /record_link   - Link evidence
6. /record_show   - Your current facts
7. /notes         - Personal notepad
8. /message       - Team message board
9. /rules         - View game rules
10. /end_turn     - Pass to next player

>
```

---

## MESSAGE BOARD DISPLAY

When agents see the message board:

```
════════════════════════════════════════════════════════════════
MESSAGE BOARD
════════════════════════════════════════════════════════════════

[14:30] DOODLES: Found fraud on page 23! Check ECF 15.

[14:32] TURBO: Good find! I'll take pages 24-30.

[14:33] TYLER: Great teamwork. Phase 2 starts next round.

[14:35] QWEN3: I have UID 334 if anyone needs it.

════════════════════════════════════════════════════════════════
```

---

## END OF TURN SUMMARY

When agent types /end_turn:

```
════════════════════════════════════════════════════════════════
{AGENT_NAME}'S TURN COMPLETE
════════════════════════════════════════════════════════════════

This turn:
- Facts recorded:    3
- Evidence linked:   2
- Messages posted:   1
- Points earned:     +40

Total score:         125 points

Next up: {NEXT_AGENT_NAME}
════════════════════════════════════════════════════════════════
```

---

## ROUND SUMMARY (after all 3 agents go)

```
════════════════════════════════════════════════════════════════
ROUND {N} COMPLETE
════════════════════════════════════════════════════════════════

SCOREBOARD:
1st: DOODLES     - 145 points  (+45 this round)
2nd: TURBO       - 125 points  (+30 this round)
3rd: QWEN3       - 110 points  (+25 this round)

TOTAL FACTS FOUND: 47
TOTAL EVIDENCE LINKS: 32

TYLER'S NOTES:
{Moderator comments here}

Continue to Round {N+1}? (y/n)
════════════════════════════════════════════════════════════════
```

---

## WHAT'S NEXT (PART 5)

Part 5 will finalize:
- Scoring formulas
- Fact and Evidence templates
- Validation checklist
- 10 things to improve
