#!/usr/bin/env python3
"""
Standards Synchronization - Proof of Concept

Demonstrates parsing CONTEXT.md and transforming to tool-specific formats
with preprocessing and optimization.

Usage:
    python3 scripts/sync-standards-poc.py [--dry-run]

Requirements:
    pip install pyyaml markdown
"""

import sys
from pathlib import Path
from typing import Dict, List
from dataclasses import dataclass


@dataclass
class Rule:
    """Represents a rule extracted from CONTEXT.md."""

    section: str
    title: str
    content: str
    examples_correct: List[str]
    examples_incorrect: List[str]
    priority: int
    scope: List[str]  # ['all'] or ['*.py', '*.sh']


class ContextParser:
    """Parse CONTEXT.md into structured rules."""

    def parse(self, context_md: str) -> List[Rule]:
        """Extract rules from CONTEXT.md."""
        rules = []

        # Simple example: extract security rules
        # In production, this would be more sophisticated

        if "Never Commit Secrets" in context_md:
            rules.append(
                Rule(
                    section="Security",
                    title="Never Commit Secrets",
                    content="AI agents must NEVER commit secrets, API keys, tokens, or credentials to git.",
                    examples_correct=["import os\napi_key = os.environ.get('API_KEY')"],
                    examples_incorrect=["api_key = 'sk-1234567890abcdef'  # WRONG!"],
                    priority=100,
                    scope=["all"],
                )
            )

        if "set -euo pipefail" in context_md:
            rules.append(
                Rule(
                    section="Bash Standards",
                    title="Use Safe Bash Options",
                    content="All bash scripts must start with set -euo pipefail for safety.",
                    examples_correct=["#!/usr/bin/env bash\nset -euo pipefail"],
                    examples_incorrect=["#!/bin/bash\n# Missing safety options"],
                    priority=50,
                    scope=["*.sh"],
                )
            )

        return rules


class BaseTransformer:
    """Base class for tool-specific transformers."""

    def transform(self, rules: List[Rule]) -> str:
        """Transform rules to tool-specific format."""
        raise NotImplementedError


class CursorTransformer(BaseTransformer):
    """Transform rules to Cursor .mdc format."""

    def transform(self, rules: List[Rule]) -> Dict[str, str]:
        """Generate Cursor .mdc files."""
        files = {}

        for rule in rules:
            # Map sections to cursor files
            file_map = {
                "Security": ".cursor/rules/006_security.mdc",
                "Bash Standards": ".cursor/rules/003_bash_standards.mdc",
            }

            if rule.section not in file_map:
                continue

            filename = file_map[rule.section]

            # Build .mdc content (imperative style)
            content = self._build_mdc_content(rule)

            if filename in files:
                files[filename] += "\n\n" + content
            else:
                # Add frontmatter
                files[filename] = self._build_frontmatter(rule) + "\n\n" + content

        return files

    def _build_frontmatter(self, rule: Rule) -> str:
        """Build .mdc frontmatter."""
        globs = rule.scope if rule.scope != ["all"] else ["**/*"]
        return f"""---
priority: {rule.priority}
globs:
  - "{globs[0]}"
---"""

    def _build_mdc_content(self, rule: Rule) -> str:
        """Build .mdc rule content (imperative style)."""
        lines = []

        # Title (use ##)
        lines.append(f"## {rule.title}")
        lines.append("")

        # Content (make imperative)
        imperative_content = self._make_imperative(rule.content)
        lines.append(imperative_content)
        lines.append("")

        # Examples
        if rule.examples_correct:
            lines.append("✅ **CORRECT:**")
            lines.append("")
            lines.append("```bash" if "*.sh" in rule.scope else "```python")
            lines.append(rule.examples_correct[0])
            lines.append("```")
            lines.append("")

        if rule.examples_incorrect:
            lines.append("❌ **WRONG:**")
            lines.append("")
            lines.append("```bash" if "*.sh" in rule.scope else "```python")
            lines.append(rule.examples_incorrect[0])
            lines.append("```")

        return "\n".join(lines)

    def _make_imperative(self, text: str) -> str:
        """Convert to imperative voice."""
        # Simple transformations (production would be more sophisticated)
        text = text.replace("must", "MUST")
        text = text.replace("should", "MUST")
        text = text.replace("never", "NEVER")
        return text


class ClaudeTransformer(BaseTransformer):
    """Transform rules to Claude conversational markdown."""

    def transform(self, rules: List[Rule]) -> Dict[str, str]:
        """Generate Claude.md content."""
        files = {"CLAUDE.md": self._build_header()}

        for rule in rules:
            content = self._build_claude_content(rule)
            files["CLAUDE.md"] += "\n\n" + content

        return files

    def _build_header(self) -> str:
        """Build Claude.md header."""
        return """# Claude AI Instructions for Engineering Projects

You are Claude, an AI assistant working on a software engineering project.
Follow these guardrails carefully."""

    def _build_claude_content(self, rule: Rule) -> str:
        """Build conversational Claude content."""
        lines = []

        # Section header
        lines.append(f"### {rule.title}")
        lines.append("")

        # Content (conversational style)
        conversational = self._make_conversational(rule.content)
        lines.append(conversational)
        lines.append("")

        # Add "why this matters"
        lines.append("**Why this matters:**")
        lines.append(self._generate_reasoning(rule))
        lines.append("")

        # Examples with explanation
        if rule.examples_correct:
            lines.append("✅ **Do this:**")
            lines.append("")
            lines.append("```python")
            lines.append(rule.examples_correct[0])
            lines.append("```")
            lines.append("")
            lines.append(self._explain_example(rule.examples_correct[0], correct=True))
            lines.append("")

        if rule.examples_incorrect:
            lines.append("❌ **Don't do this:**")
            lines.append("")
            lines.append("```python")
            lines.append(rule.examples_incorrect[0])
            lines.append("```")
            lines.append("")
            lines.append(
                self._explain_example(rule.examples_incorrect[0], correct=False)
            )

        return "\n".join(lines)

    def _make_conversational(self, text: str) -> str:
        """Convert to conversational style."""
        # Add "you" voice
        if not text.startswith("You"):
            text = "You " + text.lower()
        return text

    def _generate_reasoning(self, rule: Rule) -> str:
        """Generate 'why this matters' explanation."""
        reasoning_map = {
            "Never Commit Secrets": "Committed secrets can be exploited by attackers and are nearly impossible to fully remove from git history.",
            "Use Safe Bash Options": "These options prevent silent failures and make scripts more reliable and debuggable.",
        }
        return reasoning_map.get(rule.title, "This ensures code quality and security.")

    def _explain_example(self, example: str, correct: bool) -> str:
        """Explain why example is correct or incorrect."""
        if correct:
            return "This approach loads credentials from environment variables, keeping them out of your code."
        else:
            return "This hardcodes credentials directly in the code, which will be committed to git."


class CopilotTransformer(BaseTransformer):
    """Transform rules to GitHub Copilot concise format."""

    def transform(self, rules: List[Rule]) -> Dict[str, str]:
        """Generate GitHub Copilot instructions."""
        content = ["# GitHub Copilot Instructions", ""]

        for rule in rules:
            content.extend(self._build_copilot_content(rule))
            content.append("")

        return {".github/copilot-instructions.md": "\n".join(content)}

    def _build_copilot_content(self, rule: Rule) -> List[str]:
        """Build concise Copilot content."""
        lines = []

        # Title
        lines.append(f"## {rule.title}")
        lines.append("")

        # One-line summary
        lines.append(self._summarize(rule.content))
        lines.append("")

        # Before/after comparison
        if rule.examples_incorrect and rule.examples_correct:
            lines.append("```python")
            lines.append("# ❌ Bad")
            lines.append(rule.examples_incorrect[0])
            lines.append("")
            lines.append("# ✅ Good")
            lines.append(rule.examples_correct[0])
            lines.append("```")

        return lines

    def _summarize(self, text: str) -> str:
        """Create one-line summary."""
        # Extract first sentence
        first_sentence = text.split(".")[0] + "."
        return first_sentence


def main():
    """Main sync script."""
    dry_run = "--dry-run" in sys.argv

    print("🔄 Standards Synchronization Proof of Concept\n")

    # 1. Parse CONTEXT.md
    print("📖 Parsing CONTEXT.md...")
    context_path = Path("CONTEXT.md")
    if not context_path.exists():
        print("❌ CONTEXT.md not found")
        return 1

    context_md = context_path.read_text()
    parser = ContextParser()
    rules = parser.parse(context_md)
    print(f"   Found {len(rules)} rules\n")

    # 2. Transform for each tool
    transformers = {
        "Cursor": CursorTransformer(),
        "Claude": ClaudeTransformer(),
        "GitHub Copilot": CopilotTransformer(),
    }

    all_files = {}

    for tool_name, transformer in transformers.items():
        print(f"🔧 Transforming for {tool_name}...")
        files = transformer.transform(rules)
        all_files.update(files)
        print(f"   Generated {len(files)} file(s)")

    print()

    # 3. Write or display files
    if dry_run:
        print("🔍 DRY RUN - Would generate:\n")
        for filename, content in all_files.items():
            print(f"📄 {filename}")
            print(f"   {len(content.splitlines())} lines")
            print("   Preview:")
            print("   " + "\n   ".join(content.splitlines()[:5]))
            if len(content.splitlines()) > 5:
                print(f"   ... ({len(content.splitlines()) - 5} more lines)")
            print()
    else:
        print("💾 Writing files...\n")
        for filename, content in all_files.items():
            filepath = Path(filename)
            filepath.parent.mkdir(parents=True, exist_ok=True)

            # In production, would merge with existing content
            print(f"   Writing {filename}")
            # filepath.write_text(content)  # Uncomment to actually write

        print("\n✅ Sync complete!")
        print("\nNext steps:")
        print("1. Review changes: git diff")
        print("2. Test with AI tools")
        print("3. Run pre-commit: pre-commit run --all-files")
        print("4. Commit: git commit -am 'Sync standards'")

    return 0


if __name__ == "__main__":
    sys.exit(main())
