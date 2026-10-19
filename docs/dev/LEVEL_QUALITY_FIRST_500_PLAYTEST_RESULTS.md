# First-500 playtest results

Status: **PENDING — no human playtest sessions recorded in this pass.**

Do not treat empty tables as neutral scores. Measurements and ratings below
must be filled only from real players. Worksheet and protocol:
`LEVEL_QUALITY_FIRST_500_PLAYTEST.md`. Audit baseline:
`LEVEL_QUALITY_FIRST_500_REMEDIATION.md`.

---

## 1. Participants and sessions

| Metric | Value |
|---|---|
| Participants | **0** |
| Completed sessions | **0** |
| Session labels | — |
| Human testing occurred | **No** |

---

## 2. Environment

| Item | Status |
|---|---|
| Interactive sandbox code | Prepared (`ENABLE_FIRST500_PLAYTEST`) |
| Screenshot harness | Used for Priority 0 visual A/B (see §8) |
| Emulator | Available during prep (`emulator-5554`); **no human play session logged** |
| Physical Android device | **Not used** for playtest |
| Arabic RTL visual check | **Not performed** |
| Light/dark harness themes | Per snapshot commands in playtest doc |

---

## 3. Original vs candidate (levels that differ)

*No human A/B results yet.*

| Level | Completions O/C | Median time O/C | Retries O/C | Notes |
|---|---|---|---|---|
| — | — | — | — | Pending |

---

## 4. Aggregated measurements (sample counts)

*Empty until sessions exist.*

| Level | n | Complete % | Median time | Median retries | Hints (median) |
|---|---|---|---|---|---|
| — | 0 | — | — | — | — |

Subjective ratings (Clarity / Fairness / Challenge / Visual) — **not filled**.

---

## 5. Major findings

### Fairness
Pending human observation.

### Duration / campaign rhythm
Pending. Static audit still flags Phase 2A median peel ~10 and 250→251 cliff.

### Readability
Harness screenshots prepared for P0 IDs; human/device confirmation pending.

### Phase 2A trap fatigue (49 traps in 251–300)
Pending consecutive-play observation. No traps removed in this pass.

---

## 6. Most problematic candidate levels

*None identified by humans yet.* Static watch list from integration report:
250→251 cliff, 255/270 trap density, shorts 463/474/481/487/488, small-cell
specials 10/24.

---

## 7. Improvement decisions

| Item | Decision |
|---|---|
| Accept as-is for merge | **Not decided** (awaiting playtest) |
| Refine Phase 2A traps | **More evidence required** |
| Expand mid 25–250 replacements | **More evidence required** |
| Inflate peel toward production | **Not mandated**; await feel |
| Begin 501–1000 remediation | **Blocked** until gate review |

---

## 8. Visual harness notes (non-human)

Generated this pass under
`build/candidates/first_500_quality/playtest_snapshots/`:

| Folder | Content | Count |
|---|---|---|
| `original/` | P0 IDs, phone 366×600, light | 20 PNGs (18 levels + 2 pressed helpers) |
| `candidate/` | Same P0 set, light | 20 PNGs |
| `candidate_dark/` | Sample specials/traps, light+dark | 16 PNGs |

P0 IDs: 3,4,12,24,25,50,97,210,217,220,230,239,250,251,255,270,300,301.

Harness viewport ≠ device touch validation. Emulator was attached
(`emulator-5554`) during prep but **no on-device visual play session** was
logged. Arabic RTL: **not** checked.

---

## 9. Limitations

- Sample size: **0** human sessions.
- No claim of enjoyment, fairness, or difficulty from players.
- Emulator presence during engineering prep ≠ completed playtest.
- Incomplete reachability on large specials remains an audit limitation.

---

## 10. Decision gate summary

| Outcome | Selected? |
|---|---|
| Accept | No |
| Refine | No (not yet evidenced) |
| **Hold** | **Yes — awaiting human playtest review** |

**Do not start levels 501–1000 quality remediation until this gate moves off
Hold after real sessions are reviewed.**
