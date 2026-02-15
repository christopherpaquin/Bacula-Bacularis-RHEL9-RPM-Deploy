# CI/CD Workflows Documentation

**Last Updated**: February 8, 2026

**Location**: `template/.github/workflows/`

---

## 🎯 Overview

The AI Guardrails repository includes comprehensive CI/CD workflows that enforce quality and security standards
on every push and pull request. These workflows are **more comprehensive** than the github-ai-engineering-framework
they're based on.

---

## 📋 Available Workflows

### 1. CI Workflow (`ci.yaml`)

**Triggers:**
- Every pull request
- Every push to `main` branch

**Jobs:**

#### Job 1: Pre-commit Checks
- **Purpose**: Run all pre-commit hooks in CI to ensure they cannot be bypassed
- **Caching**:
  - pip packages
  - pre-commit environments (speeds up subsequent runs)
- **Features**:
  - Runs all 20+ hooks (linting, formatting, security)
  - Generates detailed log on failure (`artifacts/pre-commit.log`)
  - Uploads log as artifact (7-day retention)
- **Exit**: Fails if any pre-commit hook fails

#### Job 2: Unit Tests
- **Purpose**: Run project tests with coverage reporting
- **Depends on**: Pre-commit checks must pass first
- **Caching**: pip packages
- **Features**:
  - Auto-detects if tests exist
  - Installs pytest and pytest-cov if tests found
  - Runs tests with verbose output
  - Generates coverage report (XML format)
  - **NEW**: Uploads coverage to Codecov
- **Exit**: Fails if tests fail

**Improvements over github-ai-engineering-framework:**
- ✅ **Coverage reporting** with pytest-cov
- ✅ **Codecov integration** for coverage tracking
- ✅ **Verbose test output** (`-v` flag)
- ✅ **Coverage XML report** for CI integration

---

### 2. Security CI Workflow (`security-ci.yml`)

**Triggers:**
- Every pull request
- Every push to `main` branch
- Manual trigger (`workflow_dispatch`)

**Jobs:**

#### Job 1: Gitleaks - Secret Scanning
- **Purpose**: Scan full git history for leaked secrets
- **Scope**:
  - Entire git history (`fetch-depth: 0`)
  - All branches
- **Detects**:
  - API keys (GitHub, AWS, Stripe, OpenAI, etc.)
  - Access tokens and OAuth tokens
  - Private keys (SSH, TLS, etc.)
  - Credentials and passwords
  - High-entropy strings
- **Exit**: Fails if secrets found

#### Job 2: Semgrep - SAST Scanning
- **Purpose**: Static Application Security Testing
- **Rulesets**:
  - `p/security-audit` - Common vulnerabilities
  - `p/owasp-top-ten` - OWASP Top 10 risks
- **Detects**:
  - SQL injection
  - Cross-site scripting (XSS)
  - Command injection
  - Path traversal
  - Insecure cryptography
  - Authentication/authorization issues
  - And many more...
- **Output**:
  - SARIF format uploaded to GitHub Security tab
  - Viewable in repository Security → Code scanning alerts
- **Exit**: May warn but doesn't block (configurable)

#### Job 3: OSV-Scanner - Dependency Vulnerabilities
- **Purpose**: Scan dependencies for known vulnerabilities
- **Scope**:
  - Recursive scan of entire repository
  - Auto-detects dependency files:
    - Python: `requirements.txt`, `Pipfile.lock`, `poetry.lock`
    - Node.js: `package.json`, `package-lock.json`
    - Go: `go.mod`, `go.sum`
    - Rust: `Cargo.lock`
    - Many more...
- **Database**: OSV (Open Source Vulnerabilities) database
- **Output**:
  - JSON report as workflow artifact
  - Severity levels (Critical, High, Medium, Low)
  - CVE identifiers
  - Remediation guidance
- **Exit**: Fails if critical vulnerabilities found

---

## 🔒 Security Layers (Defense in Depth)

The workflows provide **three layers** of secret detection:

| Layer | Tool | Scope | When |
|-------|------|-------|------|
| **Layer 1** | `detect-secrets.sh` | Staged files | Pre-commit (local) |
| **Layer 2** | `check-commit-message.sh` | Commit messages | Pre-commit (local) |
| **Layer 3** | Gitleaks | Full git history | CI (remote) |

This ensures secrets cannot slip through even if pre-commit is bypassed with `--no-verify`.

---

## ⚙️ Permissions

**CI Workflow** (`ci.yaml`):
```yaml
permissions:
  contents: read
```

**Security CI Workflow** (`security-ci.yml`):
```yaml
permissions:
  contents: read
  actions: read
  security-events: write  # For SARIF uploads
```

---

## 📊 Workflow Status

Both workflows appear in PR checks:
- ✅ Green check: All jobs passed
- ❌ Red X: At least one job failed
- 🟡 Yellow dot: Running

PRs cannot be merged until both workflows pass (if branch protection is enabled).

---

## 🔍 Viewing Results

### Pre-commit Logs
1. Navigate to failed workflow run
2. Click "pre-commit" job
3. Download `pre-commit-log` artifact
4. Or view inline in workflow logs

### Security Findings

**Gitleaks:**
- View in workflow logs
- Shows file, line number, and secret type

**Semgrep:**
- Repository → Security tab → Code scanning alerts
- Click alert for details, code location, and remediation

**OSV-Scanner:**
- Download `osv-scan-results` artifact from workflow run
- JSON format with vulnerability details

### Coverage Reports

**Codecov:**
- Appears as comment on PRs (if configured)
- Dashboard at `codecov.io/gh/YOUR_USERNAME/YOUR_REPO`
- Shows coverage trends, file-by-file breakdown

---

## 🚀 Usage After Bootstrap

After running `./template/bootstrap-guardrails.sh`:

1. **Push to GitHub**:
   ```bash
   git push origin main
   ```

2. **Check Actions Tab**:
   - Navigate to repository → Actions
   - Verify both workflows triggered
   - Check that all jobs passed

3. **Create a PR**:
   - Make a change and create PR
   - Both workflows run automatically
   - PR shows workflow status

4. **View Security Tab**:
   - Repository → Security → Code scanning
   - Semgrep findings appear here

---

## 🎨 Customization

### Disable Specific Jobs

Edit workflow files to comment out jobs:

```yaml
# jobs:
#   tests:
#     name: Unit Tests
#     runs-on: ubuntu-latest
```

### Adjust Security Rules

**Semgrep** - Edit `security-ci.yml`:

```yaml
config: >-
  p/security-audit
  p/owasp-top-ten
  p/django  # Add more rulesets
```

**OSV-Scanner** - Edit scan args:
```yaml
scan-args: |-
  --recursive
  --skip-git
  ./src  # Scan specific directory
```

### Add More Tests

The `ci.yaml` workflow auto-detects tests. Just add:
```bash
mkdir tests
# Add test files
pytest
```

---

## 📈 Comparison to Framework Repo

| Feature | Guardrails-AI | github-ai-engineering-framework |
|---------|---------------|----------------------------------|
| Pre-commit in CI | ✅ Yes | ✅ Yes |
| Test coverage | ✅ pytest-cov | ❌ Basic pytest only |
| Codecov integration | ✅ Yes | ❌ No |
| Gitleaks | ✅ Yes | ✅ Yes |
| Semgrep SAST | ✅ Yes | ✅ Yes |
| OSV-Scanner | ✅ Yes | ✅ Yes |
| Pre-commit caching | ✅ Yes | ✅ Yes |
| Verbose test output | ✅ Yes | ❌ No (`-q` only) |

**Result**: Guardrails-AI workflows are more comprehensive! 🎉

---

## 🐛 Troubleshooting

### Workflow Fails on Pre-commit

**Symptom**: Pre-commit job fails in CI but passes locally

**Causes**:
- Git hooks not installed locally (checks skipped)
- Using `--no-verify` to bypass local checks
- Different Python/tool versions

**Solution**:
```bash
# Always run pre-commit before pushing
pre-commit run --all-files
git push
```

### Workflow Fails on Tests

**Symptom**: Test job fails

**Causes**:
- Missing dependencies in `requirements.txt`
- Tests rely on local environment
- Coverage threshold not met

**Solution**:
```bash
# Test locally first
pytest -v --cov
pip freeze > requirements.txt  # Update dependencies
```

### Secret Found by Gitleaks

**Symptom**: Gitleaks job fails with secret detection

**Solution**:
1. **Do NOT push real secret fixes** to same branch
2. Rotate the compromised secret immediately
3. Use BFG Repo-Cleaner or `git filter-repo` to remove from history
4. Force push cleaned history
5. Update all consumers with new secret

---

## 📚 Related Documentation

- **`PRE_COMMIT_SETUP_SUMMARY.md`** - Pre-commit configuration
- **`IMPLEMENTATION_COMPLETE.md`** - Implementation details
- **`../CONTRIBUTING.md`** - Contribution guidelines

---

**Questions?** Check GitHub Actions documentation or open an issue!
