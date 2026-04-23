# storage-health-check

A fast, read-only Mac storage diagnostic [skill](https://docs.claude.com/en/docs/claude-code/skills) for Claude Code. Run it anytime — it produces a **HEALTHY / NEEDS ATTENTION / CRITICAL** verdict with specific cleanup recommendations, without deleting anything.

Built to catch storage problems *before* they become emergencies: cache blowouts, orphaned Claude Code sessions, full Trash, the CloudKit sync-bug pattern, and other common Mac storage gremlins.

## What it checks

- Free disk space (as % of total — works on any drive size)
- Top 10 `~/Library/Caches` folders by size
- Top 10 `~/Library/Application Support` folders by size
- Trash size
- Claude Code CLI process count (catches orphaned zombie sessions)

Runs in under 30 seconds on a typical Mac.

## Example output

```
# Storage Health Check — ✅ HEALTHY

**Free:** 749.4 GB of 926 GB (19% used, 81% free) — PASS

## Top 3 Space Consumers
1. Claude (Application Support) — 14.00 GB — PASS
2. Google (Caches) — 3.80 GB — PASS
3. Notion (Application Support) — 3.46 GB — PASS

## Other Probes
- Trash: 0.00 GB — PASS
- Claude Code CLI processes: 2 — PASS
- iCloud Drive cache (CloudDocs): not in top consumers — ok

## Recommendations
None.

## Summary
Disk is healthy — caches tight, no orphaned CLI sessions.
```

## Install

```bash
git clone https://github.com/<you>/storage-health-check.git ~/.claude/skills/storage-health-check
chmod +x ~/.claude/skills/storage-health-check/scripts/collect.sh
```

Restart Claude Code so the `/` picker picks it up. Then either:
- Type `/storage-health-check`, or
- Say any trigger phrase: "check my storage", "disk check", "how's my storage", "am I running out of space", etc.

## Requirements

- macOS (uses `df`, `du`, `ps` — default system tools)
- [Claude Code](https://claude.com/claude-code) CLI
- `bc` (bundled with macOS)

## Customize

Thresholds live in [`SKILL.md`](SKILL.md) — edit the "Apply Thresholds" table to match your setup. Defaults are conservative and work for most Macs:

| Probe | PASS | WARN | FAIL |
|---|---|---|---|
| Free space | > 15% | 5–15% | < 5% |
| Single Caches folder | < 10 GB | 10–50 GB | > 50 GB |
| Single Application Support folder | < 20 GB | 20–100 GB | > 100 GB |
| Trash | < 10 GB | 10–50 GB | > 50 GB |
| Claude Code CLI processes | ≤ 3 | 4–6 | > 6 |

Heavy iCloud users: `CloudDocs` is expected to be large and is flagged as expected, not a problem, unless it dominates the drive.

## How it works

The skill has two parts:

1. **[`scripts/collect.sh`](scripts/collect.sh)** — a ~40-line bash script that runs the probes and outputs structured key-value data. Read-only, no dependencies beyond macOS defaults.
2. **[`SKILL.md`](SKILL.md)** — the prompt Claude uses to interpret the data, apply thresholds, and format the report.

The script does the heavy lifting (filesystem scans) so Claude just does interpretation — keeps runtime and token cost down.

## Contributing

Issues and PRs welcome. Good candidates for improvement:
- Linux / Windows portability (currently macOS-only)
- Additional probes (Xcode DerivedData, Mail database, Homebrew cellar)
- Per-user threshold config file

## License

MIT — see [LICENSE](LICENSE).
