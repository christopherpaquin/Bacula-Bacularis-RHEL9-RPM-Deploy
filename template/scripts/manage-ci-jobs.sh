#!/usr/bin/env bash
# shellcheck disable=SC2001,SC2155,SC2094  # Allow sed, declare+assign, and same-file pipeline for readability
###############################################################################
# manage-ci-jobs.sh
#
# Manage CI/CD workflow jobs (enable, disable, list).
#
# Usage:
#   ./scripts/manage-ci-jobs.sh list [workflow]
#   ./scripts/manage-ci-jobs.sh disable <workflow> <job>
#   ./scripts/manage-ci-jobs.sh enable <workflow> <job>
#   ./scripts/manage-ci-jobs.sh show <workflow> <job>
#
# Examples:
#   ./scripts/manage-ci-jobs.sh list
#   ./scripts/manage-ci-jobs.sh list ci.yaml
#   ./scripts/manage-ci-jobs.sh disable ci.yaml tests
#   ./scripts/manage-ci-jobs.sh enable ci.yaml tests
#   ./scripts/manage-ci-jobs.sh show security-ci.yml gitleaks
###############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get repository root
if git rev-parse --show-toplevel &> /dev/null; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
else
  echo -e "${RED}Error: Not in a git repository${NC}"
  exit 1
fi

WORKFLOWS_DIR="${REPO_ROOT}/.github/workflows"

# Check if workflows directory exists (try template/ if not in root)
if [[ ! -d "${WORKFLOWS_DIR}" ]]; then
  WORKFLOWS_DIR="${REPO_ROOT}/template/.github/workflows"
  if [[ ! -d "${WORKFLOWS_DIR}" ]]; then
    echo -e "${RED}Error: .github/workflows/ directory not found${NC}"
    echo "Checked:"
    echo "  - ${REPO_ROOT}/.github/workflows"
    echo "  - ${REPO_ROOT}/template/.github/workflows"
    exit 1
  fi
fi

# Usage
usage() {
  cat << EOF
Usage: $0 <command> [arguments]

Commands:
  list [workflow]           List all workflows and jobs
  show <workflow> <job>     Show configuration for a specific job
  disable <workflow> <job>  Disable a job (comments it out)
  enable <workflow> <job>   Enable a job (uncomments it)

Workflows:
  ci.yaml              - Main CI workflow (pre-commit + tests)
  security-ci.yml      - Security scanning workflow

Examples:
  $0 list
  $0 list ci.yaml
  $0 disable ci.yaml tests
  $0 enable ci.yaml tests
  $0 show security-ci.yml gitleaks

EOF
  exit 1
}

# List workflows and jobs
list_workflows() {
  local workflow_filter="${1:-}"

  echo "================================================================================"
  echo "CI/CD Workflows and Jobs"
  echo "================================================================================"
  echo ""

  for workflow_file in "${WORKFLOWS_DIR}"/*.{yaml,yml}; do
    [[ -f "${workflow_file}" ]] || continue

    local workflow_name=$(basename "${workflow_file}")

    # Skip if filtering and doesn't match
    if [[ -n "${workflow_filter}" ]] && [[ "${workflow_name}" != "${workflow_filter}" ]]; then
      continue
    fi

    echo -e "${BLUE}Workflow: ${workflow_name}${NC}"

    # Extract workflow name
    local wf_display_name=$(grep "^name:" "${workflow_file}" | head -1 | sed 's/^name:[[:space:]]*//')
    if [[ -n "${wf_display_name}" ]]; then
      echo "  Display name: ${wf_display_name}"
    fi

    echo "  Jobs:"

    # Extract jobs
    local in_jobs=false
    local job_name=""

    while IFS= read -r line; do
      # Found jobs section
      if [[ "${line}" =~ ^jobs:[[:space:]]*$ ]]; then
        in_jobs=true
        continue
      fi

      # End of jobs section
      if [[ "${in_jobs}" == "true" ]] && [[ "${line}" =~ ^[a-zA-Z] ]]; then
        break
      fi

      # Extract job names
      if [[ "${in_jobs}" == "true" ]] && [[ "${line}" =~ ^[[:space:]]*([a-zA-Z0-9_-]+):[[:space:]]*$ ]]; then
        job_name="${BASH_REMATCH[1]}"

        # Check if job is commented
        local is_commented=false
        if grep -B5 "^[[:space:]]*${job_name}:" "${workflow_file}" | grep -q "^[[:space:]]*#[[:space:]]*${job_name}:"; then
          is_commented=true
        fi

        # Get job display name if available
        local job_display_name=$(grep -A10 "^[[:space:]]*${job_name}:" "${workflow_file}" | grep "name:" | head -1 | sed 's/.*name:[[:space:]]*//' | tr -d '"')

        if [[ "${is_commented}" == "true" ]]; then
          echo -e "    ${YELLOW}⚪ ${job_name}${NC} (disabled)"
        else
          echo -e "    ${GREEN}✓ ${job_name}${NC}"
        fi

        if [[ -n "${job_display_name}" ]]; then
          echo "       → ${job_display_name}"
        fi
      fi
    done < "${workflow_file}"

    echo ""
  done

  echo "Use '$0 show <workflow> <job>' to see job configuration"
  echo "Use '$0 disable <workflow> <job>' to disable a job"
  echo "Use '$0 enable <workflow> <job>' to enable a job"
  echo ""
}

# Show job configuration
show_job() {
  local workflow="$1"
  local job_name="$2"
  local workflow_file="${WORKFLOWS_DIR}/${workflow}"

  if [[ ! -f "${workflow_file}" ]]; then
    echo -e "${RED}Error: Workflow file not found: ${workflow}${NC}"
    exit 1
  fi

  echo "================================================================================"
  echo "Job Configuration: ${workflow} → ${job_name}"
  echo "================================================================================"
  echo ""

  # Extract job configuration
  local in_job=false
  local base_indent=0

  while IFS= read -r line; do
    # Found the job
    if [[ "${line}" =~ ^[[:space:]]*${job_name}:[[:space:]]*$ ]]; then
      in_job=true
      echo "${line}"
      base_indent=$(echo "${line}" | sed 's/[^[:space:]].*$//' | wc -c)
      continue
    fi

    if [[ "${in_job}" == "true" ]]; then
      # Check if we've moved to next job (same indent level)
      local current_indent=$(echo "${line}" | sed 's/[^[:space:]].*$//' | wc -c)

      if [[ ${current_indent} -le ${base_indent} ]] && [[ -n "$(echo "${line}" | tr -d '[:space:]')" ]]; then
        break
      fi

      echo "${line}"
    fi
  done < "${workflow_file}"

  echo ""
}

# Disable a job
disable_job() {
  local workflow="$1"
  local job_name="$2"
  local workflow_file="${WORKFLOWS_DIR}/${workflow}"

  if [[ ! -f "${workflow_file}" ]]; then
    echo -e "${RED}Error: Workflow file not found: ${workflow}${NC}"
    exit 1
  fi

  echo -e "${YELLOW}Disabling job: ${job_name} in ${workflow}${NC}"

  # Create backup
  cp "${workflow_file}" "${workflow_file}.backup"

  # Comment out the job
  local in_job=false
  local base_indent=0
  local output=""

  while IFS= read -r line; do
    # Found the job
    if [[ "${line}" =~ ^([[:space:]]*)${job_name}:[[:space:]]*$ ]]; then
      in_job=true
      base_indent=$(echo "${line}" | sed 's/[^[:space:]].*$//' | wc -c)
      output+="# ${line}"$'\n'
      continue
    fi

    if [[ "${in_job}" == "true" ]]; then
      local current_indent=$(echo "${line}" | sed 's/[^[:space:]].*$//' | wc -c)

      # Check if we've moved to next job
      if [[ ${current_indent} -le ${base_indent} ]] && [[ -n "$(echo "${line}" | tr -d '[:space:]')" ]]; then
        in_job=false
        output+="${line}"$'\n'
        continue
      fi

      # Comment out job content
      if [[ -n "$(echo "${line}" | tr -d '[:space:]')" ]]; then
        output+="# ${line}"$'\n'
      else
        output+="${line}"$'\n'
      fi
    else
      output+="${line}"$'\n'
    fi
  done < "${workflow_file}"

  echo "${output}" > "${workflow_file}"

  echo -e "${GREEN}✓ Job disabled: ${job_name}${NC}"
  echo "Backup saved to: ${workflow_file}.backup"
  echo ""
  echo "Commit the change and push to apply to CI"
}

# Enable a job
enable_job() {
  local workflow="$1"
  local job_name="$2"
  local workflow_file="${WORKFLOWS_DIR}/${workflow}"

  if [[ ! -f "${workflow_file}" ]]; then
    echo -e "${RED}Error: Workflow file not found: ${workflow}${NC}"
    exit 1
  fi

  echo -e "${GREEN}Enabling job: ${job_name} in ${workflow}${NC}"

  # Create backup
  cp "${workflow_file}" "${workflow_file}.backup"

  # Uncomment the job
  local in_job=false
  local base_indent=0
  local output=""

  while IFS= read -r line; do
    # Found the commented job
    if [[ "${line}" =~ ^([[:space:]]*)#[[:space:]]*${job_name}:[[:space:]]*$ ]]; then
      in_job=true
      base_indent=$(echo "${line}" | sed 's/[^[:space:]].*$//' | wc -c)
      uncommented=$(echo "${line}" | sed 's/^[[:space:]]*#[[:space:]]*//')
      output+="${uncommented}"$'\n'
      continue
    fi

    if [[ "${in_job}" == "true" ]]; then
      # Check if line is not commented (end of commented block)
      if [[ ! "${line}" =~ ^[[:space:]]*#[[:space:]]* ]] && [[ -n "$(echo "${line}" | tr -d '[:space:]')" ]]; then
        in_job=false
        output+="${line}"$'\n'
        continue
      fi

      # Uncomment job content
      if [[ "${line}" =~ ^[[:space:]]*#[[:space:]]* ]]; then
        uncommented=$(echo "${line}" | sed 's/^([[:space:]]*)#[[:space:]]*/\1/')
        output+="${uncommented}"$'\n'
      else
        output+="${line}"$'\n'
      fi
    else
      output+="${line}"$'\n'
    fi
  done < "${workflow_file}"

  echo "${output}" > "${workflow_file}"

  echo -e "${GREEN}✓ Job enabled: ${job_name}${NC}"
  echo "Backup saved to: ${workflow_file}.backup"
  echo ""
  echo "Commit the change and push to apply to CI"
}

# Main
case "${1:-}" in
  list)
    list_workflows "${2:-}"
    ;;
  show)
    if [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]]; then
      echo -e "${RED}Error: Missing workflow or job name${NC}"
      usage
    fi
    show_job "$2" "$3"
    ;;
  disable)
    if [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]]; then
      echo -e "${RED}Error: Missing workflow or job name${NC}"
      usage
    fi
    disable_job "$2" "$3"
    ;;
  enable)
    if [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]]; then
      echo -e "${RED}Error: Missing workflow or job name${NC}"
      usage
    fi
    enable_job "$2" "$3"
    ;;
  *)
    usage
    ;;
esac
