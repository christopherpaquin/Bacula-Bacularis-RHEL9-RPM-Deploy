# Quick Start Guide - AI Guardrails

**Last Updated**: February 8, 2026

---

## 🎯 For Projects Using This Template

### Option 1: Use as GitHub Template

1. **Click "Use this template"** on GitHub
2. **Clone your new repository**
3. **Run bootstrap script**:

   ```bash
   ./template/bootstrap-guardrails.sh
   ```

4. **Set up pre-commit**:

   ```bash
   ./scripts/setup-precommit.sh
   ```

5. **Commit and push**:

   ```bash
   git add -A
   git commit -m "Add AI Guardrails infrastructure"
   git push
   ```

### Option 2: Add to Existing Project

```bash
cd your-project

# Clone the template
git clone https://github.com/YOUR_USERNAME/Guardrails-AI.git .ai-guardrails

# Copy AI context files
cp .ai-guardrails/AGENTS.md .
cp .ai-guardrails/WORKLOG.md .
cp .ai-guardrails/WORKLOG_USAGE.md .
cp .ai-guardrails/CONTEXT.md .
cp .ai-guardrails/CONTRIBUTING.md .
cp -r .ai-guardrails/.cursor .
cp .ai-guardrails/CLAUDE.md .
cp .ai-guardrails/.claudeprompt .
cp -r .ai-guardrails/.continue .
cp .ai-guardrails/.windsurfignore .
cp -r .ai-guardrails/.vscode .

# Run bootstrap to copy infrastructure
.ai-guardrails/template/bootstrap-guardrails.sh

# Set up pre-commit
./scripts/setup-precommit.sh

# Commit
git add -A
git commit -m "Add AI Guardrails"

# Clean up
rm -rf .ai-guardrails
```

---

## 🛠️ Management Commands

### List Everything

```bash
# List all pre-commit hooks
./scripts/manage-precommit-hooks.sh list

# List all CI workflows and jobs
./scripts/manage-ci-jobs.sh list
```

### Manage Pre-commit Hooks

```bash
# Show hook configuration
./scripts/manage-precommit-hooks.sh show detect-secrets

# Disable expensive check during development
./scripts/manage-precommit-hooks.sh disable shellcheck

# Re-enable before commit
./scripts/manage-precommit-hooks.sh enable shellcheck
```

### Manage CI Jobs

```bash
# Show job configuration
./scripts/manage-ci-jobs.sh show ci.yaml tests

# Disable test job if no tests yet
./scripts/manage-ci-jobs.sh disable ci.yaml tests
git commit -am "Disable tests job"
git push

# Enable when tests are added
./scripts/manage-ci-jobs.sh enable ci.yaml tests
git commit -am "Enable tests job"
git push
```

---

## 🔒 Security Features

After setup, your project will have **triple-layer secret detection**:

1. **Pre-commit** - `detect-secrets.sh` scans staged files
2. **Commit message** - `check-commit-message.sh` validates messages
3. **CI** - Gitleaks scans full git history

**Test it works**:

```bash
# This should FAIL:
echo "API_KEY=sk-test123" > test.txt
git add test.txt
git commit -m "test"
# ❌ Potential secret found!

# This should also FAIL:
git commit -m "password=test123"
# ❌ Commit message contains sensitive information!
```

---

## ✅ What You Get

### AI Context Files

- **AGENTS.md**: Workflow instructions for AI agents (commands, testing, PRs)
- **WORKLOG.md**: Implementation tracking log (features, findings, failed approaches)
- **WORKLOG_USAGE.md**: Complete guide for using the worklog
- **CONTEXT.md**: Universal standards (security, quality, documentation)
- **CONTRIBUTING.md**: Contribution guidelines for humans and AI

**Tool-specific configurations:**

- **Cursor**: 8 scoped `.mdc` rules with priorities
- **Claude**: Comprehensive instructions in `CLAUDE.md`
- **Copilot**: Optimized format in `.github/copilot-instructions.md`
- **Aider**: Pre-configured in `.aider/.aider.conf.yml`
- **Continue.dev**: YAML config with rules and custom prompts
- **Windsurf**: Context exclusions and VS Code integration
- **VS Code**: Pre-configured formatters, linters, settings

### Quality Enforcement

**26 Pre-commit Hooks**:

- 🌳 Git hygiene (conflicts, large files, submodules)
- 📁 Filesystem (case, Windows compatibility, shebangs, symlinks)
- 📄 Format (YAML, JSON, TOML, EOF, whitespace, line endings)
- 🔒 Security (private keys, secrets, commit messages)
- 🐍 Python (Ruff linting and formatting)
- 🐚 Shell (ShellCheck + shfmt)
- 📝 Markdown (PyMarkdown)

**CI/CD Workflows**:

- ✅ Pre-commit checks (cannot be bypassed)
- ✅ Unit tests with coverage (pytest-cov + Codecov)
- ✅ Secret scanning (Gitleaks - full history)
- ✅ SAST scanning (Semgrep - OWASP Top 10)
- ✅ Dependency scanning (OSV-Scanner)

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| `README.md` | Overview and quick start |
| `AGENTS.md` | AI agent workflow instructions |
| `WORKLOG.md` | Implementation tracking log |
| `WORKLOG_USAGE.md` | How to use the worklog |
| `CONTEXT.md` | Canonical standards (source of truth) |
| `CONTRIBUTING.md` | Contribution guidelines |
| `template/USAGE.md` | Detailed usage guide |
| `template/MANAGEMENT_SCRIPTS.md` | Script documentation |
| `template/CI_WORKFLOWS.md` | CI/CD documentation |
| `template/PRE_COMMIT_SETUP_SUMMARY.md` | Pre-commit guide |
| `template/TEMPLATE_STRUCTURE.md` | Repository structure |

---

## 🔧 Troubleshooting

### Pre-commit not running

```bash
# Verify installation
ls -la .git/hooks/pre-commit
ls -la .git/hooks/commit-msg

# Reinstall
./scripts/setup-precommit.sh --force
```

### Hook keeps failing

```bash
# See what's wrong
./scripts/manage-precommit-hooks.sh show <hook-id>

# Temporarily disable
./scripts/manage-precommit-hooks.sh disable <hook-id>

# Fix issues, then re-enable
./scripts/manage-precommit-hooks.sh enable <hook-id>
```

### Need to bypass pre-commit (emergency only)

```bash
git commit --no-verify -m "Emergency fix"
# Then fix issues and make a proper commit
```

---

## 🎓 Learn More

- **For AI worklog**: See `WORKLOG_USAGE.md` (how to track implementation work)
- **For AI tool setup**: See `template/USAGE.md`
- **For script details**: See `template/MANAGEMENT_SCRIPTS.md`
- **For CI/CD details**: See `template/CI_WORKFLOWS.md`
- **For structure**: See `template/TEMPLATE_STRUCTURE.md`
- **For standards**: Read `CONTEXT.md`

---

**Questions?** Open an issue on GitHub!
