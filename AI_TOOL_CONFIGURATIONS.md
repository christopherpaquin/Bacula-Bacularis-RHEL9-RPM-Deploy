# AI Tool Configurations

**Last Updated**: February 8, 2026

---

## Overview

This repository provides optimized configurations for **10+ AI coding assistants**. Each tool receives a configuration
in its native format, all derived from our canonical standards in `CONTEXT.md`.

Additionally, we support **AGENTS.md** - an open format for workflow instructions inspired by
[agents.md](https://agents.md). While tool-specific configs provide standards enforcement, AGENTS.md
provides project-specific workflow guidance.

---

## ✅ Universal Formats

### AGENTS.md

**Configuration**: `AGENTS.md` (root level)

**Format**: Markdown with workflow instructions

**Purpose**: Project-specific workflow guidance for AI agents

**Features**:
- Inspired by the [agents.md](https://agents.md) open format (17.1k+ stars)
- Complements tool-specific configs with workflow instructions
- Answers "How do I work on THIS project?"
- Not tool-specific - works with any AI coding agent

**Content**:
- Development environment setup
- Testing instructions
- Common development tasks
- Git workflow and commit format
- PR process and checklist
- Project-specific guidelines
- Debugging and troubleshooting
- Useful commands reference

**How to use**:
1. Copy `template/AGENTS.md.template` to your project root as `AGENTS.md`
2. Customize for your specific project:
   - Replace [bracketed placeholders]
   - Add your tech stack and commands
   - Document your workflows
   - Add project-specific sections

---

### WORKLOG.md

**Configuration**: `WORKLOG.md` (root level)

**Format**: Markdown log with dated entries

**Purpose**: Implementation tracking to prevent circular work and maintain context

**Features**:
- Tracks features added, decisions made, and failed approaches
- Prevents AI agents from repeating failed experiments
- Maintains context across multiple agent sessions
- Reduces hallucination by providing documented facts

**Content**:
- **Features Added**: Brief summaries of what was built
- **Findings & Decisions**: Why certain approaches were chosen
- **What Doesn't Work**: Failed approaches to avoid re-trying

**How to use**:
1. Copy `WORKLOG.md` and `WORKLOG_USAGE.md` to your project
2. Instruct AI agents to:
   - Read `WORKLOG.md` before starting work
   - Update it after completing significant work
3. Keep entries brief (1-3 lines per item)
4. Archive old entries if file exceeds 500 lines

**Example entry**:
```markdown
## 2026-02-15

### Features Added
- Implemented JWT authentication with refresh tokens
- Added rate limiting middleware using Redis

### Findings & Decisions
- Redis 10x faster than database for rate limit checks
- Refresh tokens stored in httpOnly cookies for XSS protection

### What Doesn't Work
- ❌ Storing tokens in localStorage - vulnerable to XSS
- ❌ Database queries for auth checks - too slow (200ms vs 2ms)
```

**AI agent instructions**: All major AI configs (AGENTS.md, CLAUDE.md, .cursor/rules/001_workspace.mdc) include instructions to use WORKLOG.md

**Documentation**: See `WORKLOG_USAGE.md` for complete guide
3. Keep it updated as your project evolves
4. AI agents read it alongside tool-specific configs

**Relationship to other files**:
- **AGENTS.md** = "How to work on THIS project" (workflow)
- **CONTEXT.md** = "Standards to follow ALWAYS" (rules)
- **Tool configs** = Tool-specific implementations of standards

---

## ✅ Tool-Specific Configurations

### Cursor

**Configuration**: `.cursor/rules/*.mdc`

**Format**: Markdown with frontmatter (`.mdc` format)

**Features**:
- 8 scoped rule files (apply only to relevant file types)
- Numbered priority system (001-008, security is highest)
- Micro-examples showing correct vs incorrect patterns
- Imperative instructions for clear, actionable guidance

**Files**:
```text
.cursor/rules/
├── 001_workspace.mdc           # Repository context
├── 002_design_principles.mdc   # Core design principles
├── 003_bash_standards.mdc      # Shell script standards
├── 004_python_standards.mdc    # Python coding standards
├── 005_yaml_json_standards.mdc # Data format standards
├── 006_security.mdc            # Security requirements (HIGHEST)
├── 007_precommit.mdc           # Pre-commit workflow
└── 008_documentation.mdc       # Documentation requirements
```

**How to use**:
- Cursor automatically discovers and loads `.cursor/rules/*.mdc`
- No manual configuration needed
- Rules are scoped to relevant files automatically

---

### Claude Desktop

**Configuration**: `CLAUDE.md`

**Format**: Conversational markdown

**Features**:
- Comprehensive guidelines in narrative format
- Security checklists for critical requirements
- Example-heavy explanations
- Optimized for Claude's conversational style

**How to use**:

1. Open Claude Desktop
2. Reference `CLAUDE.md` in your messages:

   ```text
   @CLAUDE.md Please review this code
   ```

3. Claude will follow the guidelines automatically

---

### Claude Projects

**Configuration**: `.claudeprompt`

**Format**: Single-line instruction file

**Features**:
- Concise directive pointing to detailed standards
- Optimized for Claude Projects' system prompt
- References CONTEXT.md as source of truth

**How to use**:
1. Create a Claude Project
2. Add `.claudeprompt` content to the project's custom instructions
3. All conversations in that project will follow the standards

---

### GitHub Copilot

**Configuration**: `.github/copilot-instructions.md`

**Format**: Markdown with code examples

**Features**:
- Concise, example-heavy format
- Focus on showing correct patterns
- Optimized for Copilot's context window
- Emphasizes security and quality

**How to use**:
- GitHub Copilot automatically discovers `.github/copilot-instructions.md`
- Applies to all Copilot suggestions in the repository
- No manual configuration needed

---

### Aider

**Configuration**: `.aider/.aider.conf.yml`

**Format**: YAML configuration

**Features**:
- Specifies files to auto-read (CONTEXT.md, CONTRIBUTING.md)
- Environment variable configuration
- Editor and linter integration
- Model selection preferences

**Content**:
```yaml
auto-read:
  - CONTEXT.md
  - CONTRIBUTING.md
  - .cursor/rules/006_security.mdc

editor:
  enabled: true
  command: "code --wait"

git:
  auto-commit: false
  commit-msg-template: "AI: {message}"

linter:
  enabled: true
  command: "pre-commit run --files"
```

**How to use**:
1. Aider automatically loads `.aider/.aider.conf.yml`
2. Specified files are auto-read into context
3. No manual configuration needed

---

### Continue.dev

**Configuration**: `.continue/config.yaml`

**Format**: YAML with rules, prompts, and models

**Features**:
- References external rule files (CONTEXT.md, CONTRIBUTING.md)
- Custom prompts for common tasks (review, test, commit)
- Context providers (diff, file, code, terminal)
- Model configuration (optional, user customizable)

**Custom Commands**:
- `/review` - Review code for security and quality
- `/commit` - Generate a commit message
- `/test` - Generate comprehensive unit tests

**Content Highlights**:
```yaml
name: AI Guardrails Project
version: 1.0.0
schema: v1

rules:
  - uses: file://CONTEXT.md
  - uses: file://CONTRIBUTING.md
  - Critical security rules inline

prompts:
  - name: review
    invokable: true
    prompt: Review for security, quality, and standards

context:
  - provider: diff
  - provider: file
  - provider: code
```

**How to use**:
1. Continue.dev automatically loads `.continue/config.yaml`
2. Invoke custom prompts with `/command-name`
3. Configure your preferred models in the config

---

### Windsurf

**Configuration**:
- `.windsurfignore` - Context exclusions
- `.vscode/settings.json` - Editor settings (Windsurf is VS Code-based)

**Format**:
- `.windsurfignore` - Gitignore-style patterns
- `.vscode/settings.json` - JSON

**Features**:
- Excludes large files and build artifacts from AI context
- Pre-configured formatters and linters
- File exclusions for search and display
- Python, YAML, JSON, Markdown settings

**Content (`.windsurfignore`)**:
```text
# Virtual environments
.venv/
node_modules/

# Build artifacts
dist/
__pycache__/

# Logs
*.log
artifacts/

# Large data files
*.csv
*.db
```

**Content (`.vscode/settings.json` - AI-relevant parts)**:
```json
{
  "continue.telemetryEnabled": false,
  "files.exclude": {
    "**/__pycache__": true,
    "artifacts/": true
  },
  "[python]": {
    "editor.defaultFormatter": "charliermarsh.ruff",
    "editor.formatOnSave": true
  }
}
```

**How to use**:
- Windsurf automatically respects `.windsurfignore`
- Imports VS Code settings on first launch
- No manual configuration needed

---

## ⚠️ Limited Support Tools

### Cody (Sourcegraph)

**Configuration**: Server-side via Sourcegraph Enterprise

**Status**: Enterprise only - requires Sourcegraph instance

**Features**:
- Configured through Sourcegraph site admin
- `modelConfiguration` in Site config
- BYOK (Bring Your Own Key) support
- Default models: Claude 3.5 Sonnet (chat), DeepSeek V2 (autocomplete)

**How to use**:
1. Requires Sourcegraph Enterprise instance
2. Configure via Site admin → Configuration → Site configuration
3. Edit `modelConfiguration` section
4. No local file-based configuration

**For teams with Sourcegraph**:
- Add CONTEXT.md to your Sourcegraph repository
- Reference it in chat: `@CONTEXT.md`
- Cody will use it as context

---

### Tabnine

**Configuration**: UI-based custom commands

**Status**: No file-based configuration available

**Features**:
- Custom commands configured through Tabnine UI
- Click settings cog → "Define custom commands"
- Particularly useful for generating tests

**How to configure**:
1. Open Tabnine
2. Click settings cog in upper right
3. Scroll to "Define custom commands"
4. Click "Add"
5. Enter prompt template
6. Save

**Recommended custom command**:
```text
Generate comprehensive unit tests following the standards in CONTEXT.md.
Include edge cases, error handling, and docstrings.
```

---

### Amazon Q Developer

**Configuration**: Server-side via Amazon Q Pro

**Status**: Pro tier only - requires AWS account and Q Pro subscription

**Features**:
- Customizations through Amazon Q Developer Pro
- Can upload custom files with `/learn` command in chat
- Tailored code suggestions based on your codebase
- Code transformation and security scanning

**How to use**:
1. Requires Amazon Q Developer Pro subscription
2. Configure customizations through AWS console
3. In chat, use `/learn` command to reference custom files:
   ```text
   /learn CONTEXT.md
   Please review this code
   ```

---

## 🔄 Configuration Maintenance

### Single Source of Truth

**`CONTEXT.md`** is the canonical standards document. All tool-specific configs are derived from it.

**Update workflow**:
1. Edit `CONTEXT.md` (canonical source)
2. Update tool-specific files to match
3. Test with each AI tool you use
4. Commit all changes together

### Adding New Standards

When adding a new standard:

1. Add to `CONTEXT.md` first
2. Update all tool configs that apply
3. Add examples to tool-specific formats
4. Update this documentation

### Testing Configurations

**Cursor**:
```bash
# Verify rules are loaded
# Check Cursor → Settings → Rules
```

**Claude**:
```text
# In Claude Desktop
@CLAUDE.md Can you summarize the security requirements?
```

**Continue.dev**:
```bash
# In VS Code with Continue
# Type / to see available commands
# Try /review on a file
```

**Pre-commit**:
```bash
# Test that all checks pass
pre-commit run --all-files
```

---

## 📊 Configuration Comparison

| Feature | Cursor | Claude | Copilot | Aider | Continue.dev | Windsurf |
|---------|--------|--------|---------|-------|--------------|----------|
| **Auto-discovery** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **File scoping** | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Custom prompts** | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| **Context exclusions** | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| **External file references** | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ |
| **Priority system** | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Examples in config** | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ |

---

## 🎯 Best Practices

### For New Projects

**Copy everything**:
```bash
# Get all AI configurations
cp -r /path/to/guardrails-ai/.cursor .
cp /path/to/guardrails-ai/CLAUDE.md .
cp /path/to/guardrails-ai/.claudeprompt .
cp -r /path/to/guardrails-ai/.continue .
cp /path/to/guardrails-ai/.windsurfignore .
cp -r /path/to/guardrails-ai/.vscode .
cp /path/to/guardrails-ai/.github/copilot-instructions.md .github/
cp -r /path/to/guardrails-ai/.aider .
cp /path/to/guardrails-ai/CONTEXT.md .
cp /path/to/guardrails-ai/CONTRIBUTING.md .
```

### For Existing Projects

**Start with your primary tool**:
1. Copy config for your main AI tool (e.g., Cursor)
2. Copy `CONTEXT.md` and `CONTRIBUTING.md` (universal)
3. Add configs for other tools as needed

### For Teams

**Standardize on primary tool**:
1. Choose 1-2 primary AI tools for the team
2. Configure those thoroughly
3. Add optional configs for other tools team members might use
4. Keep `CONTEXT.md` as the authoritative source

---

## 🔧 Troubleshooting

### AI not following standards

1. **Verify config file exists**:
   ```bash
   ls -la .cursor/rules/
   ls -la CLAUDE.md
   ls -la .continue/config.yaml
   ```

2. **Check AI tool is reading the config**:
   - Cursor: Settings → Rules (should show loaded rules)
   - Claude: Test with `@CLAUDE.md what are the security rules?`
   - Continue.dev: Type `/` to see custom commands

3. **Verify CONTEXT.md is accessible**:
   ```bash
   cat CONTEXT.md | head -20
   ```

### Configuration conflicts

**If multiple configs conflict**:

1. Check `CONTEXT.md` for the authoritative standard
2. Update all tool-specific configs to match
3. Security rules always take highest priority

### Tool-specific issues

**Cursor not loading rules**:

- Ensure files use `.mdc` extension
- Check filenames are numbered correctly (001-008)
- Restart Cursor

**Continue.dev commands not working**:

- Verify `.continue/config.yaml` has correct YAML syntax
- Check file paths in `uses:` fields are correct
- Restart VS Code

**Claude not following CLAUDE.md**:

- Make sure you reference it with `@CLAUDE.md`
- Check the file is in the project directory
- Try pasting key sections directly into the chat

---

## 📚 Related Documentation

- **`CONTEXT.md`** - Canonical standards document
- **`CONTRIBUTING.md`** - Contribution guidelines
- **`template/USAGE.md`** - Detailed usage guide
- **`README.md`** - Overview and quick start

---

**Questions?** Open an issue on GitHub or check the documentation!
