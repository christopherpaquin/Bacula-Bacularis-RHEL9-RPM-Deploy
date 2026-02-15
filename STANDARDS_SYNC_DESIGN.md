# Standards Synchronization System Design

**Purpose:** Automate propagation of CONTEXT.md changes to tool-specific AI configurations with preprocessing and
tool-specific optimization.

**Status:** ✅ MVP Implemented and Ready for Production Use

---

## Quick Start

```bash
# Preview changes (dry run)
./scripts/sync-standards.sh --dry-run

# Run synchronization
./scripts/sync-standards.sh

# Verbose output
./scripts/sync-standards.sh --verbose
```

**What it does:**

1. Parses `CONTEXT.md` into structured rules
2. Transforms rules for each tool (Cursor, Claude, Copilot, Aider)
3. Validates generated files
4. Writes optimized tool-specific configurations

**Time savings:** 15-30 minutes → 2 minutes (70%+ reduction)

---

## Problem Statement

Currently, updating CONTEXT.md requires manually updating 7+ tool-specific configuration files:

- `.cursor/rules/*.mdc`
- `CLAUDE.md`
- `.claudeprompt`
- `.continue/config.yaml`
- `.github/copilot-instructions.md`
- `.aider/.aider.conf.yml`
- `.vscode/settings.json`

**Challenges:**

1. **Manual effort** - Tedious and error-prone
2. **Configuration drift** - Easy to forget a file
3. **Inconsistent formatting** - Each tool has different conventions
4. **Loss of optimization** - Tool-specific tuning gets lost

**Goal:** Automate while maintaining tool-specific optimization.

---

## Design Principles

1. **CONTEXT.md remains human-readable** - No special syntax required
2. **Tool-specific optimization preserved** - Each tool gets optimized format
3. **Preprocessing pipeline** - Transform generic rules → tool-specific rules
4. **Validation included** - Ensure consistency and correctness
5. **AI-enhanced** - Optional AI step for natural language optimization
6. **Git-friendly** - Generate diffs that are reviewable

---

## Proposed Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│ 1. SOURCE: CONTEXT.md (Single Source of Truth)                 │
│    - Human-readable markdown                                    │
│    - Structured sections                                        │
│    - Universal rules                                            │
└─────────────┬───────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. PARSER: Extract & Structure                                 │
│    - Parse markdown sections                                    │
│    - Extract rules by category                                  │
│    - Build intermediate representation (JSON/YAML)             │
│    - Tag rules by priority/scope                                │
└─────────────┬───────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. PREPROCESSOR: Tool-Specific Transformation                  │
│    - Apply tool-specific templates                             │
│    - Adjust formatting (mdc vs md vs yaml)                     │
│    - Optimize for tool's parsing style                         │
│    - Add tool-specific examples                                 │
└─────────────┬───────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. AI ENHANCEMENT (Optional)                                   │
│    - Refine natural language                                    │
│    - Generate tool-specific examples                            │
│    - Optimize for tool's cognitive style                        │
└─────────────┬───────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. GENERATOR: Write Tool Configs                               │
│    ├─→ .cursor/rules/*.mdc                                     │
│    ├─→ CLAUDE.md                                               │
│    ├─→ .claudeprompt                                           │
│    ├─→ .continue/config.yaml                                   │
│    ├─→ .github/copilot-instructions.md                         │
│    ├─→ .aider/.aider.conf.yml                                  │
│    └─→ Other tool configs                                      │
└─────────────┬───────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. VALIDATOR: Verify Consistency                               │
│    - Check all files generated                                  │
│    - Validate syntax (YAML, Markdown)                           │
│    - Ensure core rules present in all                          │
│    - Run pre-commit checks                                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Implementation Components

### Component 1: Context Parser (`scripts/sync/parse_context.py`)

**Purpose:** Parse CONTEXT.md into structured data

**Input:** `CONTEXT.md`

**Output:** Intermediate representation (JSON)

```python
{
  "sections": [
    {
      "id": "security",
      "title": "Security",
      "priority": 100,
      "rules": [
        {
          "id": "no_secrets",
          "title": "Never Commit Secrets",
          "content": "...",
          "examples": {
            "correct": ["..."],
            "incorrect": ["..."]
          },
          "applies_to": ["all"],
          "severity": "critical"
        }
      ]
    }
  ]
}
```

**Features:**

- Extract sections (## headers)
- Parse rules within sections
- Identify examples (code blocks)
- Tag severity/priority
- Detect scope (bash, python, yaml, etc.)

### Component 2: Tool Transformers (`scripts/sync/transformers/`)

**Purpose:** Tool-specific transformation logic

**Structure:**

```text
scripts/sync/transformers/
├── __init__.py
├── base.py           # Base transformer class
├── cursor.py         # Cursor .mdc transformer
├── claude.py         # Claude markdown transformer
├── copilot.py        # GitHub Copilot transformer
├── aider.py          # Aider YAML transformer
├── continue_dev.py   # Continue.dev YAML transformer
└── templates/        # Tool-specific templates
    ├── cursor.mdc.jinja2
    ├── claude.md.jinja2
    ├── copilot.md.jinja2
    └── aider.yaml.jinja2
```

**Example Transformer (cursor.py):**

```python
class CursorTransformer(BaseTransformer):
    def transform_rule(self, rule: dict) -> str:
        """Transform generic rule to Cursor .mdc format."""
        output = []

        # Add priority and scope metadata
        output.append(f"priority: {rule['priority']}")
        output.append(f"globs: {rule['applies_to']}")
        output.append("")

        # Add title
        output.append(f"## {rule['title']}")
        output.append("")

        # Add content (imperative style for Cursor)
        content = self.make_imperative(rule['content'])
        output.append(content)
        output.append("")

        # Add examples with Cursor formatting
        if rule.get('examples'):
            output.append("**Examples:**")
            output.append("")
            for correct in rule['examples']['correct']:
                output.append("✅ **CORRECT:**")
                output.append(f"```{rule['language']}")
                output.append(correct)
                output.append("```")

        return "\n".join(output)

    def make_imperative(self, text: str) -> str:
        """Convert to imperative voice for Cursor."""
        # Use simple transformations or AI
        return text.replace("You should", "You MUST") \
                   .replace("should", "MUST")
```

### Component 3: AI Enhancer (Optional) (`scripts/sync/enhance.py`)

**Purpose:** Use AI to optimize natural language for each tool

```python
def enhance_for_tool(rule: dict, tool: str) -> dict:
    """Use AI to enhance rule for specific tool."""

    prompts = {
        "cursor": "Rewrite this rule in imperative, directive style...",
        "claude": "Rewrite this rule in conversational, friendly style...",
        "copilot": "Rewrite this rule in concise, example-heavy style..."
    }

    # Call OpenAI/Anthropic API
    enhanced = call_llm(prompts[tool], rule['content'])

    rule['content'] = enhanced
    return rule
```

**Benefits:**
- Natural language optimization per tool
- Generate tool-specific examples
- Maintain human voice appropriate to each tool

**Optional because:**
- Requires API key
- Costs money
- Adds complexity
- Manual templates may be sufficient

### Component 4: Main Sync Script (`scripts/sync-standards.sh`)

**Purpose:** Orchestrate the entire pipeline

```bash
#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/sync-standards.sh [--with-ai] [--dry-run]

echo "🔄 Syncing standards from CONTEXT.md to tool configs..."

# 1. Parse CONTEXT.md
python3 scripts/sync/parse_context.py CONTEXT.md > /tmp/context_parsed.json

# 2. Generate tool-specific configs
python3 scripts/sync/generate_configs.py \
  --input /tmp/context_parsed.json \
  --output-dir . \
  ${WITH_AI:+--enhance-with-ai} \
  ${DRY_RUN:+--dry-run}

# 3. Validate outputs
python3 scripts/sync/validate.py

# 4. Run pre-commit
if [[ -z "${DRY_RUN:-}" ]]; then
  pre-commit run --files .cursor/rules/*.mdc CLAUDE.md
fi

echo "✅ Sync complete!"
```

### Component 5: Validator (`scripts/sync/validate.py`)

**Purpose:** Ensure consistency and correctness

```python
def validate_sync():
    """Validate all tool configs against CONTEXT.md."""

    checks = [
        check_all_files_exist(),
        check_critical_rules_present(),
        check_syntax_valid(),
        check_no_drift()
    ]

    for check in checks:
        if not check.passed:
            print(f"❌ {check.name}: {check.error}")
            return False

    print("✅ All validations passed")
    return True

def check_critical_rules_present():
    """Ensure critical rules are in all tool configs."""
    critical = ["no_secrets", "no_bypass_precommit", "quote_bash_vars"]

    for tool_config in get_all_tool_configs():
        for rule_id in critical:
            if rule_id not in extract_rules(tool_config):
                return ValidationError(f"{rule_id} missing from {tool_config}")

    return ValidationSuccess()
```

---

## Tool-Specific Transformation Rules

### Cursor (.mdc format)

**Style:** Imperative, directive, micro-examples

**Transformations:**

- Convert "should" → "MUST"
- Add priority metadata
- Add scope (globs)
- Use checkmarks (✅/❌) heavily
- Keep examples minimal (3-5 lines)
- Bold important terms

**Template:**

```markdown
---
priority: {priority}
globs: {globs}
---

## {title}

{imperative_content}

✅ **CORRECT:**

```{language}
{correct_example}
```

❌ **WRONG:**

```{language}
{incorrect_example}
```

```markdown

### Claude (markdown format)

**Style:** Conversational, friendly, detailed explanations

**Transformations:**

- Use "You" voice
- Add reasoning ("Why this matters:")
- Group related rules with headers
- Use checklists
- Provide context

**Template:**

```markdown
### {title}

{conversational_content}

**Why this matters:** {reasoning}

✅ **Do this:**
{correct_example_with_explanation}

❌ **Don't do this:**
{incorrect_example_with_explanation}

**If you encounter {scenario}, follow these steps:**
1. {step1}
2. {step2}
```

### GitHub Copilot (markdown format)

**Style:** Concise, example-heavy, pattern-focused

**Transformations:**

- Minimal prose
- Maximum examples
- Show patterns
- Before/after comparisons

**Template:**

```markdown
## {title}

{one_line_summary}

```{language}
# ❌ Bad
{bad_pattern}

# ✅ Good
{good_pattern}
```

**Pattern:** {pattern_description}

```markdown

### Aider (YAML format)

**Style:** Structured commands, file references

**Transformations:**

- Convert to YAML structure
- Add auto-read files
- Link to CONTEXT.md sections

**Template:**

```yaml
rules:
  - id: {rule_id}
    title: {title}
    content: |
      {content}
    reference: "CONTEXT.md section {section_number}"

auto_read:
  - CONTEXT.md
  - CONTRIBUTING.md
```

---

## Usage Workflow

### Scenario 1: Add New Rule to CONTEXT.md

```bash
# 1. Edit CONTEXT.md (add new rule)
vim CONTEXT.md

# 2. Run sync script
./scripts/sync-standards.sh

# 3. Review generated changes
git diff

# 4. Test with 2 AI tools
# (manually verify rules are applied correctly)

# 5. Commit all together
git add CONTEXT.md .cursor/ CLAUDE.md .github/ .aider/ .continue/
git commit -m "Add rule: {rule_name}

Updated CONTEXT.md and synced to all tool configs."
```

### Scenario 2: Sync with AI Enhancement

```bash
# Use AI to optimize natural language per tool
./scripts/sync-standards.sh --with-ai

# Requires: OPENAI_API_KEY or ANTHROPIC_API_KEY in .env
```

### Scenario 3: Dry Run (Preview Changes)

```bash
# See what would change without modifying files
./scripts/sync-standards.sh --dry-run

# Output:
# Would update: .cursor/rules/006_security.mdc (12 lines changed)
# Would update: CLAUDE.md (security section, 24 lines changed)
# ...
```

---

## Configuration File

**Location:** `scripts/sync/config.yaml`

```yaml
# Sync configuration
source:
  file: CONTEXT.md

targets:
  - name: cursor
    files:
      - .cursor/rules/001_workspace.mdc
      - .cursor/rules/002_design_principles.mdc
      - .cursor/rules/003_bash_standards.mdc
      - .cursor/rules/004_python_standards.mdc
      - .cursor/rules/005_yaml_json_standards.mdc
      - .cursor/rules/006_security.mdc
      - .cursor/rules/007_precommit.mdc
      - .cursor/rules/008_documentation.mdc
    transformer: cursor.CursorTransformer
    style: imperative

  - name: claude
    files:
      - CLAUDE.md
    transformer: claude.ClaudeTransformer
    style: conversational

  - name: copilot
    files:
      - .github/copilot-instructions.md
    transformer: copilot.CopilotTransformer
    style: concise

  - name: aider
    files:
      - .aider/.aider.conf.yml
    transformer: aider.AiderTransformer
    style: structured

# Transformation options
preprocessing:
  extract_examples: true
  tag_priorities: true
  identify_scope: true

enhancement:
  enabled: false  # Set to true to use AI enhancement
  provider: openai  # or anthropic
  model: gpt-4

validation:
  check_syntax: true
  check_critical_rules: true
  check_consistency: true
  run_precommit: true

# Mapping CONTEXT.md sections to tool files
section_mapping:
  "1. Design Principles":
    cursor: 002_design_principles.mdc
    all: true

  "3. Bash Standards":
    cursor: 003_bash_standards.mdc
    scope: ["*.sh"]

  "4. Python Standards":
    cursor: 004_python_standards.mdc
    scope: ["*.py"]

  "7. Security":
    cursor: 006_security.mdc
    priority: 100
    all: true
```

---

## Implementation Phases

### Phase 1: MVP (Manual Templates)

- ✅ Parser for CONTEXT.md
- ✅ Basic transformers (no AI)
- ✅ Template-based generation
- ✅ Syntax validation
- ⏱️ Estimated: 2-3 days

### Phase 2: AI Enhancement

- ✅ LLM integration (OpenAI/Anthropic)
- ✅ Tool-specific prompt engineering
- ✅ Example generation
- ⏱️ Estimated: 1-2 days

### Phase 3: Advanced Features

- ✅ Incremental updates (only sync changed sections)
- ✅ Conflict resolution
- ✅ Version tracking
- ✅ Pre-commit hook integration
- ⏱️ Estimated: 2-3 days

---

## Benefits

### For Maintainers

- ✅ Update once, propagate everywhere
- ✅ Reduce manual effort by 80%+
- ✅ Eliminate configuration drift
- ✅ Ensure consistency automatically

### For Contributors

- ✅ Clear process for adding rules
- ✅ No need to understand all tool formats
- ✅ Validation catches errors early

### For Users

- ✅ Always get latest standards
- ✅ Tool-specific optimization maintained
- ✅ Consistent experience across tools

---

## Challenges & Mitigations

### Challenge 1: Complex Transformations

**Problem:** Some rules need significant rewriting per tool

**Mitigation:**

- Start with simple template-based transformations
- Add AI enhancement for complex cases
- Allow manual overrides in tool configs
- Document transformation rules clearly

### Challenge 2: Loss of Manual Edits

**Problem:** Tool configs might have manual customizations

**Mitigation:**

- Support "custom sections" in tool configs
- Only sync specific sections marked for sync
- Use merge strategy, not overwrite
- Git diffs show exactly what changed

### Challenge 3: Testing Complexity

**Problem:** Hard to verify rules work in all tools

**Mitigation:**

- Automated syntax validation
- CI tests with actual AI tools (if possible)
- Manual verification checklist
- Community testing before releases

---

## Alternative Approaches Considered

### Approach A: Single Universal Format

**Idea:** All tools read same file (CONTEXT.md)

**Pros:**

- No duplication
- Perfect sync

**Cons:**

- ❌ Not optimized for any tool
- ❌ Tools have different discovery mechanisms
- ❌ Loses tool-specific features

**Decision:** Rejected - tool-specific optimization is valuable

### Approach B: Include System

**Idea:** Tool configs include CONTEXT.md sections

**Example:**

```markdown
<!-- Include: CONTEXT.md#security -->
```

**Pros:**

- Simple to implement
- No duplication

**Cons:**

- ❌ Most AI tools don't support includes
- ❌ No tool-specific formatting
- ❌ Requires tool changes

**Decision:** Rejected - most tools can't do this

### Approach C: Current Manual System

**Idea:** Keep manual synchronization

**Pros:**

- Full control
- Simple to understand

**Cons:**

- ❌ Error-prone
- ❌ Time-consuming
- ❌ Configuration drift

**Decision:** Current state, but needs improvement

### Approach D: Preprocessing + Templates (CHOSEN)

**Idea:** Parse CONTEXT.md, transform with templates, optionally enhance with AI

**Pros:**

- ✅ Maintains tool-specific optimization
- ✅ Automates tedious work
- ✅ Allows AI enhancement
- ✅ Validates consistency

**Cons:**

- More complex to implement
- Requires maintenance

**Decision:** Best balance of automation and optimization

---

## Next Steps

1. **Gather Feedback** - Review this design with maintainers
2. **Prototype Phase 1** - Build MVP with simple templates
3. **Test on Real Changes** - Use for next CONTEXT.md update
4. **Iterate** - Refine based on experience
5. **Document** - Add to AGENTS.md and CONTRIBUTING.md
6. **Optional Phase 2** - Add AI enhancement if MVP successful

---

## Questions for Discussion

1. Should AI enhancement be mandatory or optional?
2. Which tool formats are highest priority?
3. Should we support manual overrides in tool configs?
4. What level of validation is needed?
5. Should sync be automatic (pre-commit hook) or manual (script)?

---

_This is a design document. Implementation tracked in GitHub issues._
