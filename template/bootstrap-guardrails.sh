#!/usr/bin/env bash
###############################################################################
# bootstrap-guardrails.sh
#
# Copies AI Guardrails infrastructure from template/ to project root.
#
# Usage:
#   ./template/bootstrap-guardrails.sh
#
# What it does:
#   - Copies pre-commit configuration and scripts
#   - Copies CI/CD workflows
#   - Creates necessary directories
#   - Sets up pre-commit hooks
###############################################################################

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get repository root
if git rev-parse --show-toplevel &> /dev/null; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
else
  REPO_ROOT="$(pwd)"
fi

TEMPLATE_DIR="${REPO_ROOT}/template"

# Check if template directory exists
if [[ ! -d "${TEMPLATE_DIR}" ]]; then
  echo -e "${RED}Error: template/ directory not found${NC}"
  echo "This script should be run from a repository that contains the AI Guardrails template."
  exit 1
fi

echo "================================================================================"
echo "AI Guardrails Bootstrap"
echo "================================================================================"
echo ""
echo "This script will copy pre-commit infrastructure from template/ to your project."
echo ""
echo -e "${YELLOW}The following will be copied:${NC}"
echo "  - Workflow instructions (AGENTS.md - template for your project)"
echo "  - Implementation tracking (WORKLOG.md - template for tracking work)"
echo "  - Pre-commit configuration (.pre-commit-config.yaml)"
echo "  - PyMarkdown configuration (.pymarkdown.json)"
echo "  - Security scripts (scripts/detect-secrets.sh, scripts/check-commit-message.sh)"
echo "  - Pre-commit wrapper (scripts/run-precommit.sh)"
echo "  - CI/CD workflows (.github/workflows/ci.yaml, .github/workflows/security-ci.yml)"
echo "  - Development dependencies (requirements-dev.txt)"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

# Create directories
echo -e "${GREEN}Creating directories...${NC}"
mkdir -p "${REPO_ROOT}/scripts"
mkdir -p "${REPO_ROOT}/.github/workflows"
mkdir -p "${REPO_ROOT}/artifacts"

# Copy AGENTS.md template
echo -e "${GREEN}Copying AGENTS.md template...${NC}"
if [[ -f "${TEMPLATE_DIR}/AGENTS.md.template" ]] && [[ ! -f "${REPO_ROOT}/AGENTS.md" ]]; then
  cp "${TEMPLATE_DIR}/AGENTS.md.template" "${REPO_ROOT}/AGENTS.md"
  echo -e "${GREEN}  Copied AGENTS.md template${NC}"
  echo -e "${YELLOW}  ⚠️  Remember to customize AGENTS.md for your project!${NC}"
elif [[ -f "${REPO_ROOT}/AGENTS.md" ]]; then
  echo -e "${YELLOW}  AGENTS.md already exists, skipping${NC}"
else
  echo -e "${YELLOW}  AGENTS.md.template not found, skipping${NC}"
fi

# Copy WORKLOG.md template
echo -e "${GREEN}Copying WORKLOG.md template...${NC}"
if [[ -f "${REPO_ROOT}/../WORKLOG.md" ]] && [[ ! -f "${REPO_ROOT}/WORKLOG.md" ]]; then
  cp "${REPO_ROOT}/../WORKLOG.md" "${REPO_ROOT}/WORKLOG.md"
  echo -e "${GREEN}  Copied WORKLOG.md template${NC}"
  echo -e "${YELLOW}  ⚠️  AI agents will use this to track implementation work${NC}"
elif [[ -f "${REPO_ROOT}/WORKLOG.md" ]]; then
  echo -e "${YELLOW}  WORKLOG.md already exists, skipping${NC}"
else
  # Create basic WORKLOG.md if template not found
  cat > "${REPO_ROOT}/WORKLOG.md" << 'EOF'
# Implementation Work Log

**Purpose:** Track features added, implementation decisions, and findings to prevent circular work and maintain context for AI agents.

**Instructions for AI Agents:**
- Update this file whenever you add features, make significant changes, or discover important findings
- Keep entries brief (1-3 lines per item)
- Focus on WHAT was done and WHY certain approaches work or don't work

---

## YYYY-MM-DD

### Features Added
- Feature or change description

### Findings & Decisions
- Important discoveries or decisions made
- Why certain approaches were chosen

### What Doesn't Work
- Approaches that were tried but failed
- Saves time by preventing re-attempts

---

_See WORKLOG_USAGE.md for detailed usage instructions._
EOF
  echo -e "${GREEN}  Created basic WORKLOG.md${NC}"
fi

# Copy files
echo -e "${GREEN}Copying pre-commit configuration...${NC}"
# Copy and update paths for project use (template/scripts/ -> scripts/)
sed 's|template/scripts/|scripts/|g; s|template/.pymarkdown.json|.pymarkdown.json|g; s|template/\(CI_WORKFLOWS\|IMPLEMENTATION_COMPLETE\|PRE_COMMIT_SETUP_SUMMARY\|TEMPLATE_STRUCTURE\|USAGE\)\.md|excluded-template-docs.md|g' \
  "${TEMPLATE_DIR}/.pre-commit-config.yaml" > "${REPO_ROOT}/.pre-commit-config.yaml"
cp "${TEMPLATE_DIR}/.pymarkdown.json" "${REPO_ROOT}/"

echo -e "${GREEN}Copying scripts...${NC}"
cp "${TEMPLATE_DIR}/scripts/detect-secrets.sh" "${REPO_ROOT}/scripts/"
cp "${TEMPLATE_DIR}/scripts/check-commit-message.sh" "${REPO_ROOT}/scripts/"
cp "${TEMPLATE_DIR}/scripts/run-precommit.sh" "${REPO_ROOT}/scripts/"
chmod +x "${REPO_ROOT}/scripts/"*.sh

echo -e "${GREEN}Copying CI/CD workflows...${NC}"
cp "${TEMPLATE_DIR}/.github/workflows/ci.yaml" "${REPO_ROOT}/.github/workflows/"
cp "${TEMPLATE_DIR}/.github/workflows/security-ci.yml" "${REPO_ROOT}/.github/workflows/"

echo -e "${GREEN}Copying requirements...${NC}"
if [[ ! -f "${REPO_ROOT}/requirements-dev.txt" ]]; then
  cp "${TEMPLATE_DIR}/requirements-dev.txt" "${REPO_ROOT}/"
else
  echo -e "${YELLOW}  requirements-dev.txt already exists, skipping${NC}"
fi

# Update .gitignore if needed
echo -e "${GREEN}Updating .gitignore...${NC}"
if [[ -f "${REPO_ROOT}/.gitignore" ]]; then
  if ! grep -q "^artifacts/" "${REPO_ROOT}/.gitignore"; then
    echo -e "\n# Pre-commit artifacts and logs\nartifacts/\n.pre-commit-cache/" >> "${REPO_ROOT}/.gitignore"
    echo -e "${GREEN}  Added artifacts/ and .pre-commit-cache/ to .gitignore${NC}"
  else
    echo -e "${YELLOW}  .gitignore already contains artifacts/, skipping${NC}"
  fi
else
  # Copy comprehensive .gitignore template if available
  if [[ -f "${TEMPLATE_DIR}/.gitignore.template" ]]; then
    cp "${TEMPLATE_DIR}/.gitignore.template" "${REPO_ROOT}/.gitignore"
    echo -e "${GREEN}  Copied comprehensive .gitignore from template${NC}"
  else
    # Fallback to basic .gitignore
    cat > "${REPO_ROOT}/.gitignore" << EOF
# Pre-commit artifacts and logs
artifacts/
.pre-commit-cache/

# Python
__pycache__/
*.py[cod]
*.pyc
.pytest_cache/
.mypy_cache/
.ruff_cache/
*.egg-info/
dist/
build/

# Logs
*.log

# OS
.DS_Store
Thumbs.db
EOF
    echo -e "${GREEN}  Created basic .gitignore${NC}"
  fi
fi

# Install pre-commit hooks
echo -e "${GREEN}Installing pre-commit hooks...${NC}"
if command -v pre-commit &> /dev/null; then
  pre-commit install
  pre-commit install --hook-type commit-msg
  echo -e "${GREEN}  Pre-commit hooks installed${NC}"
else
  echo -e "${YELLOW}  Warning: pre-commit not found. Install with: pip install pre-commit${NC}"
  echo -e "${YELLOW}  Then run: pre-commit install && pre-commit install --hook-type commit-msg${NC}"
fi

echo ""
echo "================================================================================"
echo -e "${GREEN}✅ Bootstrap complete!${NC}"
echo "================================================================================"
echo ""
echo "Next steps:"
echo "  1. Customize AGENTS.md for your project:"
echo "     - Replace [bracketed placeholders] with actual values"
echo "     - Add project-specific commands and workflows"
echo "     - Remove sections that don't apply"
echo ""
echo "  2. Review WORKLOG.md setup:"
echo "     - Read WORKLOG_USAGE.md for detailed instructions"
echo "     - Instruct AI agents to update WORKLOG.md after completing work"
echo "     - Prevents circular debugging and maintains context"
echo ""
echo "  3. Install pre-commit (if not already installed):"
echo "     pip install pre-commit"
echo ""
echo "  4. Install development dependencies:"
echo "     pip install -r requirements-dev.txt"
echo ""
echo "  5. Run pre-commit on all files:"
echo "     pre-commit run --all-files"
echo ""
echo "  6. Commit the changes:"
echo "     git add -A"
echo "     git commit -m \"Add AI Guardrails pre-commit infrastructure\""
echo ""
echo "For more information, see:"
echo "  - WORKLOG_USAGE.md - How to use implementation tracking"
echo "  - ${TEMPLATE_DIR}/PRE_COMMIT_SETUP_SUMMARY.md"
echo "  - CONTRIBUTING.md"
echo ""
