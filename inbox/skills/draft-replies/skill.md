---
name: draft-replies
description: Detects emails requiring replies and generates contextual draft responses. Use when triaging inbox emails that need human response. Triggers on daily briefing, reply detection, or draft generation tasks.
---

## Reply Detection

Identify emails that likely need a response. Analyze in order of confidence:

### High confidence — reply needed

- **Direct question**: Body contains question marks directed at the user, "could you", "can you", "would you", "please confirm", "let me know"
- **DE equivalents**: "könntest du", "kannst du", "bitte bestätige", "gib mir Bescheid", "lass mich wissen", "was denkst du"
- **Unanswered thread**: Last message in thread is inbound (from someone else), no outbound reply exists
- **Action request**: "please review", "action required", "your approval needed", "bitte prüfen", "Handlungsbedarf", "Freigabe erforderlich"
- **Calendar/meeting**: Meeting request or invitation without RSVP response

### Medium confidence — reply likely needed

- **FYI with implicit expectation**: From a manager, client, or known contact; contains "FYI", "see attached", "zur Info", "anbei"
- **Follow-up thread**: Sender has sent 2+ messages in same thread without reply
- **Deadline mention**: Contains date/time references paired with the user's name or "you"/"du"

### Low confidence — skip drafting

- **Automated notifications**: From `noreply@`, `notifications@`, bulk senders
- **CC'd only**: User is in CC, not TO
- **Newsletters/marketing**: Matches newsletter or marketing patterns from `email-categorization` skill
- **Group emails**: Large recipient lists (>5 in TO/CC) without direct mention

## Draft Generation Rules

### Language matching

- Detect the language of the original email (DE or EN)
- Draft the reply in the **same language**
- If mixed (e.g., English email from German company), prefer the language of the body text

### Tone matching

- **Formal email** (Sie/Dear/Sehr geehrte) → formal reply
- **Informal email** (Du/Hi/Hey/Hallo) → informal reply
- **Business context** → professional, concise
- **Personal context** → warmer, but still brief

### Draft structure

1. **Greeting** — match the original's style
2. **Acknowledgment** — reference what the sender asked/said (1 sentence)
3. **Response** — address the specific request or question (1-3 sentences)
4. **Next step** — if applicable, state what you'll do or what you need (1 sentence)
5. **Closing** — match formality level

### When uncertain about content

If the email requires domain knowledge or decisions the AI cannot make:

```
Hi {name},

Thanks for your email regarding {topic}. I'll review this and get back to you
by {reasonable timeframe}.

Best,
```

DE variant:
```
Hallo {name},

danke für deine Nachricht zu {topic}. Ich schaue mir das an und melde mich
bis {reasonable timeframe} bei dir.

Viele Grüße,
```

### Draft constraints

- **Never fabricate** commitments, dates, or decisions the user hasn't made
- **Never include** sensitive information not present in the thread
- **Keep short** — 2-5 sentences maximum
- **Mark as uncertain** in the briefing if the reply needs significant user editing
- **Thread awareness** — reference prior messages in the thread for context continuity

## Reporting in Briefing

For each draft created, report:

```
- [x] **Reply to**: {sender name} — "{subject}"
  - **Why**: {one-line reason, e.g., "Direct question about Q1 timeline, unanswered 2 days"}
  - **Draft preview**: "{first 100 chars of draft}..."
  - **Confidence**: {High/Medium}
  - Draft ID: {draft_id}
```
