# Management Scripts Documentation

**Last Updated**: February 8, 2026

**Location**: `template/scripts/`

---

## 📋 Overview

This directory contains management scripts for configuring and maintaining pre-commit hooks and CI/CD workflows.
These scripts work both in this template repository and in projects that use the template.

---

## 🛠️ Available Scripts

### 1. setup-precommit.sh

**Purpose**: Install and configure pre-commit hooks in a repository.

**Usage**:

```bash
./scripts/setup-precommit.sh [--force]
```

**What it does**:

- ✅ Verifies pre-commit is installed
- ✅ Checks for `.pre-commit-config.yaml`
- ✅ Installs pre-commit hook
- ✅ Installs commit-msg hook
- ✅ Runs pre-commit on all files to validate
- ✅ Provides troubleshooting guidance

**Options**:

- `--force` - Reinstall hooks even if already installed

**Example output**:

```text
===============================================================================
Pre-commit Setup
===============================================================================

✓ pre-commit is installed: pre-commit 3.6.2
✓ .pre-commit-config.yaml found

Installing pre-commit hooks...
Installing commit-msg hook...

Running pre-commit on all files...
[All checks pass or show failures]

✅ Pre-commit setup complete and all checks passed!
```

---

### 2. manage-precommit-hooks.sh

**Purpose**: Enable, disable, or list pre-commit hooks.

**Usage**:

```bash
./scripts/manage-precommit-hooks.sh <command> [arguments]
```

**Commands**:

#### List all hooks

```bash
./scripts/manage-precommit-hooks.sh list
```

Shows all hooks with their status (enabled/disabled).

**Example output**:

```text
===============================================================================
Pre-commit Hooks Status
===============================================================================

✓ check-merge-conflict (enabled)
✓ check-yaml (enabled)
✓ check-json (enabled)
⚪ shellcheck (disabled)
✓ ruff (enabled)
✓ detect-secrets (enabled)
```

#### Show hook configuration

```bash
./scripts/manage-precommit-hooks.sh show <hook-id>
```

Displays the full configuration for a specific hook.

**Example**:

```bash
./scripts/manage-precommit-hooks.sh show ruff
```

**Output**:

```yaml
- id: ruff
  name: "🐍 python · Lint and autofix with Ruff"
  args: [--fix]
```

#### Disable a hook

```bash
./scripts/manage-precommit-hooks.sh disable <hook-id>
```

Comments out the hook in `.pre-commit-config.yaml`.

**Example**:

```bash
./scripts/manage-precommit-hooks.sh disable shellcheck
```

**What happens**:

- Creates backup: `.pre-commit-config.yaml.backup`
- Comments out the hook and all its configuration
- Hook will no longer run on commits

#### Enable a hook

```bash
./scripts/manage-precommit-hooks.sh enable <hook-id>
```

Uncomments a previously disabled hook.

**Example**:

```bash
./scripts/manage-precommit-hooks.sh enable shellcheck
```

**What happens**:

- Creates backup: `.pre-commit-config.yaml.backup`
- Uncomments the hook and its configuration
- Hook will run on future commits

---

### 3. manage-ci-jobs.sh

**Purpose**: Manage CI/CD workflow jobs (enable, disable, list).

**Usage**:

```bash
./scripts/manage-ci-jobs.sh <command> [arguments]
```

**Commands**:

#### List all workflows and jobs

```bash
./scripts/manage-ci-jobs.sh list [workflow]
```

Shows all CI/CD workflows and their jobs.

**Example output**:

```text
===============================================================================
CI/CD Workflows and Jobs
===============================================================================

Workflow: ci.yaml
  Display name: CI
  Jobs:
    ✓ pre-commit
       → Pre-commit Checks
    ✓ tests
       → Unit Tests

Workflow: security-ci.yml
  Display name: Security CI
  Jobs:
    ✓ gitleaks
       → Secret scan (Gitleaks)
    ✓ semgrep
       → SAST (Semgrep CE)
    ✓ osv-scanner
       → Dependency vulns (OSV-Scanner)
```

#### List specific workflow

```bash
./scripts/manage-ci-jobs.sh list ci.yaml
```

Shows only jobs in the specified workflow.

#### Show job configuration

```bash
./scripts/manage-ci-jobs.sh show <workflow> <job>
```

Displays the full configuration for a specific job.

**Example**:

```bash
./scripts/manage-ci-jobs.sh show ci.yaml tests
```

**Output**:

```yaml
tests:
  name: Unit Tests
  runs-on: ubuntu-latest
  needs: [pre-commit]
  steps:
    - name: Checkout
      uses: actions/checkout@v4
    ...
```

#### Disable a job

```bash
./scripts/manage-ci-jobs.sh disable <workflow> <job>
```

Comments out the job in the workflow file.

**Example**:

```bash
./scripts/manage-ci-jobs.sh disable ci.yaml tests
```

**What happens**:

- Creates backup: `.github/workflows/ci.yaml.backup`
- Comments out the entire job
- Job will not run in future CI executions
- **Important**: Must commit and push to apply

#### Enable a job

```bash
./scripts/manage-ci-jobs.sh enable <workflow> <job>
```

Uncomments a previously disabled job.

**Example**:

```bash
./scripts/manage-ci-jobs.sh enable ci.yaml tests
```

**What happens**:

- Creates backup: `.github/workflows/ci.yaml.backup`
- Uncomments the job
- Job will run in future CI executions
- **Important**: Must commit and push to apply

---

## 📚 Common Workflows

### Initial Setup (New Project)

```bash
# 1. Bootstrap the template (copies all files)
./template/bootstrap-guardrails.sh

# 2. Set up pre-commit
./scripts/setup-precommit.sh

# 3. Verify everything works
pre-commit run --all-files
```

### Disable Expensive Checks During Development

```bash
# Disable slow linters temporarily
./scripts/manage-precommit-hooks.sh disable ruff
./scripts/manage-precommit-hooks.sh disable shellcheck

# Work on your code...

# Re-enable before committing
./scripts/manage-precommit-hooks.sh enable ruff
./scripts/manage-precommit-hooks.sh enable shellcheck
pre-commit run --all-files
```

### Disable Tests in CI (For Repos Without Tests)

```bash
# Disable test job
./scripts/manage-ci-jobs.sh disable ci.yaml tests

# Commit and push
git add .github/workflows/ci.yaml
git commit -m "Disable test job (no tests yet)"
git push
```

### Check What's Running in CI

```bash
# List all workflows and jobs
./scripts/manage-ci-jobs.sh list

# See specific job configuration
./scripts/manage-ci-jobs.sh show security-ci.yml gitleaks
```

### Troubleshoot Pre-commit Issues

```bash
# See what hooks are enabled
./scripts/manage-precommit-hooks.sh list

# Check specific hook configuration
./scripts/manage-precommit-hooks.sh show detect-secrets

# Temporarily disable problematic hook
./scripts/manage-precommit-hooks.sh disable detect-secrets

# Fix issues, then re-enable
./scripts/manage-precommit-hooks.sh enable detect-secrets
```

---

## 🎯 Use Cases

### For Template Repository Maintainers

**Add a new pre-commit hook**:

1. Edit `template/.pre-commit-config.yaml` manually
2. Test with `pre-commit run --all-files`
3. Document in `PRE_COMMIT_SETUP_SUMMARY.md`

**Modify CI workflow**:

1. Edit workflow file in `template/.github/workflows/`
2. Test by pushing to a branch
3. Document in `CI_WORKFLOWS.md`

### For Project Users

**Customize for your project**:

```bash
# List what you have
./scripts/manage-precommit-hooks.sh list
./scripts/manage-ci-jobs.sh list

# Disable what you don't need
./scripts/manage-precommit-hooks.sh disable sqlfluff  # No SQL files
./scripts/manage-ci-jobs.sh disable ci.yaml tests     # No tests yet

# Enable optional hooks
# (Edit .pre-commit-config.yaml to uncomment optional sections)
```

**Upgrade pre-commit hooks**:

```bash
# Update to latest versions
pre-commit autoupdate

# Test
pre-commit run --all-files

# Commit if good
git add .pre-commit-config.yaml
git commit -m "Update pre-commit hook versions"
```

---

## 🔧 Troubleshooting

### Script says "pre-commit not installed"

**Solution**:

```bash
pip install pre-commit
# or
brew install pre-commit
# or
pipx install pre-commit
```

### Script says "Not in a git repository"

**Solution**: Run scripts from within a git repository:

```bash
cd /path/to/your/repo
./scripts/setup-precommit.sh
```

### Changes to CI jobs don't apply

**Solution**: CI changes require commit and push:

```bash
git add .github/workflows/
git commit -m "Update CI configuration"
git push
```

### Hook still runs after disabling

**Solution**: Pre-commit caches hooks. Clear cache:

```bash
rm -rf ~/.cache/pre-commit
pre-commit clean
pre-commit install
```

### Want to temporarily skip pre-commit

**Solution**: Use `--no-verify` (NOT recommended):

```bash
git commit --no-verify -m "WIP: temporary commit"
```

**Better solution**: Disable specific hooks:

```bash
./scripts/manage-precommit-hooks.sh disable expensive-hook
# Make commit
./scripts/manage-precommit-hooks.sh enable expensive-hook
```

---

## 📖 Related Documentation

- **`setup-precommit.sh`** - Initial pre-commit setup
- **`manage-precommit-hooks.sh`** - Hook management
- **`manage-ci-jobs.sh`** - CI job management
- **`bootstrap-guardrails.sh`** - Template bootstrap
- **`PRE_COMMIT_SETUP_SUMMARY.md`** - Pre-commit overview
- **`CI_WORKFLOWS.md`** - CI/CD documentation

---

## 🚀 Quick Reference

```bash
# Setup
./scripts/setup-precommit.sh

# Manage hooks
./scripts/manage-precommit-hooks.sh list
./scripts/manage-precommit-hooks.sh disable <hook-id>
./scripts/manage-precommit-hooks.sh enable <hook-id>
./scripts/manage-precommit-hooks.sh show <hook-id>

# Manage CI
./scripts/manage-ci-jobs.sh list
./scripts/manage-ci-jobs.sh disable <workflow> <job>
./scripts/manage-ci-jobs.sh enable <workflow> <job>
./scripts/manage-ci-jobs.sh show <workflow> <job>

# Run pre-commit
pre-commit run --all-files
./scripts/run-precommit.sh  # With detailed logging
```

---

**Questions?** Open an issue on GitHub!
