# Usage Tracking — Claude Pro (5-Hour Cycle)

## Method

**Passive tracking:** I track message count as we interact. No cron job.

**Limit:** ~45 messages per 5-hour rolling window

**Thresholds:**
- 15 messages → Baseline (1/3 through)
- 30 messages → Caution (2/3 through, wrap large tasks)
- 40+ messages → Critical (limit approaching)
- 45 messages → Blocked (wait for reset)

## Session Log

| Date | Time | Messages Used | Messages Remaining | Next Reset | Notes |
|------|------|---|---|------------|-------|
| 2026-03-01 | 09:47 | ~2 | ~43 | ~10:53 | Initial baseline |
| 2026-03-01 | 11:25 | ~3 | ~42 | ~15:44 | Current cycle |

---

**Ref:** https://support.claude.com/en/articles/11647753-understanding-usage-and-length-limits
