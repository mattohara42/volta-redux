---
description: Rewrite HANDOFF.md as a fresh state snapshot
---

Rewrite `HANDOFF.md`. The rules from CLAUDE.md, which this command exists to
enforce:

- **Rewrite it, never append.** The file is a snapshot, not a log.
- A resolved thread becomes one line or disappears entirely.
- Never restate another doc, link it.
- No session narrative. That is what `git log` is for.
- Keep it under 150 lines.
- No em-dashes, in this file or any other.

It has to carry: the date, the phase, the active milestone and its done-when,
where the project actually is, the next action, and what is blocked on Matt with
what each blocker blocks.

Read the current `HANDOFF.md` and the session's work first, then diff what
changed. Something that was blocked and is now answered comes out. Something
newly discovered goes in. Show Matt the rewritten file and what you dropped.
