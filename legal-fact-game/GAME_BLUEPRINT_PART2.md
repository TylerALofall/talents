# LEGAL FACT-FINDING CHAMPIONSHIP - PART 2 OF 5

## JSON SCHEMAS (YOUR CUSTOM FORMAT)

---

## FACT SCHEMA (Pass 1 - Fact Extraction)

This is what gets stored when an agent records a fact:

```json
{
  "EVENT_ID": "EVENT_001",
  "TEMP_FACT_ID": "OB-p7-n1",
  "UID": {
    "STATUS": "UNKNOWN",
    "CLAIM_ID": "",
    "ELEMENT_ID": "",
    "DEFENSE_ID": "",
    "DEFENDANT_ID": "",
    "POTENTIAL_UIDS": []
  },
  "DATE_INFO": {
    "DOE": "",
    "DATE_RANGE_START": "",
    "DATE_RANGE_END": "",
    "CHRONOLOGY_ANCHOR": ""
  },
  "DEFENDANTS_INVOLVED": "",
  "DESCRIPTION_OF_EVENT": "",
  "DUTY_BREACHED": "",
  "CREATED_BY": "AGENT_NAME",
  "CREATED_AT": "2024-01-15T14:30:00Z",
  "VALIDATION_STATUS": "PENDING"
}
```

---

## EVIDENCE SCHEMA (Pass 2 - Evidence Matching)

This links evidence to a fact:

```json
{
  "EVIDENCE_ID": "EVD_001",
  "LINKED_EVENT_ID": "EVENT_001",
  "PROOF": {
    "DOCUMENT_NAME": "",
    "SOURCE": "",
    "TYPE": "",
    "QUOTE": "",
    "CITATION": {
      "ECF": "",
      "PAGE": "",
      "LINE": ""
    }
  },
  "SCREENSHOT": {
    "STATUS": "PENDING",
    "EVIDENCE_PINPOINT": "",
    "FILENAME": "",
    "PATH": ""
  },
  "LINKED_BY": "AGENT_NAME",
  "LINKED_AT": "2024-01-15T14:35:00Z",
  "VALIDATED": false
}
```

---

## AGENT PERSONA FILE (agents.json)

```json
{
  "agents": [
    {
      "id": 1,
      "name": "QWEN3",
      "custom_name": "",
      "persona": "",
      "score": 0,
      "facts_found": 0,
      "challenges_won": 0
    },
    {
      "id": 2,
      "name": "DOODLES",
      "custom_name": "",
      "persona": "",
      "score": 0,
      "facts_found": 0,
      "challenges_won": 0
    },
    {
      "id": 3,
      "name": "TURBO",
      "custom_name": "",
      "persona": "",
      "score": 0,
      "facts_found": 0,
      "challenges_won": 0
    }
  ]
}
```

---

## MESSAGE BOARD (message_board.json)

```json
{
  "messages": [
    {
      "timestamp": "2024-01-15T14:30:00Z",
      "from": "DOODLES",
      "message": "Found a fraud on page 23!",
      "type": "discovery"
    },
    {
      "timestamp": "2024-01-15T14:32:00Z",
      "from": "TURBO",
      "message": "Good find! Check page 24 too.",
      "type": "tip"
    },
    {
      "timestamp": "2024-01-15T14:33:00Z",
      "from": "TYLER",
      "message": "Great teamwork! Moving to Phase 2.",
      "type": "moderator"
    }
  ]
}
```

---

## SCORES FILE (scores.json)

```json
{
  "round": 3,
  "phase": "EXTRACTION",
  "scores": {
    "QWEN3": {
      "total": 45,
      "facts": 12,
      "evidence_links": 8,
      "challenges_won": 2,
      "challenges_lost": 1,
      "bonus_points": 5
    },
    "DOODLES": {
      "total": 52,
      "facts": 15,
      "evidence_links": 10,
      "challenges_won": 3,
      "challenges_lost": 0,
      "bonus_points": 7
    },
    "TURBO": {
      "total": 38,
      "facts": 9,
      "evidence_links": 6,
      "challenges_won": 1,
      "challenges_lost": 2,
      "bonus_points": 4
    }
  },
  "last_updated": "2024-01-15T14:40:00Z"
}
```

---

## GAME STATE FILE (game_state.json)

```json
{
  "game_id": "session_001",
  "started_at": "2024-01-15T14:00:00Z",
  "current_round": 3,
  "current_turn": 2,
  "current_phase": "EXTRACTION",
  "agents_order": ["QWEN3", "DOODLES", "TURBO"],
  "documents_loaded": [
    "Opening_Brief.pdf",
    "Exhibit_A.pdf"
  ],
  "total_facts_found": 36,
  "status": "IN_PROGRESS"
}
```

---

## DOCUMENT SUMMARY SCHEMA (per agent)

```json
{
  "summaries": [
    {
      "document": "Opening_Brief.pdf",
      "pages_reviewed": "1-5, 12-15, 22-28",
      "summary": [
        {"page": 3, "summary": "Unlawful arrest claim established. Officer detained plaintiff without probable cause."},
        {"page": 4, "summary": "Conspiracy evidence introduced. Multiple state actors coordinated false reporting."},
        {"page": 13, "summary": "Damages calculation detailed. $111,943.56 lost income documented."}
      ],
      "key_arguments": [
        "Fourth Amendment violation",
        "Conspiracy under 42 USC 1983",
        "Qualified immunity should be denied"
      ],
      "created_by": "AGENT_NAME",
      "created_at": "2024-01-15T14:30:00Z"
    }
  ]
}
```

---

## SESSION LOG FORMAT (session_log.txt)

Plain text, easy to read:

```
=== LEGAL FACT-FINDING CHAMPIONSHIP ===
Session: session_001
Started: 2024-01-15 14:00:00

--- ROUND 1 ---

[14:01:00] QWEN3: /record_fact
[14:01:15] QWEN3: Created EVENT_001 - "Officer failed to establish probable cause"
[14:01:30] QWEN3: +10 points (new fact)
[14:02:00] QWEN3: /end_turn

[14:02:15] DOODLES: /record_fact
[14:02:30] DOODLES: Created EVENT_002 - "False arrest report filed"
[14:02:45] DOODLES: +10 points (new fact)
[14:03:00] DOODLES: /message "Found fraud on page 23!"
[14:03:15] DOODLES: /end_turn

[14:03:30] TURBO: /library
[14:03:45] TURBO: /record_fact
[14:04:00] TURBO: Created EVENT_003 - "DDA suppressed exculpatory evidence"
[14:04:15] TURBO: +10 points (new fact)
[14:04:20] TURBO: +5 bonus (fraud discovery)
[14:04:30] TURBO: /end_turn

--- ROUND 1 COMPLETE ---
Scores: QWEN3=10, DOODLES=10, TURBO=15
```

---

## INPUT/OUTPUT FOR EACH COMMAND

| Command | Input Required | Output |
|---------|---------------|--------|
| /commands | None | Display command list |
| /library | None | List PDFs in library folder |
| /scoreboard | None | Display scores.json formatted |
| /record_fact | Prompt for: doc_name, page, description, date | Save to facts.json, +10 points |
| /record_link | Prompt for: event_id, doc, page, quote | Save to evidence.json, +5 points |
| /record_show | None | Display agent's facts.json |
| /notes | None or text | View or append to notes.txt |
| /view_index_summary | None | Display agent's summaries.json |
| /message | Text | Add to message_board.json |
| /challenge | agent, event_id | Start challenge process |
| /end_turn | None | Save state, advance turn |

---

## READY FOR PART 3?

Part 3 will contain the complete game.sh script with all the logic.
