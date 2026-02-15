#!/usr/bin/env bash
set -euo pipefail

# Standards Synchronization Wrapper Script
#
# Synchronizes CONTEXT.md changes to all tool-specific AI configurations.
#
# Usage:
#   ./scripts/sync-standards.sh [OPTIONS]
#
# Options:
#   --dry-run    Preview changes without writing files
#   --verbose    Show detailed output
#   --help       Show help message

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Check Python version
check_python() {
  if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Error: python3 not found${NC}"
    echo "   Please install Python 3.11 or higher"
    exit 1
  fi

  local python_version
  python_version=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
  local major_version
  major_version=$(echo "${python_version}" | cut -d'.' -f1)
  local minor_version
  minor_version=$(echo "${python_version}" | cut -d'.' -f2)

  if [[ "${major_version}" -lt 3 ]] || { [[ "${major_version}" -eq 3 ]] && [[ "${minor_version}" -lt 11 ]]; }; then
    echo -e "${YELLOW}⚠️  Warning: Python ${python_version} detected${NC}"
    echo "   Python 3.11+ is recommended"
  fi
}

# Check dependencies
check_dependencies() {
  if ! python3 -c "import jinja2" 2> /dev/null; then
    echo -e "${YELLOW}⚠️  Installing required dependencies...${NC}"
    pip3 install --user jinja2 pyyaml || {
      echo -e "${RED}❌ Failed to install dependencies${NC}"
      echo "   Please install manually: pip3 install jinja2 pyyaml"
      exit 1
    }
  fi
}

# Main
main() {
  # Check prerequisites
  check_python
  check_dependencies

  # Change to repo root
  cd "${REPO_ROOT}"

  # Run Python script
  echo ""
  python3 "${SCRIPT_DIR}/sync-standards.py" "$@"
  local exit_code=$?

  if [[ ${exit_code} -eq 0 ]]; then
    echo -e "\n${GREEN}✅ Success!${NC}"
  else
    echo -e "\n${RED}❌ Synchronization failed${NC}"
  fi

  exit ${exit_code}
}

# Run main
main "$@"
