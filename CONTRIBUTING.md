# Contributing Guide

This repository provides AI coding assistant guardrails for software engineering projects.
Contributors (both human and AI) must follow these standards.

---

## 🤖 For AI Coding Assistants

### Quick Start

**You MUST read these files first:**

1. **`CLAUDE.md`** (if you're Claude) - Your operational guardrails
2. **`.cursor/rules/*.mdc`** (if you're Cursor) - Scoped, prioritized rules
3. **`WORKLOG.md`** - Recent implementation work and findings (read FIRST!)
4. **`CONTEXT.md`** - Canonical standards document

**After completing work:**

- **Update `WORKLOG.md`** with what you built, decisions made, and what doesn't work
- See `WORKLOG_USAGE.md` for detailed instructions

### Critical Requirements

#### 1. Security (HIGHEST PRIORITY)

**NEVER commit secrets:**

- API keys, tokens, passwords, credentials
- Private keys (`.pem`, `.key`, SSH keys)
- Cloud provider credentials
- ANY authentication material

**How to handle secrets:**

- ✅ Store in `.env` files (gitignored)
- ✅ Provide `.env.example` with placeholders
- ✅ Load from environment in code
- ❌ NEVER hardcode in source code
- ❌ NEVER log or print secret values

#### 2. Pre-commit Checks (MANDATORY)

ALL commits must pass pre-commit:

```bash

# Run before every commit

./scripts/run-precommit.sh

# Or if that doesn't exist

pre-commit run --all-files
```

**NEVER BYPASS PRE-COMMIT HOOKS:**

- ❌ **NEVER** use `git commit --no-verify`
- ❌ **NEVER** disable hooks with `./scripts/manage-precommit-hooks.sh disable`
- ❌ **NEVER** modify `.pre-commit-config.yaml` to skip checks
- ❌ **NEVER** suggest or attempt to bypass quality gates

**This is an absolute rule with no exceptions.**

Pre-commit hooks exist for security, quality, and consistency. Bypassing them
defeats the entire purpose of this framework. If hooks fail, fix the issues -
don't bypass the checks.

#### 3. Coding Standards

**Bash:**

```bash

#!/usr/bin/env bash
set -euo pipefail

# Quote all variables: "${VAR}"
```

**Python:**

```python

def function_name(arg: str) -> bool:
    """Include type hints and docstrings."""
    pass
```

**YAML:**

- Use `.yaml` extension (never `.yml`)
- 2-space indentation
- `snake_case` keys

**JSON:**

- 2-space indentation
- No trailing commas
- No comments

#### 4. Documentation

When changing code, update:

- **WORKLOG.md** (brief entry documenting what was done)
- README.md (if user-facing changes)
- Relevant docs/ files
- Inline comments (explain WHY, not WHAT)

**WORKLOG.md entries should include:**
- Features Added (1-2 lines)
- Findings & Decisions (why certain approaches were chosen)
- What Doesn't Work (failed approaches to avoid repeating)

---

## 👥 For Human Contributors

### Setup Your Environment

#### 1. Install Prerequisites

```bash

# Python 3.11+ required

python3 --version

# Install pre-commit

pip install pre-commit
```

#### 2. Clone and Setup

```bash

# Clone the repository

git clone <repo-url>
cd Guardrails-AI

# Read recent work (IMPORTANT)
cat WORKLOG.md

# Install pre-commit hooks (REQUIRED)

pre-commit install
pre-commit install --hook-type commit-msg

# Verify setup

pre-commit run --all-files
```

### Development Workflow

#### 1. Before Making Changes

- **Read `WORKLOG.md`** - Check recent work and findings
- Read relevant `.cursor/rules/*.mdc` files
- Check `CONTEXT.md` for detailed standards
- Understand the existing patterns

#### 2. Making Changes

- Follow coding standards strictly
- Test your changes thoroughly
- Update documentation
- **Document work in progress** for complex tasks

#### 3. Before Committing

```bash

# Update worklog with your changes
vim WORKLOG.md  # Add entry for today

# Run quality checks
pre-commit run --all-files

# Fix any issues
# Many are auto-fixed - run again after

# Commit only when all checks pass
git add <files>
git commit -m "Clear, descriptive message"
```

**WORKLOG.md Entry Example:**

```markdown
## 2026-02-15

### Features Added
- Implemented user authentication with JWT tokens
- Added password reset flow via email

### Findings & Decisions
- JWT refresh tokens stored in httpOnly cookies for XSS protection
- Email service uses SendGrid API with rate limiting

### What Doesn't Work
- ❌ Storing tokens in localStorage - vulnerable to XSS
- ❌ Using nodemailer directly - unreliable without proper queue
```

#### 4. Creating Pull Requests

- Ensure all CI checks pass
- Provide clear description of changes
- Link to related issues
- Include test results if applicable

### Quality Gates

This repository enforces quality through:

| Gate | What It Checks | When It Runs |
|------|----------------|--------------|
| **Pre-commit (local)** | Formatting, linting, secrets | Before commit |
| **Commit-msg hook** | Message validation | On commit |
| **CI/CD** | Same checks as pre-commit | On push/PR |
| **Code review** | Logic, design, completeness | On PR |

**All gates must pass** - no exceptions.

---

## 📋 Coding Standards Summary

### Design Principles

1. ✅ **Correctness over cleverness** - Clear beats clever
2. ✅ **Explicit over implicit** - No assumptions
3. ✅ **Idempotent and safe** - Safe to re-run
4. ✅ **Fail loudly** - Clear errors, early validation
5. ✅ **Maintainable** - Boring, standard solutions

### Security Checklist

Before committing ANY file:

- [ ] Contains no secrets or credentials
- [ ] Secrets are in `.env` (gitignored)
- [ ] Provided `.env.example` with placeholders
- [ ] Checked `.gitignore` for file type
- [ ] No hardcoded paths or credentials

### Code Quality Checklist

- [ ] Bash: Has `set -euo pipefail`, quotes variables
- [ ] Python: Has type hints, docstrings
- [ ] YAML: Uses `.yaml`, 2-space indent
- [ ] JSON: 2-space indent, no trailing commas
- [ ] Comments explain WHY, not WHAT
- [ ] Error messages are clear and actionable

### Documentation Checklist

- [ ] **WORKLOG.md updated** (features, findings, failed approaches)
- [ ] README.md updated (if needed)
- [ ] Relevant docs/ files updated
- [ ] Usage examples provided
- [ ] Breaking changes documented

**For WORKLOG.md details, see [`WORKLOG_USAGE.md`](WORKLOG_USAGE.md)**

---

## 🐛 Reporting Issues

### Bug Reports

Include:

- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, Python version)
- Error messages and logs

### Feature Requests

Include:

- Problem statement (what problem does this solve?)
- Proposed solution
- Alternative approaches considered
- Impact assessment

---

## 🔍 Code Review Guidelines

### What Reviewers Look For

1. **Security**
   - No secrets in code
   - Proper input validation
   - Safe file handling

2. **Quality**
   - Follows coding standards
   - Has appropriate tests
   - Clear, maintainable code

3. **Documentation**
   - Changes are documented
   - Usage examples provided
   - Breaking changes called out

4. **Completeness**
   - All edge cases handled
   - Error handling appropriate
   - Idempotent and safe

### Review Etiquette

- Be constructive and specific
- Explain the "why" behind suggestions
- Acknowledge good work
- Focus on the code, not the person

---

## 📚 Learning Resources

- **`.cursor/rules/*.mdc`** - Detailed coding standards with examples
- **`CONTEXT.md`** - Complete canonical standards
- **`CLAUDE.md`** - AI assistant instructions (good for humans too!)
- **`.pre-commit-config.yaml`** - See what quality checks run

---

## ❓ Questions or Help?

- Check existing documentation first
- Review `.cursor/rules/*.mdc` for examples
- Look at existing code for patterns
- Ask in issues or discussions

---

## 🎯 TL;DR

For AI assistants:
1. Read `CLAUDE.md` or `.cursor/rules/*.mdc`
2. Never commit secrets
3. Run pre-commit before commits
4. Follow coding standards

For humans:
1. Install pre-commit: `pip install pre-commit && pre-commit install`
2. Run checks before commits: `pre-commit run --all-files`
3. Follow coding standards in `.cursor/rules/*.mdc`
4. Update documentation with code changes

**Quality and security are non-negotiable. All checks must pass.**
