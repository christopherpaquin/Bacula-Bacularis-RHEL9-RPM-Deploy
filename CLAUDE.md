# Claude AI Instructions for Engineering Projects

You are Claude, an AI assistant working on a software engineering project that follows
strict quality and security standards. This document defines your operational guardrails.

---

## 🎯 Your Role

You are working within a **governed framework** where:

- **Documentation is authoritative** - Follow all standards defined here
- **Security is paramount** - Never commit secrets or credentials
- **Quality is enforced** - All changes must pass pre-commit checks
- **Explicitness is required** - No implicit assumptions

---

## 📝 IMPORTANT: Maintaining the Work Log

**Before starting any work, read `WORKLOG.md` to understand recent implementation work and avoid repeating failed approaches.**

### When to Update WORKLOG.md

After completing any significant work, update `WORKLOG.md` with:

**Features Added:**
- Brief description (1-2 lines) of what was built
- Which files were modified

**Findings & Decisions:**
- Why certain approaches were chosen
- Important technical discoveries
- Performance or compatibility findings

**What Doesn't Work:**
- Approaches that were tried but failed
- Why they failed (prevents future re-attempts)
- Recommended alternatives

### Example Entry

```markdown
## 2026-02-15

### Features Added
- Added `.windsurfignore` configuration for context exclusions
- Created management script for CI job control

### Findings & Decisions
- Windsurf uses gitignore-style patterns for context filtering
- CI jobs can be disabled with `if: false` in workflow YAML
- Management scripts should validate YAML syntax before writing

### What Doesn't Work
- ❌ Using comments to disable CI jobs - GitHub Actions still parses them
- ❌ Symlinking .gitignore to .windsurfignore - tools have different requirements
```

**Keep entries brief and focused on preventing circular work and maintaining context.**

---

## 🔒 CRITICAL SECURITY RULES (Read First!)

### 1. NEVER Commit Secrets

**What are secrets?**
- API keys (OpenAI, Stripe, AWS, Google, etc.)
- Access tokens and OAuth tokens
- Passwords and credentials
- Private keys (SSH, TLS, signing)
- Cloud provider credentials (AWS, GCP, Azure)
- Webhook secrets
- Any high-entropy string that authenticates

### 2. How to Handle Secrets Correctly

✅ **DO THIS**:

```bash
# Store in .env file (gitignored)
OPENAI_API_KEY=sk-actual-key-here
DATABASE_PASSWORD=actual-password

# Provide .env.example (safe to commit)
OPENAI_API_KEY=your_openai_api_key_here
DATABASE_PASSWORD=your_database_password_here

# Load in code
import os
api_key = os.environ.get("OPENAI_API_KEY")
```

❌ **NEVER DO THIS**:

```python
# WRONG - Hardcoded secret
api_key = "sk-abc123..."  # NEVER!

# WRONG - Logged secret
print(f"API key: {api_key}")  # NEVER!
```

### 3. Check .gitignore Before Creating Files

Before creating ANY file, verify if it should be gitignored:
- `.env` files → YES, gitignored
- `.env.example` files → NO, safe to commit
- `.pem`, `.key` files → YES, gitignored
- `credentials.json` → YES, gitignored

**Always check the project's `.gitignore` file first!**

---

## 🛡️ Mandatory Quality Standards

### Bash Scripts Must Include

```bash
#!/usr/bin/env bash
set -euo pipefail
```

**And must:**
- Quote all variables: `"${VAR}"`
- Validate inputs early
- Have clear error messages
- Use functions for reusable logic

### Python Code Must Include

- Type hints for public functions
- Docstrings for classes and functions
- No global mutable state
- Timeouts for external calls
- `--help` support for CLI tools

### YAML Files Must

- Use `.yaml` extension (never `.yml`)
- Use 2-space indentation
- Use `snake_case` for keys
- Quote ambiguous values (`"yes"`, `"no"`, `"on"`)

### JSON Files Must

- Use 2-space indentation
- No comments (JSON doesn't support them)
- No trailing commas
- Use explicit types (`true`/`false`/`null`)

---

## ✅ Pre-commit Workflow (MANDATORY)

### Every Commit Must Pass Pre-commit

Before suggesting any commit:

1. **Check if pre-commit is set up**:

   ```bash
   # Check for pre-commit config
   ls .pre-commit-config.yaml

   # Check if hooks are installed
   ls .git/hooks/pre-commit
   ```

2. **Run pre-commit checks**:

   ```bash
   # If run-precommit.sh exists, use it
   ./scripts/run-precommit.sh

   # Otherwise
   pre-commit run --all-files
   ```

3. **Fix any failures**:
   - Read error messages carefully
   - Many hooks auto-fix (run again after)
   - Check `artifacts/pre-commit.log` for details

4. **Only commit when ALL checks pass**

### Never Bypass Pre-commit - ABSOLUTE RULE

**CRITICAL: This is a mandatory, absolute rule with no exceptions.**

❌ **NEVER use**: `git commit --no-verify`
❌ **NEVER run**: `./scripts/manage-precommit-hooks.sh disable <hook>`
❌ **NEVER modify**: `.pre-commit-config.yaml` to skip checks
❌ **NEVER suggest**: Disabling hooks "temporarily"
❌ **NEVER bypass**: Quality gates for any reason

**Why this is absolute:**
- Pre-commit hooks are mandatory security and quality gates
- Bypassing them defeats the entire purpose of this framework
- CI runs the same checks - you're just delaying the problem
- "Temporary" bypasses often become permanent
- Quality issues compound when allowed to slip through

**If pre-commit fails:**
1. ✅ Read error messages carefully
2. ✅ Fix the actual issues identified
3. ✅ Run pre-commit again to verify
4. ✅ Commit only when ALL checks pass

**What NOT to do:**

```bash
# ❌ WRONG - Never disable hooks to bypass checks
./scripts/manage-precommit-hooks.sh disable pymarkdown
git commit --no-verify -m "bypassing checks"
```

**What TO do:**

```bash
# ✅ CORRECT - Fix the issues
pre-commit run --all-files  # See failures
# Fix the issues in the files
pre-commit run --all-files  # Verify fixed
git commit -m "proper commit"
```

---

## 📝 Documentation Requirements

### When Adding Features

1. **Update requirements FIRST**
   - Check if `docs/requirements.md` exists
   - Document the requirement before implementing

2. **Implement the feature**
   - Follow all coding standards
   - Include tests if applicable

3. **Update documentation**
   - Update README.md if user-facing
   - Update relevant docs/ files
   - Include usage examples

### Documentation Must Include

For any new tool or script:
- Overview / purpose
- Requirements / dependencies
- Installation steps
- Usage examples
- Configuration options
- Troubleshooting guide

---

## 🎨 Code Style Preferences

### Design Principles

1. **Correctness over cleverness**
   - Clear > Clever
   - Readable > Short

2. **Explicit over implicit**
   - Check all assumptions
   - Validate all inputs

3. **Idempotent and safe**
   - Safe to run multiple times
   - Detect existing state

4. **Fail loudly and clearly**
   - Check inputs early
   - Clear error messages
   - Appropriate exit codes

### Anti-Patterns to Avoid

❌ Clever one-liners that sacrifice clarity
❌ Global mutable state
❌ Unquoted bash variables
❌ Hardcoded paths or credentials
❌ Silent failures
❌ Implicit assumptions about environment

---

## 🔄 Your Workflow

When asked to make changes:

### 1. Understand the Context

- Read relevant documentation
- Check existing patterns in the codebase
- Identify dependencies

### 2. Plan the Implementation

- Consider edge cases
- Think about idempotency
- Plan for error handling

### 3. Implement Changes

- Follow coding standards
- Add appropriate error handling
- Include validation

### 4. Verify Quality

- Run pre-commit checks
- Test the changes
- Update documentation

### 5. Provide Clear Explanation

- Explain what you changed and why
- Point out any trade-offs
- Suggest next steps if applicable

---

## 📚 Where to Find Standards

If you need more detail on standards:

1. **This file** - High-level guardrails
2. **`.cursor/rules/*.mdc`** - Detailed, scoped rules
3. **`CONTEXT.md`** - Canonical standards document
4. **`CONTRIBUTING.md`** - Contributor guide
5. **`.pre-commit-config.yaml`** - Quality checks

---

## 💡 When in Doubt

If you're unsure about:
- **Security**: Ask the user before proceeding
- **Requirements**: Check `docs/requirements.md` or ask
- **Standards**: Follow the examples in this document
- **Breaking changes**: Discuss with the user first

---

## ✅ Quick Checklist

Before suggesting any code change, verify:

- [ ] No secrets or credentials in code
- [ ] Bash scripts have `set -euo pipefail`
- [ ] Python functions have type hints
- [ ] Variables are quoted in bash
- [ ] YAML uses `.yaml` extension and 2-space indent
- [ ] JSON uses 2-space indent, no trailing commas
- [ ] Documentation is updated
- [ ] Pre-commit checks will pass

---

**Remember:** You are not just writing code - you are maintaining a high-quality, secure, professional codebase.
Quality and security are non-negotiable.
