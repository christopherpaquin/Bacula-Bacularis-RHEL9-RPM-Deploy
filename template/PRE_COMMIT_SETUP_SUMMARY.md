# Pre-commit and CI/CD Setup Summary

**Date**: February 8, 2026

**Status**: ✅ Complete and Operational

---

## 🎯 Overview

Successfully copied comprehensive pre-commit framework and CI/CD workflows from `github-ai-engineering-framework`
repository to `Guardrails-AI` repository. The Guardrails-AI repository now practices the same strict quality and
security standards it recommends to others.

---

## 📦 What Was Added

### Pre-commit Infrastructure

1. **`.pre-commit-config.yaml`** (20+ hooks)
   - Git hygiene checks (merge conflicts, large files, submodules)
   - Filesystem checks (case sensitivity, Windows compatibility, shebangs, symlinks)
   - Format validation and auto-fixing (YAML, JSON, TOML, EOF, whitespace, line endings)
   - Security hooks (private key detection, secret scanning)
   - Python linting and formatting (Ruff)
   - Shell script linting (ShellCheck) and formatting (shfmt)
   - Markdown linting (PyMarkdown)

2. **`scripts/detect-secrets.sh`**
   - Pattern matching for known secret formats (API keys, tokens, credentials)
   - Entropy analysis for high-entropy strings
   - False positive filtering with allowlist
   - Performance optimized (single-pass scanning)

3. **`scripts/check-commit-message.sh`**
   - Validates commit messages for secrets, credentials, IPs
   - Prevents sensitive information from being committed to git history
   - Runs on every commit via commit-msg hook

4. **`scripts/run-precommit.sh`**
   - Authoritative wrapper for running pre-commit checks
   - Captures output to `artifacts/pre-commit.log` for AI analysis
   - Preserves exit codes for CI/CD integration

5. **`.pymarkdown.json`**
   - Configuration for PyMarkdown linter
   - Line length limit: 120 characters
   - Disabled overly strict rules (MD036, MD024)

6. **`requirements-dev.txt`**
   - Development dependencies (pre-commit, ruff, pymarkdown, pytest)

### CI/CD Workflows

1. **`.github/workflows/ci.yaml`**
   - Pre-commit checks (runs all hooks in CI)
   - Caching for pip and pre-commit environments (faster CI runs)
   - Unit tests with pytest and coverage reporting
   - Artifact upload for pre-commit logs on failure

2. **`.github/workflows/security-ci.yml`**
   - **Gitleaks**: Full git history secret scanning
   - **Semgrep**: SAST scanning (OWASP Top 10, security audit rules)
   - **OSV-Scanner**: Dependency vulnerability scanning
   - SARIF upload to GitHub Security tab

### Documentation Updates

- **`CLAUDE.md`**: Fixed markdown formatting (blank lines, line length)
- **`README.md`**: Fixed markdown formatting
- **`CONTRIBUTING.md`**: Fixed markdown formatting
- **`USAGE.md`**: Fixed markdown formatting, added language specs to code blocks
- **`IMPLEMENTATION_COMPLETE.md`**: Fixed markdown formatting
- **`.github/copilot-instructions.md`**: Fixed markdown formatting

### Configuration Updates

- **`.gitignore`**: Added `artifacts/`, `.pre-commit-cache/`, Python cache directories
- **`.aider/.aider.conf.yml`**: Auto-formatted with yamlfmt

---

## 🔒 Security Layers

### Defense in Depth

The repository now has **three layers** of secret detection:

1. **Pre-commit (local)**: `detect-secrets.sh` - Scans staged files before commit
2. **Commit message**: `check-commit-message.sh` - Validates commit messages
3. **CI (remote)**: Gitleaks - Scans full git history on every push

This ensures secrets cannot slip through even if pre-commit is bypassed.

### SAST and Dependency Scanning

- **Semgrep**: Detects security vulnerabilities in code patterns
- **OSV-Scanner**: Identifies known vulnerabilities in dependencies

---

## ✅ Quality Enforcement

### Pre-commit Hooks (Run Locally)

All hooks run automatically on `git commit`:

- 🌳 **Git hygiene**: Conflict markers, large files, submodules
- 📁 **Filesystem**: Case sensitivity, Windows names, shebangs, symlinks
- 📄 **Format**: YAML, JSON, EOF, whitespace, line endings
- 🔒 **Security**: Private keys, secrets, commit message validation
- 🐍 **Python**: Ruff linting and formatting
- 🐚 **Shell**: ShellCheck linting and shfmt formatting
- 📝 **Markdown**: PyMarkdown linting

### CI/CD (Run on Push/PR)

All checks run in GitHub Actions:

- ✅ **Pre-commit**: Same checks as local (cannot be bypassed)
- 🧪 **Tests**: pytest with coverage reporting
- 🔒 **Security**: Gitleaks, Semgrep, OSV-Scanner

---

## 🚀 How to Use

### Initial Setup (One-time)

```bash
# Install pre-commit (if not already installed)
pip install pre-commit

# Install git hooks
cd /home/cpaquin/Workspace/Gitrepos/Guardrails-AI
pre-commit install
pre-commit install --hook-type commit-msg

# Verify installation
ls -la .git/hooks/pre-commit
ls -la .git/hooks/commit-msg
```

### Daily Workflow

Pre-commit runs automatically on `git commit`:

```bash
# Make changes
vim file.md

# Stage changes
git add file.md

# Commit (pre-commit runs automatically)
git commit -m "Update documentation"

# If pre-commit fails, fix issues and try again
# Many hooks auto-fix issues (run commit again)
```

### Manual Pre-commit Run

```bash
# Run all hooks on all files
pre-commit run --all-files

# Run specific hook
pre-commit run shellcheck --all-files

# Use wrapper script (captures output to log)
./scripts/run-precommit.sh
```

### Checking Secret Detection

```bash
# Test secret detection (should fail)
echo "OPENAI_API_KEY=sk-test123" > test.txt
git add test.txt
git commit -m "Test"  # Should fail with secret detected

# Clean up
git restore --staged test.txt
rm test.txt
```

---

## 📊 Statistics

- **19 files changed**
- **897 insertions, 56 deletions**
- **20+ pre-commit hooks** configured
- **3 CI/CD workflows** (CI, Security CI, OSV-Scanner)
- **3 custom security scripts**
- **All checks passing** ✅

---

## 🎯 Next Steps

1. **Push to remote**: `git push origin main`
2. **Verify CI/CD**: Check GitHub Actions tab for first CI run
3. **Review security findings**: Check GitHub Security tab for Semgrep results
4. **Update documentation**: If any project-specific adjustments are needed
5. **Share with team**: Ensure all contributors have pre-commit installed

---

## 🔧 Customization

### Disable Specific Hooks

Edit `.pre-commit-config.yaml` and comment out hooks you don't need:

```yaml
# - id: check-added-large-files
#   name: "🌳 git · Block large file commits"
```

### Adjust Secret Detection

Edit `scripts/detect-secrets.sh` to add patterns to allowlist:

```bash
ALLOWLIST_PATTERN='(YOUR_PATTERN_HERE|...)'
```

### Adjust Markdown Rules

Edit `.pymarkdown.json` to enable/disable specific rules:

```json
{
  "plugins": {
    "md013": {
      "enabled": false
    }
  }
}
```

---

## 📚 Related Documentation

- **CONTEXT.md**: Canonical standards document
- **CLAUDE.md**: AI operational guardrails
- **SETUP.md**: Development environment setup (if exists)
- **CONTRIBUTING.md**: Contribution guidelines

---

**Verification**: All pre-commit hooks passing ✅

**Commit**: `aa620fa`
