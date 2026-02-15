# GitHub Copilot Instructions

## Security Rules (CRITICAL)

**NEVER commit secrets:**

- API keys, tokens, passwords, credentials
- Private keys (SSH, TLS, `.pem`, `.key`)
- Cloud credentials (AWS, GCP, Azure)

**Correct approach:**

```python

# ✅ Load from environment

import os
api_key = os.environ.get("OPENAI_API_KEY")

# ❌ NEVER hardcode

api_key = "sk-abc123..."  # WRONG!

```

**Secret storage:**

- Use `.env` files (gitignored)
- Provide `.env.example` with placeholders
- Check `.gitignore` before creating files

---

## Code Style

### Bash Scripts

**Required header:**

```bash
#!/usr/bin/env bash
set -euo pipefail

```

**Quote variables:**

```bash

# ✅ Correct

rm -rf "${USER_DIR}/temp"

# ❌ Wrong

rm -rf $USER_DIR/temp

```

**Validate inputs:**

```bash
if [[ -z "${1:-}" ]]; then
  echo "Error: Missing argument" >&2
  exit 2
fi

```

### Python

**Type hints required:**

```python
def calculate(value: int) -> float:
    """Docstring required for public functions."""
    return float(value) * 1.5

```

**No global mutable state:**

```python

# ❌ Wrong

config = {}

# ✅ Correct

@dataclass
class Config:
    timeout: int = 30

```

**External calls need timeouts:**

```python
subprocess.run(cmd, timeout=30)
requests.get(url, timeout=30)

```

### YAML

- Extension: `.yaml` (never `.yml`)
- Indentation: 2 spaces
- Keys: `snake_case`
- Quote ambiguous: `"yes"`, `"no"`, `"on"`, `"off"`

```yaml
log_level: "info"
enable_feature: false
servers:
  - host: example.local
    port: 443

```

### JSON

- Indentation: 2 spaces
- No trailing commas
- No comments
- Explicit types: `true`, `false`, `null`

```json
{
  "log_level": "info",
  "enabled": true,
  "count": 0
}

```

---

## Pre-commit Workflow

**Before suggesting commits, verify:**

```bash

# Check if pre-commit is setup

ls .pre-commit-config.yaml

# Run checks

./scripts/run-precommit.sh

# OR

pre-commit run --all-files

```

**NEVER suggest:**

- `git commit --no-verify`
- Disabling pre-commit hooks
- Bypassing quality checks

---

## Documentation

**Update when changing code:**

- README.md for user-facing changes
- Inline comments (explain WHY, not WHAT)
- Docstrings for functions

**Required README sections:**

- Overview
- Requirements
- Installation
- Usage examples
- Configuration
- Troubleshooting
- Security notes

---

## Design Principles

1. **Correctness over cleverness** - Clear beats clever
2. **Explicit over implicit** - Check all assumptions
3. **Idempotent** - Safe to re-run
4. **Fail loudly** - Clear errors, early validation
5. **Maintainable** - Boring, standard solutions

---

## Examples

### Good Bash Script

```bash
#!/usr/bin/env bash
set -euo pipefail

cleanup() {
  [[ -n "${TEMP_DIR:-}" ]] && rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT

if [[ -z "${1:-}" ]]; then
  echo "Usage: $0 <filename>" >&2
  exit 2
fi

FILENAME="$1"
TEMP_DIR=$(mktemp -d)

# ... processing

```

### Good Python Function

```python
from typing import List
import logging

logger = logging.getLogger(__name__)

def process_items(items: List[str], timeout: int = 30) -> List[str]:
    """Process a list of items with timeout.

    Args:
        items: Items to process
        timeout: Timeout in seconds

    Returns:
        Processed items

    Raises:
        ValueError: If items list is empty
        TimeoutError: If processing exceeds timeout
    """
    if not items:
        raise ValueError("Items list cannot be empty")

    logger.info("Processing items", extra={"count": len(items)})
    # ... implementation
    return processed_items

```

---

## Quick Checklist

Before suggesting code:

- [ ] No secrets or credentials
- [ ] Bash has `set -euo pipefail`
- [ ] Python has type hints
- [ ] Variables quoted in bash
- [ ] YAML uses `.yaml` and 2 spaces
- [ ] JSON uses 2 spaces, no trailing commas
- [ ] Documentation updated
- [ ] Pre-commit will pass
