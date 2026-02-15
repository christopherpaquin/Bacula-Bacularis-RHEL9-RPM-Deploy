# 📝 WORKLOG.md Usage Guide

**Purpose:** This guide explains how to use `WORKLOG.md` for tracking AI agent implementation work and maintaining context across sessions.

---

## 🎯 What is WORKLOG.md?

`WORKLOG.md` is an **implementation tracking log** that:

- **Documents what features were built** (brief summaries)
- **Records important findings and decisions** (why certain approaches work)
- **Tracks what doesn't work** (prevents repeating failed experiments)
- **Maintains context** across multiple AI agent sessions
- **Prevents circular debugging** and backtracking

---

## 🆚 WORKLOG.md vs CONTEXT.md

| File | Purpose | Update Frequency | Content |
|------|---------|------------------|---------|
| **CONTEXT.md** | Standards (HOW to code) | Rarely | Design principles, security rules, coding standards |
| **WORKLOG.md** | Implementation tracking (WHAT was done) | Frequently | Features, findings, failed approaches |

**Key difference:**
- `CONTEXT.md` = "Never commit secrets, use type hints, quote bash variables"
- `WORKLOG.md` = "Built authentication system, tried JWT but Redis sessions work better"

---

## 👥 Who Uses WORKLOG.md?

### For AI Agents

**When starting work:**
1. Read `WORKLOG.md` FIRST to understand recent work
2. Check if similar work has been attempted
3. Learn from documented successes and failures

**When completing work:**
1. Update `WORKLOG.md` with what you built
2. Document important decisions made
3. Record approaches that didn't work

**AI agents are instructed to use WORKLOG.md in:**
- `AGENTS.md` (section 2.1)
- `CLAUDE.md` (after "Your Role")
- `.cursor/rules/001_workspace.mdc`
- `README.md` (documentation section)

### For Human Developers

**When onboarding:**
- Read recent entries to understand project evolution
- Learn what approaches have been tried

**When opening new AI sessions:**
- Prompt agent: "Read WORKLOG.md before starting"
- After work: "Update WORKLOG.md with what you did"

**When debugging:**
- Check if issue has been encountered before
- Review what solutions worked or didn't work

---

## 📋 Entry Format

Each entry should include:

```markdown
## YYYY-MM-DD

### Features Added
- Brief description (1-2 lines) of what was built
- Which files/components were affected

### Findings & Decisions
- Why certain approaches were chosen
- Important technical discoveries
- Performance or compatibility insights

### What Doesn't Work
- Approaches that were tried but failed
- Why they failed (specific reasons)
- Recommended alternatives to try instead
```

---

## ✅ Good Entry Examples

### Example 1: Feature Implementation

```markdown
## 2026-02-15

### Features Added
- Implemented JWT authentication with refresh tokens
- Added middleware for protected routes in `src/middleware/auth.ts`
- Created token refresh endpoint `/api/auth/refresh`

### Findings & Decisions
- JWT access tokens expire in 15 minutes, refresh tokens in 7 days
- Storing refresh tokens in httpOnly cookies prevents XSS attacks
- Redis chosen for token blacklist - 10x faster than database queries

### What Doesn't Work
- ❌ Storing JWT in localStorage - vulnerable to XSS attacks
- ❌ Long-lived access tokens - can't revoke without blacklist overhead
- ❌ Database queries for every auth check - too slow (200ms vs 2ms with Redis)
```

### Example 2: Bug Investigation

```markdown
## 2026-02-20

### Features Added
- Fixed memory leak in WebSocket connection handler
- Added connection cleanup in `src/websocket/manager.ts`

### Findings & Decisions
- WeakMap for connection tracking prevents memory leaks
- Must call `socket.terminate()` not just `socket.close()` for cleanup
- Connection pool limit set to 1000 concurrent connections

### What Doesn't Work
- ❌ Using Map for connections - causes memory leak (no automatic cleanup)
- ❌ Relying on client disconnect event - unreliable with network issues
- ❌ setTimeout for cleanup - race conditions with rapid reconnects
```

### Example 3: Infrastructure Change

```markdown
## 2026-02-25

### Features Added
- Migrated CI/CD from CircleCI to GitHub Actions
- Added workflow files: `.github/workflows/ci.yaml`, `security-ci.yml`
- Integrated Codecov for test coverage reporting

### Findings & Decisions
- GitHub Actions 30% faster for our workload (8min vs 12min)
- Free tier includes 2000 minutes/month - sufficient for project
- Matrix testing across Python 3.9, 3.10, 3.11 working correctly

### What Doesn't Work
- ❌ Using actions/setup-python@v2 - outdated, use v4 or v5
- ❌ Caching ~/.cache/pip - doesn't work on GitHub runners (use pip cache dir)
- ❌ Running security scans on every PR - too slow, moved to cron schedule
```

---

## ❌ Bad Entry Examples

### Too Vague

```markdown
## 2026-02-15

### Features Added
- Fixed some stuff
- Updated files

### Findings & Decisions
- Made it work better

### What Doesn't Work
- Some things didn't work
```

**Problem:** No actionable information. Future readers won't know what was done or why.

### Too Detailed

```markdown
## 2026-02-15

### Features Added
- Modified src/auth/jwt.ts line 45 to change token expiry from 3600 to 900
- Updated src/middleware/auth.ts lines 23-67 with new validation logic
- Changed import statements in 12 files to use new auth module
- Added 3 new test files with 47 test cases covering edge cases
- Updated package.json to include jsonwebtoken@9.0.0
- Modified tsconfig.json compiler options for better type checking
- etc...
```

**Problem:** Too detailed, more like git commit messages. Should summarize at feature level.

### No Context

```markdown
## 2026-02-15

### Features Added
- Added JWT authentication

### Findings & Decisions
- JWT is good

### What Doesn't Work
- Other approaches
```

**Problem:** No explanation of WHY decisions were made or WHAT specifically doesn't work.

---

## 🔄 Workflow

### Manual User Workflow (Recommended)

As a human developer working with AI agents:

**1. Start of session:**
```
Prompt: "Before starting, read WORKLOG.md to understand recent work."
```

**2. During development:**
```
Agent does work...
```

**3. After completing work:**
```
Prompt: "Update WORKLOG.md with:
- What you just implemented
- Key decisions made
- Any approaches that didn't work

Keep each section to 1-3 lines."
```

**4. Review and commit:**
```bash
# Review the worklog entry
cat WORKLOG.md

# Commit with both code and worklog
git add .
git commit -m "feat: implement authentication

Updated WORKLOG.md with implementation details."
```

### Example Prompts

**Starting work:**
```
"Read WORKLOG.md. Has JWT authentication been attempted before?"

"Check WORKLOG.md - what approaches didn't work for caching?"

"Review recent WORKLOG.md entries before implementing this feature."
```

**Updating log:**
```
"Add an entry to WORKLOG.md documenting this implementation."

"Update WORKLOG.md with the WebSocket fix and why setTimeout didn't work."

"Document in WORKLOG.md why we chose Postgres over MongoDB for this feature."
```

---

## 🛠️ Maintenance

### When to Archive

If `WORKLOG.md` grows beyond **500 lines**, archive old entries:

```bash
# Create archive file
mv WORKLOG.md WORKLOG_ARCHIVE_2026.md

# Create fresh WORKLOG.md with recent entries
# Keep last 2-3 months of entries
```

**Update `WORKLOG.md`:**
```markdown
# Implementation Work Log

**Archived logs:**
- [2024-2025 Archive](./WORKLOG_ARCHIVE_2024-2025.md)
- [2026 Archive](./WORKLOG_ARCHIVE_2026.md)

---

## 2026-10-01

### Features Added
...
```

### Keeping It Current

**Stale logs are useless.** Update regularly:

✅ **Good practice:**
- Update after each significant feature or change
- Update when discovering important findings
- Update when encountering dead ends

❌ **Bad practice:**
- Updating once per month (too infrequent)
- Never updating (defeats the purpose)
- Updating with vague entries (no value)

---

## 🎓 Best Practices

### 1. Be Concise

- 1-3 lines per item
- Focus on key information
- Avoid implementation details (save for code comments)

### 2. Be Specific

- Name specific files, components, or technologies
- Include concrete reasons for decisions
- Document specific error messages or failure modes

### 3. Be Actionable

- Future readers should understand what was done
- Provide enough context to avoid repeating mistakes
- Document alternatives to try instead of failed approaches

### 4. Update Regularly

- Don't let entries pile up
- Update soon after completing work (while fresh)
- Review entries periodically for accuracy

### 5. Focus on "Why"

- **Not**: "Added caching"
- **Better**: "Added Redis caching - 10x faster than database queries"

### 6. Document Failures

- Failed experiments are valuable
- Prevents wasted time re-attempting
- Often more useful than success stories

---

## 📊 Benefits

### For AI Agents

- ✅ **Context preservation** across sessions
- ✅ **Prevents hallucination** (documented facts to reference)
- ✅ **Avoids circular work** (knows what was tried)
- ✅ **Faster onboarding** (reads log before starting)

### For Human Developers

- ✅ **Project history** without reading all commits
- ✅ **Decision rationale** (why things were built this way)
- ✅ **Troubleshooting aid** (similar issues documented)
- ✅ **Onboarding tool** (new developers read recent log)

### For Projects

- ✅ **Institutional knowledge** captured
- ✅ **Reduced rework** (failed approaches documented)
- ✅ **Better handoffs** (context preserved)
- ✅ **Audit trail** of technical decisions

---

## 🔗 Related Documentation

- **AGENTS.md** - Section 2.1 covers worklog workflow
- **CLAUDE.md** - Instructions for Claude to use WORKLOG.md
- **CONTEXT.md** - Coding standards (separate from implementation log)
- **README.md** - Documentation overview

---

## 📞 Questions?

**How is this different from git commit messages?**
- Commit messages: granular, per-change
- WORKLOG.md: summary, feature-level, includes failures

**Should I document every commit?**
- No, document significant features, findings, or dead ends
- Group related commits into one entry

**What if I forget to update it?**
- Update before opening a new AI session
- Review weekly and add missing entries

**Can I use it for non-AI work?**
- Yes! It's valuable for any development work
- Especially useful for context switching

---

**Remember:** The goal is to prevent circular work and maintain context, not to replace git history or documentation.
