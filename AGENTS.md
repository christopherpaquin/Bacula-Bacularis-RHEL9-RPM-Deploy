# AGENTS Guidelines for This Repository

This repository provides AI coding assistant configurations and guardrails for professional
software engineering. When working with AI agents on this repository, follow these guidelines
to maintain consistency and quality.

---

## 1. Repository Structure

**Understanding the layout:**

```text
Root Directory (AI Context Files):
├── AGENTS.md              # This file - workflow instructions for agents
├── WORKLOG.md             # Implementation tracking and findings log
├── CONTEXT.md             # Universal standards (single source of truth)
├── CONTRIBUTING.md        # Contribution guidelines
├── README.md              # Overview and quick start
├── QUICK_START.md         # Fast setup guide
│
├── AI Tool Configurations:
├── .cursor/rules/*.mdc    # Cursor AI (8 scoped rules)
├── CLAUDE.md              # Claude Desktop instructions
├── .claudeprompt          # Claude Projects config
├── .continue/config.yaml  # Continue.dev configuration
├── .windsurfignore        # Windsurf context exclusions
├── .vscode/settings.json  # VS Code/Windsurf settings
├── .github/copilot-instructions.md  # GitHub Copilot
├── .aider/.aider.conf.yml # Aider configuration
│
└── template/              # Infrastructure (pre-commit, CI/CD, scripts)
    ├── bootstrap-guardrails.sh          # Setup script for new projects
    ├── .pre-commit-config.yaml          # Pre-commit configuration
    ├── .pymarkdown.json                 # Markdown linting config
    ├── .github/workflows/               # CI/CD workflows
    ├── scripts/                         # Management scripts
    └── Documentation (USAGE.md, etc.)
```

**Key principle:**
- Root directory = AI context and configuration files
- template/ directory = Infrastructure files (out of the way for template users)

---

## 2. Reading Order for New Agents

**When first working on this repository, read in this order:**

1. **AGENTS.md** (this file) - Learn workflow and commands
2. **WORKLOG.md** - Review recent implementation work and findings (IMPORTANT - read first!)
3. **CONTEXT.md** - Understand universal standards (CRITICAL - read fully)
4. **CONTRIBUTING.md** - Learn contribution process
5. **template/TEMPLATE_STRUCTURE.md** - Understand template design

**For specific tasks:**
- Adding AI tool support → Read `AI_TOOL_CONFIGURATIONS.md`
- Working with pre-commit → Read `template/PRE_COMMIT_SETUP_SUMMARY.md`
- Working with CI/CD → Read `template/CI_WORKFLOWS.md`
- Creating scripts → Read `template/MANAGEMENT_SCRIPTS.md`

---

## 2.1 Maintaining the Work Log

**IMPORTANT:** When working on this repository, maintain `WORKLOG.md` to track implementation progress and prevent circular work.

### When to Update WORKLOG.md

Update the worklog when you:
- ✅ Add new features or functionality
- ✅ Make significant implementation decisions
- ✅ Discover what works or doesn't work
- ✅ Complete a complex task
- ✅ Find solutions to tricky problems

### What to Document

Keep entries brief (1-3 lines each):

**Features Added:**
- What was built or changed
- Which files were affected

**Findings & Decisions:**
- Why certain approaches were chosen
- Important discoveries or insights
- Technical decisions and rationale

**What Doesn't Work:**
- Approaches that were tried but failed
- Why they failed (saves future time)
- Alternative approaches to try instead

### Example Worklog Entry

```markdown
## 2026-02-15

### Features Added
- Added semantic search support to pre-commit hook detection
- Created `scripts/analyze-hooks.sh` for hook performance metrics

### Findings & Decisions
- Ripgrep is 10x faster than grep for large repos - use `rg` in all scripts
- YAML parsing with yq is more reliable than awk for complex queries
- Hook execution time should be <2s for good developer experience

### What Doesn't Work
- ❌ Using Python for pre-commit hooks - too slow to initialize interpreter
- ❌ Regex-only secret detection - high false positive rate
- ❌ Global git hooks in ~/.git-templates - conflicts with repo-specific hooks
```

### Workflow

```bash
# 1. Start new work - read the worklog first
cat WORKLOG.md

# 2. Do your work
# ... implement features, fix bugs, etc ...

# 3. Before committing - update the worklog
vim WORKLOG.md  # Add entry for today's date

# 4. Commit with both code and worklog updates
git add .
git commit -m "feat: add new feature

Updated WORKLOG.md with implementation details."
```

**Why this matters:**
- Prevents re-trying failed approaches
- Maintains context across agent sessions
- Helps new agents get up to speed quickly
- Documents tribal knowledge

---

## 3. Development Workflow

### Running Pre-commit Checks

**ALWAYS run before committing:**

```bash
# From repository root
pre-commit run --all-files
```

**Common pre-commit commands:**

```bash
# Setup pre-commit (first time only)
./template/scripts/setup-precommit.sh

# Run on specific files
pre-commit run --files AGENTS.md CONTEXT.md

# Run specific hook
pre-commit run shellcheck --all-files

# Bypass (EMERGENCY ONLY - requires justification)
git commit --no-verify -m "Emergency fix"
```

### Managing Pre-commit Hooks

```bash
# List all hooks
./template/scripts/manage-precommit-hooks.sh list

# Show hook configuration
./template/scripts/manage-precommit-hooks.sh show detect-secrets

# Disable expensive check during development
./template/scripts/manage-precommit-hooks.sh disable shellcheck

# Re-enable before committing
./template/scripts/manage-precommit-hooks.sh enable shellcheck
```

### Managing CI Jobs

```bash
# List all CI workflows and jobs
./template/scripts/manage-ci-jobs.sh list

# Show job configuration
./template/scripts/manage-ci-jobs.sh show ci.yaml tests

# Disable job (commit the change)
./template/scripts/manage-ci-jobs.sh disable ci.yaml tests
git commit -am "Disable tests job"

# Enable job (commit the change)
./template/scripts/manage-ci-jobs.sh enable ci.yaml tests
git commit -am "Enable tests job"
```

---

## 4. Common Tasks and Commands

### Adding Support for a New AI Tool

**Steps:**

1. Research the tool's configuration format
2. Create config file in root directory (e.g., `.newtool/config.yaml`)
3. Derive content from `CONTEXT.md` (single source of truth)
4. Optimize for tool's native format
5. Update `AI_TOOL_CONFIGURATIONS.md` with:
   - Tool description
   - Configuration format
   - How to use
   - Features and limitations
6. Update `README.md` supported tools table
7. Update `QUICK_START.md` setup instructions
8. Test with the actual AI tool
9. Run pre-commit and fix any issues
10. Commit changes

**Example commit message format:**

```text
Add support for [Tool Name]

Add configuration for [Tool Name] with [key features].
Derived from CONTEXT.md standards.

New files:
- .toolname/config.ext - [Tool] configuration

Updated documentation:
- AI_TOOL_CONFIGURATIONS.md - Add [Tool] reference
- README.md - Add to supported tools
- QUICK_START.md - Add setup instructions
```

### Updating Standards

**CRITICAL WORKFLOW - Always follow this order:**

1. **Update `CONTEXT.md` FIRST** (single source of truth)
2. Update **all** tool-specific configs to match:
   - `.cursor/rules/*.mdc`
   - `CLAUDE.md`
   - `.claudeprompt`
   - `.continue/config.yaml`
   - `.github/copilot-instructions.md`
   - `.aider/.aider.conf.yml`
   - Any other AI tool configs
3. Update `CONTRIBUTING.md` if process changes
4. Test with at least 2 different AI tools
5. Run pre-commit checks
6. Commit all changes together

**Why this order matters:**
- CONTEXT.md is the authoritative source
- Tool configs are derivations of CONTEXT.md
- Keeps all tools in sync
- Prevents configuration drift

### Adding New Pre-commit Hooks

**Steps:**

1. Edit `template/.pre-commit-config.yaml`
2. Add new hook configuration:
   ```yaml
   - repo: https://github.com/username/hook-repo
     rev: v1.0.0
     hooks:
       - id: hook-id
         name: "🔧 category · Description"
         args: ["--option", "value"]
   ```
3. Test the hook:
   ```bash
   pre-commit run hook-id --all-files
   ```
4. Update documentation:
   - `template/PRE_COMMIT_SETUP_SUMMARY.md` - Add hook description
   - `QUICK_START.md` - Update hook count
5. Run full pre-commit suite
6. Commit changes

### Adding New CI Jobs

**Steps:**

1. Edit `template/.github/workflows/ci.yaml` or `security-ci.yml`
2. Add new job:
   ```yaml
   new-job:
     runs-on: ubuntu-latest
     steps:
       - uses: actions/checkout@v4
       - name: Run new check
         run: |
           # commands here
   ```
3. Update documentation:
   - `template/CI_WORKFLOWS.md` - Document new job
4. Test locally if possible
5. Commit and push to test in CI
6. Monitor first run for issues

### Creating New Management Scripts

**Standards for scripts:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# ALWAYS include:
# - Shebang: #!/usr/bin/env bash
# - Safety: set -euo pipefail
# - Input validation
# - Error handling
# - Usage/help function
# - Color-coded output

# Save to: template/scripts/scriptname.sh
# Document in: template/MANAGEMENT_SCRIPTS.md
# Make executable: chmod +x template/scripts/scriptname.sh
# Test thoroughly before committing
```

**Required sections:**
1. Header with description
2. Usage function
3. Input validation
4. Main logic
5. Error handling
6. Exit codes (0=success, 1=error, 2=invalid usage)

---

## 5. Testing Instructions

### Pre-commit Testing

**Before every commit:**

```bash
# Full suite (required)
pre-commit run --all-files

# Specific checks for changed files
pre-commit run --files path/to/file1 path/to/file2

# Individual hooks
pre-commit run shellcheck --all-files
pre-commit run pymarkdown --all-files
pre-commit run detect-secrets --all-files
```

**Fix issues:**
- Many hooks auto-fix (trailing whitespace, EOF, formatting)
- After auto-fix, stage changes and commit again
- Security issues (secrets, private keys) MUST be manually removed

### CI Testing

**This repository's CI runs:**

1. **Pre-commit checks** - Same as local (cannot be bypassed)
2. **Security scanning** - Gitleaks (full history), Semgrep, OSV-Scanner

**CI only runs on pull requests and pushes to main.**

For this repository (template), tests are not required since it's infrastructure.
However, projects using this template should have comprehensive tests.

### Manual Testing Checklist

**When adding AI tool support:**

- [ ] Config file syntax is valid
- [ ] AI tool actually reads the config
- [ ] Tool follows the specified guidelines
- [ ] Security rules are enforced
- [ ] Examples work correctly
- [ ] Documentation is accurate

**When updating standards:**

- [ ] CONTEXT.md is updated first
- [ ] All tool configs are updated
- [ ] Tested with at least 2 AI tools
- [ ] Pre-commit passes
- [ ] No secrets or sensitive data
- [ ] Documentation reflects changes

---

## 6. Commit Message Format

**Conventional commit format (preferred):**

```text
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature or AI tool support
- `fix`: Bug fix or correction
- `docs`: Documentation only
- `style`: Formatting changes
- `refactor`: Code restructuring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**

```text
feat(ai-tools): Add support for Continue.dev

Add .continue/config.yaml with custom prompts for review, commit, and test.
Includes context providers and references to CONTEXT.md.

- New: .continue/config.yaml
- Updated: AI_TOOL_CONFIGURATIONS.md, README.md
```

```text
docs(standards): Update security requirements in CONTEXT.md

Clarify secret detection requirements and add examples of proper
credential handling. Propagated changes to all AI tool configs.

BREAKING CHANGE: Stricter secret detection in pre-commit hooks
```

**CRITICAL - Commit message security:**
- NO secrets, passwords, API keys, tokens
- NO private/internal URLs or IPs
- NO credentials or sensitive data
- Commit message hook will reject violations

---

## 7. PR Instructions

### PR Title Format

```text
[<area>] <Title>

Examples:
- [ai-tools] Add support for Windsurf
- [docs] Update AGENTS.md with workflow guidance
- [pre-commit] Add new shellcheck rules
- [security] Strengthen secret detection
```

### PR Checklist

**Before creating PR:**

- [ ] Read CONTEXT.md for standards
- [ ] All pre-commit checks pass
- [ ] CONTEXT.md updated (if standards changed)
- [ ] All tool configs updated (if standards changed)
- [ ] Documentation updated
- [ ] Tested with actual AI tools (if tool changes)
- [ ] No secrets or sensitive data
- [ ] Commit messages follow format

**PR description should include:**
1. What changed
2. Why it changed
3. How to test
4. Any breaking changes
5. Related issues (if any)

### Review Process

**Reviewers check for:**
- Standards compliance (CONTEXT.md)
- Documentation completeness
- Pre-commit passing
- No secrets or sensitive data
- Proper commit message format
- Testing evidence (if applicable)

---

## 8. File Naming and Organization

### AI Configuration Files

**Naming conventions:**

- Tool-specific config directory: `.toolname/` (lowercase)
- Main config file: `TOOLNAME.md` or `.toolname/config.ext`
- Use tool's native format and conventions

**Examples:**
- `.cursor/rules/001_workspace.mdc` (Cursor's native format)
- `CLAUDE.md` (Claude Desktop convention)
- `.continue/config.yaml` (Continue.dev standard)

### Documentation Files

**Naming conventions:**

- Root docs: `UPPERCASE.md` (e.g., `CONTEXT.md`, `AGENTS.md`)
- Template docs: `template/UPPERCASE.md` (e.g., `USAGE.md`)
- Special cases: `README.md`, `CONTRIBUTING.md` (GitHub standards)

**Organization:**
- AI context files → Root directory
- Infrastructure docs → `template/` directory
- Keep root clean for template users

### Script Files

**Naming conventions:**

- Lowercase with hyphens: `script-name.sh`
- Location: `template/scripts/`
- Descriptive names: `setup-precommit.sh`, `manage-ci-jobs.sh`

---

## 9. Security Guidelines for Agents

### CRITICAL - Never Commit Secrets

**NEVER commit these to git:**
- API keys, tokens, passwords, credentials
- Private keys (SSH, TLS, .pem, .key files)
- Cloud credentials (AWS, GCP, Azure keys/secrets)
- Database connection strings with passwords
- OAuth tokens, JWT secrets
- Webhook secrets
- Any high-entropy strings that might be secrets

**Detection layers:**
1. Pre-commit hook: `detect-secrets.sh` (local, staged files)
2. Commit message hook: `check-commit-message.sh` (local, message validation)
3. CI: Gitleaks (full git history, cannot be bypassed)

**If you accidentally commit a secret:**
1. Immediately revoke/rotate the secret
2. DO NOT just remove it in next commit (it's in history)
3. Contact repository maintainer for git history rewrite
4. Update documentation if procedure changed

### Handling Credentials Properly

**✅ CORRECT approach:**

```python
import os

# Load from environment variable
api_key = os.environ.get("OPENAI_API_KEY")
if not api_key:
    raise ValueError("OPENAI_API_KEY environment variable required")

# Use in code
client = OpenAI(api_key=api_key)
```

**Provide `.env.example` (safe to commit):**

```bash
# .env.example
OPENAI_API_KEY=your_api_key_here
DATABASE_URL=postgresql://user:pass@localhost:5432/db
```

**Add to `.gitignore`:**

```text
.env
.env.local
*.key
*.pem
credentials.json
```

---

## 10. Useful Commands Reference

### Git Commands

```bash
# Check current status
git status

# Stage all changes
git add -A

# Stage specific files
git add path/to/file

# Commit with message
git commit -m "feat: description"

# Amend last commit (if not pushed)
git commit --amend --no-edit

# Push to remote
git push origin main

# Create new branch
git checkout -b feature/new-ai-tool

# View commit history
git log --oneline -10
```

### Pre-commit Commands

```bash
# Install hooks
pre-commit install
pre-commit install --hook-type commit-msg

# Run all checks
pre-commit run --all-files

# Run on staged files only
pre-commit run

# Run specific hook
pre-commit run <hook-id> --all-files

# Update hook versions
pre-commit autoupdate

# Clean cache
pre-commit clean

# Uninstall hooks
pre-commit uninstall
```

### Repository Management

```bash
# List management scripts
ls -la template/scripts/

# Get help for any script
./template/scripts/scriptname.sh --help

# Check pre-commit config
cat template/.pre-commit-config.yaml | grep "id:"

# Check CI workflows
ls -la template/.github/workflows/

# View git log with files
git log --stat -5

# Find large files
find . -type f -size +1M -not -path "./.git/*"
```

---

## 11. Common Pitfalls and Solutions

### Problem: Pre-commit hook failing

**Solution:**

```bash
# See what failed
pre-commit run --all-files

# Run individual hooks to debug
pre-commit run <hook-id> --all-files --verbose

# Check hook configuration
./template/scripts/manage-precommit-hooks.sh show <hook-id>

# Fix the actual issues identified by the hook
# DO NOT disable the hook to bypass the check
```

**CRITICAL: NEVER disable pre-commit hooks to bypass failures.**

The management script `manage-precommit-hooks.sh` exists for development workflow
optimization (e.g., disabling slow hooks during rapid iteration), but hooks must
be re-enabled before committing.

**Better approach: Fix the issues rather than bypass the checks.**

### Problem: Secret detected in commit

**Solution:**

```bash
# DON'T commit with --no-verify
# Instead, remove the secret:

# 1. Remove secret from file
# 2. Use environment variable instead
# 3. Add to .env (gitignored)
# 4. Provide .env.example

# If already committed locally (not pushed):
git reset HEAD~1  # Undo commit, keep changes
# Remove secret, fix issue
git add -A
git commit -m "fix: proper credential handling"
```

### Problem: Markdown linting errors

**Solution:**

```bash
# Most are auto-fixable
pre-commit run --all-files

# Common issues:
# - MD031: Need blank lines around code fences
# - MD032: Need blank lines around lists
# - MD013: Line too long (wrap at 120 chars)

# Check PyMarkdown config
cat template/.pymarkdown.json

# Disable specific rule for internal docs only
# (Edit template/.pre-commit-config.yaml exclude pattern)
```

### Problem: Tool config not working

**Solution:**

1. Verify file syntax (YAML, JSON, etc.)
2. Check file is in correct location
3. Restart AI tool to reload config
4. Verify tool actually supports file-based config
5. Check tool documentation for config format changes
6. Test with minimal config first, then expand

---

## 12. Questions or Issues?

**For questions about:**

- **Standards** → Read `CONTEXT.md`
- **Contributing** → Read `CONTRIBUTING.md`
- **Setup** → Read `QUICK_START.md`
- **AI tools** → Read `AI_TOOL_CONFIGURATIONS.md`
- **Workflows** → Read this file (`AGENTS.md`)

**For issues or suggestions:**

1. Check existing documentation first
2. Search GitHub issues for similar questions
3. Open a new issue with:
   - Clear description
   - Steps to reproduce (if bug)
   - Expected vs actual behavior
   - Environment details (OS, tool versions)

---

## 13. Summary: Quick Reference

**Essential commands:**

```bash
# Setup
./template/scripts/setup-precommit.sh

# Before every commit
pre-commit run --all-files

# Managing hooks/jobs
./template/scripts/manage-precommit-hooks.sh list
./template/scripts/manage-ci-jobs.sh list

# Standard commit flow
git add -A
pre-commit run --all-files
git commit -m "type(scope): description"
git push
```

**Essential principles:**

1. **CONTEXT.md is single source of truth** - Update it first
2. **Never commit secrets** - Use environment variables
3. **Run pre-commit before every commit** - No --no-verify
4. **Update all tool configs together** - Keep in sync
5. **Document everything** - Update docs with code changes
6. **Test with real tools** - Verify configs actually work

**Essential files to know:**

- `AGENTS.md` - This file (workflow)
- `CONTEXT.md` - Standards (rules)
- `CONTRIBUTING.md` - Process (how to contribute)
- `template/TEMPLATE_STRUCTURE.md` - Design (why organized this way)

---

**Following these guidelines ensures high-quality, secure, maintainable AI configurations!**
