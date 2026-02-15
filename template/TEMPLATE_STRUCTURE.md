# Template Repository Structure

**Date**: February 8, 2026

**Purpose**: This document explains the structure of the AI Guardrails repository and how to use it as a GitHub template.

---

## 📁 Repository Structure

```text
Guardrails-AI/
├── .cursor/rules/              # Cursor AI rules (context files)
├── .aider/                     # Aider AI configuration (context files)
├── .github/
│   ├── copilot-instructions.md # GitHub Copilot instructions (context file)
│   └── ISSUE_TEMPLATE/         # Issue templates (for this repo)
├── CLAUDE.md                   # Claude AI instructions (context file)
├── .claudeprompt               # Claude Projects config (context file)
├── CONTEXT.md                  # Canonical standards document (context file)
├── CONTRIBUTING.md             # Contribution guidelines (documentation)
├── README.md                   # Main documentation (documentation)
├── USAGE.md                    # Usage instructions (documentation)
├── LICENSE                     # Apache 2.0 license
├── .gitignore                  # Git ignore patterns
├── .pre-commit-config.yaml     # Pre-commit config FOR THIS REPO (references template/)
├── .pymarkdown.json            # PyMarkdown config FOR THIS REPO (references template/)
└── template/                   # ⭐ Infrastructure to copy to projects
    ├── .github/workflows/      # CI/CD workflows
    │   ├── ci.yaml             # Main CI pipeline
    │   └── security-ci.yml     # Security scanning
    ├── scripts/                # Security and utility scripts
    │   ├── detect-secrets.sh   # Secret detection
    │   ├── check-commit-message.sh  # Commit message validation
    │   └── run-precommit.sh    # Pre-commit wrapper
    ├── .pre-commit-config.yaml # Pre-commit config FOR PROJECTS (references scripts/)
    ├── .pymarkdown.json        # PyMarkdown configuration
    ├── requirements-dev.txt    # Development dependencies
    ├── bootstrap-guardrails.sh # Bootstrap script to copy to projects
    ├── PRE_COMMIT_SETUP_SUMMARY.md  # Setup documentation
    └── IMPLEMENTATION_COMPLETE.md   # Implementation details
```

---

## 🎯 Two Types of Files

### 1. AI Context Files (Root Directory)

These files teach AI coding assistants about standards and best practices:

- **`.cursor/rules/*.mdc`** - Cursor-specific rules with priorities
- **`CLAUDE.md`** - Claude Desktop instructions
- **`.claudeprompt`** - Claude Projects instructions
- **`.github/copilot-instructions.md`** - GitHub Copilot instructions
- **`.aider/.aider.conf.yml`** - Aider configuration
- **`CONTEXT.md`** - Canonical standards (source of truth)
- **`CONTRIBUTING.md`** - Guidelines for contributors
- **`README.md`** - Repository overview
- **`USAGE.md`** - How to use the guardrails

**Purpose**: These files stay in your project permanently to guide AI tools.

### 2. Infrastructure Files (template/ Directory)

These files provide pre-commit hooks, CI/CD, and quality enforcement:

- **Scripts**: Secret detection, commit message validation
- **Workflows**: GitHub Actions for CI and security scanning
- **Configs**: Pre-commit and linting configurations
- **Bootstrap**: Script to copy infrastructure to projects

**Purpose**: These files are copied to your project root during setup.

---

## 🚀 How to Use This Template

### Option 1: As a GitHub Template

1. **Create a new repository** from this template on GitHub
2. **Clone your new repository**
3. **Run the bootstrap script**:

   ```bash
   ./template/bootstrap-guardrails.sh
   ```

4. **Commit the changes**:

   ```bash
   git add -A
   git commit -m "Add AI Guardrails infrastructure"
   git push
   ```

### Option 2: Add to Existing Project

1. **Copy this repository** to a subdirectory:

   ```bash
   git clone https://github.com/YOUR_USERNAME/Guardrails-AI.git ai-guardrails
   cd your-project
   ```

2. **Run the bootstrap script**:

   ```bash
   ./ai-guardrails/template/bootstrap-guardrails.sh
   ```

3. **Keep the AI context files**:

   ```bash
   cp ai-guardrails/CLAUDE.md .
   cp ai-guardrails/.claudeprompt .
   cp -r ai-guardrails/.cursor .
   # ... copy other context files as needed
   ```

4. **Commit and clean up**:

   ```bash
   git add -A
   git commit -m "Add AI Guardrails"
   rm -rf ai-guardrails
   ```

---

## 🔧 What the Bootstrap Script Does

The `template/bootstrap-guardrails.sh` script:

1. ✅ Creates `scripts/` directory
2. ✅ Creates `.github/workflows/` directory
3. ✅ Creates `artifacts/` directory (for logs)
4. ✅ Copies all scripts with executable permissions
5. ✅ Copies pre-commit configuration
6. ✅ Copies CI/CD workflows
7. ✅ Copies development dependencies
8. ✅ Updates `.gitignore`
9. ✅ Installs pre-commit hooks (if pre-commit is installed)
10. ✅ Provides next steps

---

## 🎨 Customizing for Your Project

### Keep What You Need

Not all projects need all the guardrails. Customize:

1. **Edit `.pre-commit-config.yaml`** - Comment out hooks you don't need
2. **Edit `scripts/detect-secrets.sh`** - Adjust secret patterns for your stack
3. **Edit `.github/workflows/`** - Customize CI/CD for your needs
4. **Edit `.cursor/rules/`** - Add project-specific rules

### Path Differences

**Important**: The repository has TWO pre-commit configs:

- **Root `.pre-commit-config.yaml`**: For this repo's pre-commit (paths: `template/scripts/`)
- **`template/.pre-commit-config.yaml`**: For target projects (paths: `scripts/`)

This allows this repo to use pre-commit while providing correct paths for projects.

---

## 📚 Key Files Explained

| File | Purpose | Location |
|------|---------|----------|
| `CLAUDE.md` | Claude instructions | Root (copy to projects) |
| `.cursor/rules/*.mdc` | Cursor AI rules | Root (copy to projects) |
| `CONTEXT.md` | Canonical standards | Root (copy to projects) |
| `template/scripts/detect-secrets.sh` | Secret scanning | Template (copy to `scripts/`) |
| `template/.pre-commit-config.yaml` | Pre-commit config | Template (copy to root) |
| `template/.github/workflows/` | CI/CD workflows | Template (copy to `.github/workflows/`) |
| `template/bootstrap-guardrails.sh` | Setup automation | Template (run once) |

---

## ✅ Verification

After running the bootstrap script:

```bash
# Check files were copied
ls -la scripts/
ls -la .github/workflows/
ls -la .pre-commit-config.yaml

# Check pre-commit hooks installed
ls -la .git/hooks/pre-commit
ls -la .git/hooks/commit-msg

# Run pre-commit
pre-commit run --all-files
```

---

## 🔒 Security Features

After bootstrap, your project will have:

- **Local secret detection** (pre-commit)
- **Commit message validation** (pre-commit)
- **CI secret scanning** (GitHub Actions - Gitleaks)
- **SAST scanning** (GitHub Actions - Semgrep)
- **Dependency scanning** (GitHub Actions - OSV-Scanner)

---

## 📖 Further Reading

- **`template/PRE_COMMIT_SETUP_SUMMARY.md`** - Detailed setup guide
- **`template/IMPLEMENTATION_COMPLETE.md`** - Implementation details
- **`CONTRIBUTING.md`** - Contribution guidelines
- **`USAGE.md`** - How to use AI Guardrails

---

**Questions?** Open an issue on GitHub!
