#!/usr/bin/env bash
###############################################################################
# setup-precommit.sh
#
# Configures and installs pre-commit in a repository.
#
# Usage:
#   ./scripts/setup-precommit.sh [--force]
#
# What it does:
#   - Installs pre-commit hooks (both pre-commit and commit-msg)
#   - Verifies installation
#   - Runs pre-commit on all files to ensure everything works
#   - Provides troubleshooting guidance if issues are found
#
# Options:
#   --force    Reinstall hooks even if already installed
###############################################################################

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
FORCE=false
if [[ "${1:-}" == "--force" ]]; then
  FORCE=true
fi

# Get repository root
if git rev-parse --show-toplevel &> /dev/null; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
else
  echo -e "${RED}Error: Not in a git repository${NC}"
  exit 1
fi

cd "${REPO_ROOT}"

echo "================================================================================"
echo "Pre-commit Setup"
echo "================================================================================"
echo ""

# Check if pre-commit is installed
echo -e "${BLUE}Checking pre-commit installation...${NC}"
if ! command -v pre-commit &> /dev/null; then
  echo -e "${RED}Error: pre-commit is not installed${NC}"
  echo ""
  echo "Install pre-commit with one of the following:"
  echo "  pip install pre-commit"
  echo "  brew install pre-commit"
  echo "  pipx install pre-commit"
  echo ""
  exit 1
fi

echo -e "${GREEN}✓ pre-commit is installed: $(pre-commit --version)${NC}"
echo ""

# Check if .pre-commit-config.yaml exists
echo -e "${BLUE}Checking pre-commit configuration...${NC}"
if [[ ! -f "${REPO_ROOT}/.pre-commit-config.yaml" ]]; then
  echo -e "${RED}Error: .pre-commit-config.yaml not found${NC}"
  echo ""
  echo "This repository doesn't have a pre-commit configuration."
  echo "Run the bootstrap script first if this is from the AI Guardrails template:"
  echo "  ./template/bootstrap-guardrails.sh"
  echo ""
  exit 1
fi

echo -e "${GREEN}✓ .pre-commit-config.yaml found${NC}"
echo ""

# Check if hooks are already installed
HOOKS_INSTALLED=false
if [[ -f "${REPO_ROOT}/.git/hooks/pre-commit" ]]; then
  if grep -q "pre-commit" "${REPO_ROOT}/.git/hooks/pre-commit" 2> /dev/null; then
    HOOKS_INSTALLED=true
  fi
fi

if [[ "${HOOKS_INSTALLED}" == "true" ]] && [[ "${FORCE}" == "false" ]]; then
  echo -e "${YELLOW}Pre-commit hooks are already installed${NC}"
  echo "Use --force to reinstall"
  echo ""
else
  # Install pre-commit hooks
  echo -e "${BLUE}Installing pre-commit hooks...${NC}"
  pre-commit install
  echo ""

  # Install commit-msg hook
  echo -e "${BLUE}Installing commit-msg hook...${NC}"
  pre-commit install --hook-type commit-msg
  echo ""
fi

# Verify installation
echo -e "${BLUE}Verifying installation...${NC}"
if [[ -f "${REPO_ROOT}/.git/hooks/pre-commit" ]]; then
  echo -e "${GREEN}✓ pre-commit hook installed${NC}"
else
  echo -e "${RED}✗ pre-commit hook NOT installed${NC}"
fi

if [[ -f "${REPO_ROOT}/.git/hooks/commit-msg" ]]; then
  echo -e "${GREEN}✓ commit-msg hook installed${NC}"
else
  echo -e "${YELLOW}⚠ commit-msg hook NOT installed (may not be needed)${NC}"
fi
echo ""

# Run pre-commit on all files
echo -e "${BLUE}Running pre-commit on all files (this may take a while)...${NC}"
echo ""

set +e
pre-commit run --all-files
PRECOMMIT_RC=$?
set -e

echo ""
if [[ ${PRECOMMIT_RC} -eq 0 ]]; then
  echo "================================================================================"
  echo -e "${GREEN}✅ Pre-commit setup complete and all checks passed!${NC}"
  echo "================================================================================"
  echo ""
  echo "Pre-commit is now active and will run automatically on every commit."
  echo ""
  echo "To manually run pre-commit:"
  echo "  pre-commit run --all-files"
  echo ""
  echo "To update hooks to latest versions:"
  echo "  pre-commit autoupdate"
  echo ""
else
  echo "================================================================================"
  echo -e "${YELLOW}⚠️  Pre-commit setup complete but some checks failed${NC}"
  echo "================================================================================"
  echo ""
  echo "Pre-commit hooks are installed but some checks failed."
  echo "This is normal for existing code that hasn't been formatted yet."
  echo ""
  echo "Many hooks auto-fix issues. Run again to apply fixes:"
  echo "  pre-commit run --all-files"
  echo ""
  echo "To see detailed output in a log file:"
  echo "  ./scripts/run-precommit.sh"
  echo ""
  echo "To skip pre-commit for a single commit (NOT recommended):"
  echo "  git commit --no-verify"
  echo ""
fi

# Show which hooks are installed
echo "Installed hooks:"
for hook in pre-commit commit-msg pre-push; do
  if [[ -f "${REPO_ROOT}/.git/hooks/${hook}" ]]; then
    echo "  - ${hook}"
  fi
done
echo ""

echo "For more information, see:"
echo "  - README.md"
echo "  - template/PRE_COMMIT_SETUP_SUMMARY.md (if using template)"
echo ""

exit ${PRECOMMIT_RC}
