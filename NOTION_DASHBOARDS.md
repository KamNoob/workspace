# NOTION DASHBOARDS - Your Mission Control

Two Notion databases for complete visibility into what Morpheus is working on:

## 1. Task Board 📋
**URL:** https://www.notion.so/5680631beb20434f9388b8db1ab4356c

**Purpose:** Active work tracking  
**What's here:** Individual tasks, their status, who's working on them  
**Updated:** Real-time as work happens  

| Field | Example |
|-------|---------|
| Task | "Build task board for Art" |
| Status | To Do → In Progress → Done |
| Assigned To | Art or Morpheus |
| Priority | Low / Medium / High |
| Due Date | When it should be done |
| Description | Task details |
| Notes | Progress updates |

---

## 2. Scheduled Tasks 🚀
**URL:** https://www.notion.so/b9eaba8909cf4f64bc7c3dc260c95d76

**Purpose:** Scheduled automation tracking  
**What's here:** Cron jobs, scheduled tasks, heartbeat checks  
**Updated:** When new schedules are created or statuses change  

| Field | Example |
|-------|---------|
| Task | "Daily email summary" |
| Type | One-time / Recurring / Heartbeat |
| Status | Scheduled → Running → Completed |
| Schedule | `0 8 * * *` (8am daily) |
| Next Run | 2026-02-21 |
| Description | What it does |
| Job ID | Reference ID from OpenClaw |
| Notes | Results, errors, updates |

---

## Quick Reference

### Task Board = "What am I currently doing?"
Use this to see active work, check priorities, update progress, or assign new tasks.

### Scheduled Tasks = "What's scheduled to happen?"
Use this to verify I'm automating the right things on the right schedule, and catch any issues before they happen.

---

## Your Workflow

1. **Assign a task** → Goes to Task Board
2. **I work on it** → Update status, add notes
3. **Schedule automation** → Goes to Scheduled Tasks
4. **Verify it works** → Check next run date and status updates

---

**Both databases:** Shared workspace (30d1ae7a-37e2-8000-bad9-d97541e42241)  
**Last updated:** 2026-02-20 10:00 GMT
