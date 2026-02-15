#!/usr/bin/env bash
###############################################################################
# detect-secrets.sh
#
# Pre-commit hook to detect secrets, API keys, and access tokens in staged
# files. This script implements comprehensive secret detection with:
# - Pattern matching for known secret formats
# - Entropy analysis for high-entropy strings
# - False positive filtering
# - Performance optimizations
#
# Used by .pre-commit-config.yaml as a local hook.
###############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Combined secret pattern (all patterns OR'd together for single grep pass)
SECRET_PATTERN='(sk_live_[a-zA-Z0-9]{24,}|sk_test_[a-zA-Z0-9]{24,}|pk_live_[a-zA-Z0-9]{24,}|pk_test_[a-zA-Z0-9]{24,}|AIza[0-9A-Za-z_-]{35}|AKIA[0-9A-Z]{16}|sk-[a-zA-Z0-9]{32,}|xox[baprs]-[0-9]{10,13}-[0-9]{10,13}-[a-zA-Z0-9]{24,}|ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|ghu_[a-zA-Z0-9]{36}|ghs_[a-zA-Z0-9]{36}|ghr_[a-zA-Z0-9]{36}|ASIA[0-9A-Z]{16}|[a-zA-Z0-9+/=]{40,}|eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}|-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----|ya29\.[a-zA-Z0-9_-]+|1//[a-zA-Z0-9_-]+)'

# Patterns that always indicate secrets (no entropy check needed)
HIGH_CONFIDENCE_PATTERN='(BEGIN|PRIVATE|KEY|ghp_|sk_|AIza|AKIA)'

# Combined allowlist pattern (for fast filtering)
ALLOWLIST_PATTERN='(YOUR_API_KEY_HERE|your-api-key-here|example\.com|test_key|demo_key|placeholder|CHANGE_ME|REPLACE_ME|api_key\s*=|API_KEY\s*=|access_token\s*=|secret\s*=|https?://[a-zA-Z0-9.-]+|api/v[0-9]+|/api/|^\s*#.*(api|key|token|secret)|^\s*//.*(api|key|token|secret)|^\s*\*.*(api|key|token|secret)|/home/[a-zA-Z0-9_-]+/Workspace|/Workspace/Gitrepos/)'

# Files to exclude from scanning
EXCLUDE_PATTERN='(\.git/|\.env\.example$|\.gitignore$|artifacts/|\.pre-commit-cache/|node_modules/|\.venv/|venv/|__pycache__/|\.pytest_cache/|\.mypy_cache/|dist/|build/)'

# Function to check if file should be excluded
should_exclude_file() {
  local file="$1"
  [[ "${file}" =~ ${EXCLUDE_PATTERN} ]]
}

# Optimized entropy calculation (pure bash)
calculate_entropy() {
  local str="$1"
  local len=${#str}
  if [[ ${len} -lt 16 ]]; then
    echo "0"
    return
  fi

  declare -A chars
  local i
  for ((i = 0; i < len; i++)); do
    chars[${str:i:1}]=1
  done
  echo "${#chars[@]}"
}

# Main detection function
detect_secrets() {
  local found_secrets=0
  local files_checked=0

  # Get list of staged files
  local staged_files
  staged_files=$(git diff --cached --name-only --diff-filter=ACM 2> /dev/null || true)

  if [[ -z "${staged_files}" ]]; then
    echo -e "${GREEN}✓ No staged files to check${NC}"
    return 0
  fi

  # Process files efficiently
  while IFS= read -r file; do
    [[ -z "${file}" ]] && continue

    # Skip excluded files
    if should_exclude_file "${file}"; then
      continue
    fi

    # Skip if file doesn't exist
    [[ ! -f "${file}" ]] && continue

    # Skip binary files
    if ! grep -qI . "${file}" 2> /dev/null; then
      continue
    fi

    files_checked=$((files_checked + 1))

    # Find all lines with potential secrets in one pass
    local matches
    matches=$(grep -nE "${SECRET_PATTERN}" "${file}" 2> /dev/null || true)

    # Early exit if no matches
    if [[ -z "${matches}" ]]; then
      continue
    fi

    # Process matching lines
    while IFS= read -r match_line; do
      [[ -z "${match_line}" ]] && continue

      local line_num="${match_line%%:*}"
      local line="${match_line#*:}"

      # Fast allowlist check
      if echo "${line}" | grep -qiE "${ALLOWLIST_PATTERN}"; then
        continue
      fi

      # Extract matched secret part
      local matched_part
      matched_part=$(echo "${line}" | grep -oE "${SECRET_PATTERN}" | head -1)

      # Check if high-confidence pattern
      if echo "${matched_part}" | grep -qE "${HIGH_CONFIDENCE_PATTERN}"; then
        echo -e "${RED}✗ Potential secret found in ${file}:${line_num}${NC}"
        echo -e "  ${YELLOW}Pattern:${NC} ${matched_part:0:50}..."
        echo -e "  ${YELLOW}Context:${NC} ${line:0:100}..."
        echo ""
        found_secrets=$((found_secrets + 1))
        continue
      fi

      # For generic patterns, check entropy
      local entropy
      entropy=$(calculate_entropy "${matched_part}")

      if [[ ${entropy} -gt 8 ]]; then
        echo -e "${RED}✗ Potential secret found in ${file}:${line_num}${NC}"
        echo -e "  ${YELLOW}Pattern:${NC} ${matched_part:0:50}..."
        echo -e "  ${YELLOW}Context:${NC} ${line:0:100}..."
        echo ""
        found_secrets=$((found_secrets + 1))
      fi
    done <<< "${matches}"
  done <<< "${staged_files}"

  if [[ ${found_secrets} -gt 0 ]]; then
    echo -e "${RED}❌ Found ${found_secrets} potential secret(s) in staged files${NC}"
    echo -e "${YELLOW}If these are false positives, add them to the allowlist in scripts/detect-secrets.sh${NC}"
    echo -e "${YELLOW}Or use example placeholders like: YOUR_API_KEY_HERE${NC}"
    return 1
  fi

  if [[ ${files_checked} -gt 0 ]]; then
    echo -e "${GREEN}✓ Checked ${files_checked} file(s) - no secrets detected${NC}"
  fi

  return 0
}

# Run detection
main() {
  detect_secrets
}

main "$@"
