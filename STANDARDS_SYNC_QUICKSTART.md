# Standards Synchronization - Quick Start Guide

**Status:** Design Phase + Proof of Concept

**Purpose:** Automate propagation of CONTEXT.md changes to tool-specific AI configurations.

---

## 🎯 The Problem

Currently, when you update CONTEXT.md, you must manually update 7+ tool-specific config files. This is tedious and
error-prone.

## ✅ The Solution

Automated synchronization with preprocessing and tool-specific optimization:

```text
CONTEXT.md → Parser → Preprocessor → AI Enhancement → Tool Configs
  (source)            (structure)    (transform)     (optimize)     (outputs)
```

---

## 🚀 Quick Demo

**Try the proof-of-concept:**

```bash
# Dry run (see what would be generated)
python3 scripts/sync-standards-poc.py --dry-run

# Output shows:
# - Cursor rules (.mdc format, imperative style)
# - Claude instructions (conversational style)
# - GitHub Copilot (concise, example-heavy)
```

**Example transformation for same rule:**

### Source (CONTEXT.md)

```markdown
All bash scripts must start with set -euo pipefail for safety.
```

### Output (Cursor - Imperative)

```markdown
## Use Safe Bash Options

All bash scripts MUST start with set -euo pipefail for safety.

✅ **CORRECT:**

```bash
#!/usr/bin/env bash
set -euo pipefail
```

```markdown

### Output (Claude - Conversational)

```markdown
### Use Safe Bash Options

You must start all bash scripts with set -euo pipefail for safety.

**Why this matters:**
These options prevent silent failures and make scripts more reliable.

✅ **Do this:**
[example with explanation]
```

### Output (Copilot - Concise)

```markdown
## Use Safe Bash Options

All bash scripts must start with set -euo pipefail.

```bash
# ❌ Bad
#!/bin/bash

# ✅ Good
#!/usr/bin/env bash
set -euo pipefail
```

```markdown

---

## 📋 Full Design

See **[STANDARDS_SYNC_DESIGN.md](./STANDARDS_SYNC_DESIGN.md)** for complete architecture, implementation phases,
and technical details.

---

## 🔄 Proposed Workflow

When implemented, updating standards will be:

```bash
# 1. Update CONTEXT.md
vim CONTEXT.md

# 2. Run sync script
./scripts/sync-standards.sh

# 3. Review changes
git diff

# 4. Test with AI tools (manual verification)
# Open Cursor, ask it about the rule
# Open Claude, verify it follows the rule

# 5. Commit all together
git add CONTEXT.md .cursor/ CLAUDE.md .github/ .aider/ .continue/
git commit -m "Add rule: [rule name]"
```

**Time saved:** 15-30 minutes per update → 2 minutes

---

## 🎓 Key Features

### 1. Preprocessing Pipeline

Each rule goes through transformation:

```python
# Cursor transformer
def make_imperative(text):
    return text.replace("should", "MUST").replace("never", "NEVER")

# Claude transformer
def make_conversational(text):
    if not text.startswith("You"):
        text = "You " + text.lower()
    return text

# Copilot transformer
def make_concise(text):
    return text.split('.')[0] + '.'  # First sentence only
```

### 2. Tool-Specific Templates

Each tool has a template:

**Cursor Template:**

```text
---
priority: {priority}
globs: {scope}
---

## {title}

{imperative_content}

✅ **CORRECT:** {example}
❌ **WRONG:** {counter_example}
```

**Claude Template:**

```text
### {title}

{conversational_content}

**Why this matters:** {reasoning}

✅ **Do this:** {example_with_explanation}
```

### 3. Optional AI Enhancement

Use AI to optimize natural language:

```bash
# Without AI (template-based)
./scripts/sync-standards.sh

# With AI enhancement (requires API key)
./scripts/sync-standards.sh --with-ai
```

AI enhancement can:

- Refine natural language per tool
- Generate better examples
- Add tool-specific context
- Optimize for each tool's "personality"

### 4. Validation

Automatic checks:

- ✅ All files exist
- ✅ Valid syntax (YAML, Markdown)
- ✅ Critical rules present in all tools
- ✅ No configuration drift
- ✅ Pre-commit checks pass

---

## 📊 Comparison

| Aspect | Current (Manual) | Automated |
|--------|------------------|-----------|
| Time to update | 15-30 min | 2 min |
| Risk of forgetting a file | High | None |
| Tool-specific optimization | Yes (manual) | Yes (automated) |
| Consistency | Manual checking | Automatic validation |
| Examples generation | Manual | Can be AI-generated |

---

## 🏗️ Implementation Status

- ✅ **Design document** (STANDARDS_SYNC_DESIGN.md)
- ✅ **Proof of concept** (scripts/sync-standards-poc.py)
- ⏳ **Phase 1 (MVP):** Not started
  - Full parser
  - All transformers
  - Template system
  - Validation
- ⏳ **Phase 2 (AI):** Not started
  - LLM integration
  - Prompt engineering
- ⏳ **Phase 3 (Advanced):** Not started
  - Incremental updates
  - Conflict resolution

---

## 🤔 Questions Answered

### Q: Do I still need to know all tool formats?

**A:** No! Just update CONTEXT.md. The sync script handles format conversions.

### Q: What if I want to customize a tool config?

**A:** Tool configs can have "custom sections" that sync doesn't touch. Only specified sections are
synced.

### Q: Can I preview changes before applying?

**A:** Yes! Use `--dry-run` flag:

```bash
./scripts/sync-standards.sh --dry-run
```

### Q: What if the automated output isn't perfect?

**A:** You can:
1. Edit the generated files manually (one-time fix)
2. Improve the transformer for that tool (permanent fix)
3. Add custom override rules in config.yaml

### Q: Does this require AI API keys?

**A:** No! Basic sync uses templates. AI enhancement is optional.

### Q: Will this work with custom AI tools?

**A:** Yes! Add a transformer for your tool in `scripts/sync/transformers/`.

---

## 🎯 Next Steps

1. **Review design:** Read STANDARDS_SYNC_DESIGN.md
2. **Test POC:** Run `python3 scripts/sync-standards-poc.py --dry-run`
3. **Provide feedback:** What features are most important?
4. **Phase 1 implementation:** Build MVP if design approved
5. **Real-world testing:** Use on next CONTEXT.md update

---

## 📚 Related Documentation

- **[STANDARDS_SYNC_DESIGN.md](./STANDARDS_SYNC_DESIGN.md)** - Full technical design
- **[AGENTS.md](./AGENTS.md)** - Current manual workflow (section 4)
- **[CONTEXT.md](./CONTEXT.md)** - The single source of truth
- **[AI_TOOL_CONFIGURATIONS.md](./AI_TOOL_CONFIGURATIONS.md)** - Tool format details

---

## 💡 Example Use Cases

### Use Case 1: Add Security Rule

**Scenario:** You want to add "Never use eval()" rule.

**Without automation:**
1. Edit CONTEXT.md (5 min)
2. Edit .cursor/rules/006_security.mdc (5 min)
3. Edit CLAUDE.md security section (5 min)
4. Edit .github/copilot-instructions.md (3 min)
5. Edit .aider/.aider.conf.yml (3 min)
6. Edit .continue/config.yaml (3 min)
7. Test manually (10 min)
8. Fix inconsistencies (5 min)
**Total: 39 minutes**

**With automation:**
1. Edit CONTEXT.md (5 min)
2. Run `./scripts/sync-standards.sh` (10 seconds)
3. Review git diff (2 min)
4. Test with 2 tools (5 min)
**Total: 12 minutes + more consistency**

### Use Case 2: Update Bash Standards

**Scenario:** Change "quote variables" to be more specific.

**Without automation:**
- Update 8 files manually
- Ensure wording consistent
- Risk missing a file

**With automation:**
- Update CONTEXT.md once
- Sync automatically
- Validation ensures all files updated

---

_This guide demonstrates the proposed automation system. Implementation pending approval._
