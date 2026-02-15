#!/usr/bin/env bash
# shellcheck disable=SC2001,SC2155  # Allow sed and declare+assign for readability
###############################################################################
# manage-precommit-hooks.sh
#
# Add, remove, enable, or disable pre-commit hooks.
#
# Usage:
#   ./scripts/manage-precommit-hooks.sh list
#   ./scripts/manage-precommit-hooks.sh enable <hook-id>
#   ./scripts/manage-precommit-hooks.sh disable <hook-id>
#   ./scripts/manage-precommit-hooks.sh show <hook-id>
#
# Examples:
#   ./scripts/manage-precommit-hooks.sh list
#   ./scripts/manage-precommit-hooks.sh disable shellcheck
#   ./scripts/manage-precommit-hooks.sh enable shellcheck
#   ./scripts/manage-precommit-hooks.sh show ruff
###############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get repository root
if git rev-parse --show-toplevel &> /dev/null; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
else
  echo -e "${RED}Error: Not in a git repository${NC}"
  exit 1
fi

CONFIG_FILE="${REPO_ROOT}/.pre-commit-config.yaml"

# Check if config exists
if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo -e "${RED}Error: .pre-commit-config.yaml not found${NC}"
  exit 1
fi

# Usage
usage() {
  cat << EOF
Usage: $0 <command> [arguments]

Commands:
  list              List all hooks and their status (enabled/disabled)
  enable <hook-id>  Enable a disabled hook
  disable <hook-id> Disable a hook (comments it out)
  show <hook-id>    Show configuration for a specific hook

Examples:
  $0 list
  $0 disable shellcheck
  $0 enable shellcheck
  $0 show ruff

EOF
  exit 1
}

# List all hooks
list_hooks() {
  echo "================================================================================"
  echo "Pre-commit Hooks Status"
  echo "================================================================================"
  echo ""

  # Parse YAML to find hooks
  local in_hooks=false
  local hook_id=""
  local is_commented=false

  while IFS= read -r line; do
    # Check if we're in a hooks section
    if [[ "${line}" =~ ^[[:space:]]*hooks:[[:space:]]*$ ]]; then
      in_hooks=true
      continue
    fi

    # Check if we left hooks section
    if [[ "${in_hooks}" == "true" ]] && [[ "${line}" =~ ^[[:space:]]*-[[:space:]]*repo: ]]; then
      in_hooks=false
    fi

    # Find hook IDs
    if [[ "${in_hooks}" == "true" ]] && [[ "${line}" =~ -[[:space:]]*id:[[:space:]]*(.+)$ ]]; then
      hook_id="${BASH_REMATCH[1]}"

      # Check if this hook is commented out (look at previous lines)
      is_commented=false

      # Simple check: if line starts with # it's commented
      if [[ "${line}" =~ ^[[:space:]]*#.*id: ]]; then
        is_commented=true
      fi

      if [[ "${is_commented}" == "true" ]]; then
        echo -e "${YELLOW}⚪ ${hook_id}${NC} (disabled)"
      else
        echo -e "${GREEN}✓ ${hook_id}${NC} (enabled)"
      fi
    fi
  done < "${CONFIG_FILE}"

  echo ""
  echo "Use '$0 show <hook-id>' to see hook configuration"
  echo "Use '$0 disable <hook-id>' to disable a hook"
  echo "Use '$0 enable <hook-id>' to enable a hook"
  echo ""
}

# Show hook configuration
show_hook() {
  local hook_id="$1"

  echo "================================================================================"
  echo "Hook Configuration: ${hook_id}"
  echo "================================================================================"
  echo ""

  # Extract hook configuration
  local in_hook=false
  local indent_level=0

  while IFS= read -r line; do
    # Found the hook
    if [[ "${line}" =~ -[[:space:]]*id:[[:space:]]*${hook_id}[[:space:]]*$ ]]; then
      in_hook=true
      echo "${line}"
      # Get indent level of the id line
      indent_level=$(echo "${line}" | sed 's/[^[:space:]].*$//' | wc -c)
      continue
    fi

    if [[ "${in_hook}" == "true" ]]; then
      # Check if we've moved to next hook or repo
      if [[ "${line}" =~ ^[[:space:]]*-[[:space:]]*(id|repo): ]]; then
        break
      fi

      # Print lines that are part of this hook (same or deeper indent)
      local current_indent=$(echo "${line}" | sed 's/[^[:space:]].*$//' | wc -c)
      if [[ ${current_indent} -gt ${indent_level} ]] || [[ -z "$(echo "${line}" | tr -d '[:space:]')" ]]; then
        echo "${line}"
      else
        break
      fi
    fi
  done < "${CONFIG_FILE}"

  echo ""
}

# Disable a hook
disable_hook() {
  local hook_id="$1"

  echo -e "${YELLOW}Disabling hook: ${hook_id}${NC}"

  # Create backup
  cp "${CONFIG_FILE}" "${CONFIG_FILE}.backup"

  # Comment out the hook and its configuration
  local in_hook=false
  local output=""

  while IFS= read -r line; do
    # Found the hook
    if [[ "${line}" =~ -[[:space:]]*id:[[:space:]]*${hook_id}[[:space:]]*$ ]]; then
      in_hook=true
      # Comment out this line
      output+="# ${line}"$'\n'
      continue
    fi

    if [[ "${in_hook}" == "true" ]]; then
      # Check if we've moved to next hook or repo
      if [[ "${line}" =~ ^[[:space:]]*-[[:space:]]*(id|repo): ]]; then
        in_hook=false
        output+="${line}"$'\n'
        continue
      fi

      # Comment out lines that are part of this hook
      if [[ -n "$(echo "${line}" | tr -d '[:space:]')" ]]; then
        output+="# ${line}"$'\n'
      else
        output+="${line}"$'\n'
      fi
    else
      output+="${line}"$'\n'
    fi
  done < "${CONFIG_FILE}"

  echo "${output}" > "${CONFIG_FILE}"

  echo -e "${GREEN}✓ Hook disabled: ${hook_id}${NC}"
  echo "Backup saved to: ${CONFIG_FILE}.backup"
  echo ""
  echo "Run 'pre-commit run --all-files' to verify"
}

# Enable a hook
enable_hook() {
  local hook_id="$1"

  echo -e "${GREEN}Enabling hook: ${hook_id}${NC}"

  # Create backup
  cp "${CONFIG_FILE}" "${CONFIG_FILE}.backup"

  # Uncomment the hook
  local in_hook=false
  local output=""

  while IFS= read -r line; do
    # Found the commented hook
    if [[ "${line}" =~ ^[[:space:]]*#[[:space:]]*-[[:space:]]*id:[[:space:]]*${hook_id}[[:space:]]*$ ]]; then
      in_hook=true
      # Uncomment this line
      uncommented=$(echo "${line}" | sed 's/^[[:space:]]*#[[:space:]]*//')
      output+="${uncommented}"$'\n'
      continue
    fi

    if [[ "${in_hook}" == "true" ]]; then
      # Check if we've moved to next hook or repo
      if [[ "${line}" =~ ^[[:space:]]*-[[:space:]]*(id|repo):|^[[:space:]]*#[[:space:]]*-[[:space:]]*(id|repo): ]]; then
        in_hook=false
        output+="${line}"$'\n'
        continue
      fi

      # Uncomment lines that are part of this hook
      if [[ "${line}" =~ ^[[:space:]]*#[[:space:]]* ]]; then
        uncommented=$(echo "${line}" | sed 's/^[[:space:]]*#[[:space:]]*//')
        output+="${uncommented}"$'\n'
      else
        output+="${line}"$'\n'
      fi
    else
      output+="${line}"$'\n'
    fi
  done < "${CONFIG_FILE}"

  echo "${output}" > "${CONFIG_FILE}"

  echo -e "${GREEN}✓ Hook enabled: ${hook_id}${NC}"
  echo "Backup saved to: ${CONFIG_FILE}.backup"
  echo ""
  echo "Run 'pre-commit run --all-files' to verify"
}

# Main
case "${1:-}" in
  list)
    list_hooks
    ;;
  show)
    if [[ -z "${2:-}" ]]; then
      echo -e "${RED}Error: Missing hook-id${NC}"
      usage
    fi
    show_hook "$2"
    ;;
  disable)
    if [[ -z "${2:-}" ]]; then
      echo -e "${RED}Error: Missing hook-id${NC}"
      usage
    fi
    disable_hook "$2"
    ;;
  enable)
    if [[ -z "${2:-}" ]]; then
      echo -e "${RED}Error: Missing hook-id${NC}"
      usage
    fi
    enable_hook "$2"
    ;;
  *)
    usage
    ;;
esac
