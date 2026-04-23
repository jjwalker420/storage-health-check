---
name: storage-health-check
description: >
  Runs a fast Mac storage diagnostic and produces a HEALTHY / NEEDS ATTENTION
  / CRITICAL verdict. Checks free disk space, the top Caches and Application
  Support consumers, Trash size, and Claude Code process count — applies
  calibrated thresholds and recommends specific cleanup actions for any WARN
  or FAIL. Read-only, completes in under 30 seconds, never deletes anything.

  Trigger when the user says (or clear variations of): "check my storage",
  "storage health", "storage check", "disk check", "how's my storage", "run
  storage check", "am I running out of space", "is my Mac full", "free up
  space", "low disk space", "what's eating my disk", "why is my Mac slow",
  "clean up my disk".

  Also trigger proactively when a command fails with "No space left on device"
  or a similar disk-full error.
---

# Storage Health Check

Fast, read-only Mac storage diagnostic. One mode: collect probes → apply thresholds → report verdict → recommend action.

## Expected Large Folders (not problems on most Macs)

- `CloudDocs` — iCloud Drive sync cache, can be 10s–100s of GB on a large iCloud plan
- `Claude` — active Claude Code data, 10–20 GB typical
- `com.apple.photoanalysisd`, `Photos` — Photos library internals

## Known Problem Patterns

- `CloudKit` cache > 50 GB → macOS sync bug, usually fixes with signing out/in of iCloud
- Orphaned `claude-code` CLI processes eating RAM (zombie sessions)
- Trash not emptied after a large delete

## Step 0: Load Context

Confirm the collector script exists at `~/.claude/skills/storage-health-check/scripts/collect.sh`. If running in a different environment, adapt the path.

## Step 1: Run the Collector

```bash
bash ~/.claude/skills/storage-health-check/scripts/collect.sh
```

The script outputs structured key=value lines plus two listed sections. Parse:
- `FREE_GB`, `TOTAL_GB`, `USED_PCT`
- `TRASH_GB`
- `CLAUDE_PROCS`
- `TOP_CACHES_BEGIN ... TOP_CACHES_END` — up to 10 lines, `size_gb|name|path`
- `TOP_APPSUPPORT_BEGIN ... TOP_APPSUPPORT_END` — same format

Compute `free_pct = FREE_GB / TOTAL_GB * 100` for threshold comparison. Runtime should be under ~30 seconds.

## Step 2: Apply Thresholds

Thresholds use **percent free** for disk space so they work on any drive size, and **absolute GB** for per-folder probes (which are bounded by app behavior, not disk size).

| Probe | PASS | WARN | FAIL |
|---|---|---|---|
| Free space (% of total) | > 15% | 5–15% | < 5% |
| Single Caches folder | < 10 GB | 10–50 GB | > 50 GB |
| Single Application Support folder | < 20 GB | 20–100 GB | > 100 GB |
| Trash | < 10 GB | 10–50 GB | > 50 GB |
| Claude Code CLI processes | ≤ 3 | 4–6 | > 6 |

**CloudDocs exception:** iCloud Drive cache is expected to be large. Don't flag it unless it dominates the drive — a reasonable ceiling is ~25% of total disk. List it separately as "iCloud Drive cache — expected."

**Overall verdict:**
- **HEALTHY** ✅ — no FAIL and at most 1 WARN
- **NEEDS ATTENTION** ⚠️ — 2+ WARN, or any WARN on free space
- **CRITICAL** 🚨 — any FAIL

## Step 3: Produce the Report

Fill this template exactly. Keep it tight — the whole report should fit on one screen.

```
# Storage Health Check — {EMOJI} {VERDICT}

**Free:** {FREE_GB} GB of {TOTAL_GB} GB ({USED_PCT}% used, {free_pct}% free) — {probe verdict}

## Top 3 Space Consumers
1. {name} — {size} — {verdict}
2. {name} — {size} — {verdict}
3. {name} — {size} — {verdict}

## Other Probes
- Trash: {size} — {verdict}
- Claude Code CLI processes: {count} — {verdict}
- iCloud Drive cache (CloudDocs): {size} — expected

## Recommendations
{Only for WARN or FAIL items. One bullet each. Include why it matters and a
copy-pasteable command — never auto-execute.}

- **{issue}** — {why it matters}. Try: `{command}`

## Summary
{One sentence: current health + the single most important next action, if any.}
```

**Recommendation phrasing (when needed):**
- Caches folder WARN/FAIL → `rm -rf ~/Library/Caches/{folder}/*` (user runs it)
- CloudKit > 50 GB → explain the sync-bug pattern, recommend signing out/in of iCloud in System Settings
- Claude Code processes > 3 → `pkill -f "claude-code"` after saving work in any open sessions
- Trash WARN/FAIL → empty the Trash from Finder, or `rm -rf ~/.Trash/*`
- Free space under threshold with no obvious cause → run `du -sh ~/* ~/Library/* 2>/dev/null | sort -hr | head -20` for a broader sweep

## Guardrails

- **Read-only.** Never delete, move, or modify anything. Report and recommend only.
- **Never execute a cleanup command.** The user copies and runs it themselves.
- **Don't flag CloudDocs as a problem** unless it exceeds ~25% of total disk. State this in the report if it appears in the top consumers.
- **Runtime cap ~30 seconds.** If the collector stalls, report partial data and note which probe was skipped.

## Scope Limits

Covers: top-level `~/Library/Caches`, `~/Library/Application Support`, `~/.Trash`, free space on `/`, Claude Code CLI process count.

Does NOT cover: Photos library internals, Mail database, Xcode DerivedData (unless it appears in Application Support), external drives, Time Machine local snapshots, `/System` or `/Applications`. For a deeper tree view, recommend DaisyDisk or GrandPerspective.
