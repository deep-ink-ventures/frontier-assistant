---
name: task-extraction
description: Extracts action items and tasks from inbox emails, and identifies high-traction threads where the user is CC'd. Use during daily briefing to surface work that needs doing. Triggers on briefing analysis, task detection, or action item extraction.
---

## What This Skill Does

Scans every inbox email for two things:

1. **Action items** — emails where someone expects the user to do something
2. **High-traction threads** — threads with lots of activity where the user is CC'd (likely important to stay aware of)

## Action Item Detection

Analyze each email's body, subject, and thread context. Look for these patterns:

### Direct task assignment (HIGH confidence)

**EN patterns**:
- "can you take care", "could you handle", "please take care of", "can you look into"
- "please handle", "over to you", "assigning to you", "you're on point"
- "action required", "please review", "needs your approval", "please sign off"
- Forwarded email (Fwd: prefix OR forwarded headers) + any of the above

**DE patterns**:
- "kannst du dich darum kümmern", "kannst du das übernehmen", "bitte kümmere dich"
- "bitte erledigen", "liegt bei dir", "übernimmst du", "du bist dran"
- "Handlungsbedarf", "bitte prüfen", "braucht deine Freigabe", "bitte unterschreiben"
- Weitergeleitete Email (WG: / Fwd: Prefix) + any of the above

### Implicit task (MEDIUM confidence)

- User is in TO, thread has no reply from user, and latest message contains a question or request
- Forwarded email with no explicit instruction but context implies action (e.g., an invoice forwarded to you = "please process")
- Mentioned by name in a thread body ("@{user}" or "{user_first_name}, " followed by a request)
- Deadline or date mentioned alongside user's name

### Not a task (skip)

- Automated notifications, newsletters, marketing
- User is CC'd with no mention of their name and no request language
- Informational FYI with no implicit action expectation
- Threads where user has already replied (conversation complete)

## High-Traction Thread Detection

Identify threads where the user is CC'd and the thread has significant activity:

### Criteria

- User is in CC (not TO)
- Thread has **3+ messages** from **2+ different senders**
- At least **2 messages in the last 7 days**

### Scoring

- **HOT**: 5+ messages in last 3 days, or 3+ different participants
- **ACTIVE**: 3+ messages in last 7 days
- Below threshold: skip

### What to extract

For each high-traction thread:
1. Thread subject
2. Participants (who's driving the conversation)
3. One-line summary of what the thread is about
4. Whether the user is mentioned by name anywhere (escalates priority)

## Reporting in Briefing

### Action items format

```
## Section B — Action Items

Tasks extracted from your inbox. These need your attention.

### HIGH confidence

- [ ] **From**: {sender} — "{subject}"
  - **Task**: {extracted task summary, 1-2 sentences}
  - **Context**: {forwarded / direct / thread mention}
  - **Age**: {how long ago the email arrived}

### MEDIUM confidence

- [ ] **From**: {sender} — "{subject}"
  - **Task**: {extracted task summary}
  - **Context**: {why this looks like a task}
  - **Age**: {how long ago}
```

### High-traction threads format

```
## Section A — Situation Report

### High-Traction Threads (CC'd)

Threads with significant activity where you're copied. Stay aware.

- 🔴 **HOT** "{subject}" — {n} messages, {participants}
  - **Summary**: {one-line summary}
  - **Your mention**: {yes/no — were you mentioned by name?}

- 🟡 **ACTIVE** "{subject}" — {n} messages, {participants}
  - **Summary**: {one-line summary}
```

## Integration with draft-replies

If an action item also needs a reply (e.g., someone asks "can you take care of this?" — the task is the work, the reply is "yes, I'll handle it"), both should appear:
- The **task** in Section B (Action Items)
- The **draft reply** in Section C (Draft Replies)

Do not duplicate: the draft reply acknowledges the task, Section B tracks the actual work.
