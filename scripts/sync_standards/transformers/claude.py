"""
Claude Transformer

Transforms rules into Claude conversational markdown format.
"""

from typing import Dict, List

from ..parser import Rule
from .base import BaseTransformer


class ClaudeTransformer(BaseTransformer):
    """Transform rules to Claude conversational format."""

    TEMPLATE_NAME = "claude.md.j2"
    OUTPUT_FILE = "CLAUDE.md"

    def transform(self, rules: List[Rule]) -> Dict[str, str]:
        """Transform rules into CLAUDE.md."""
        # Build header
        parts = [self._build_header().rstrip()]

        # Group rules by section
        sections = {}
        for rule in rules:
            if rule.section not in sections:
                sections[rule.section] = []
            sections[rule.section].append(rule)

        # Generate content for each section
        for section_name, section_rules in sections.items():
            parts.append(f"## {section_name}")

            for rule in section_rules:
                rule_content = self._render_template(
                    self.TEMPLATE_NAME, rule=rule
                ).strip()
                parts.append(rule_content)

        # Join with exactly one blank line between parts
        content = "\n\n".join(parts) + "\n"
        return {self.OUTPUT_FILE: content}

    def _build_header(self) -> str:
        """Build file header."""
        return """# Claude AI Instructions for Engineering Projects

You are Claude, an AI assistant working on a software engineering project that follows
strict quality and security standards. This document defines your operational guardrails.

**IMPORTANT:** This document is automatically generated from CONTEXT.md.
Any manual edits will be overwritten. To update, modify CONTEXT.md and run the sync script.

---

## 🎯 Your Role

You are working within a **governed framework** where:

- **Documentation is authoritative** - Follow all standards defined here
- **Security is paramount** - Never commit secrets or credentials
- **Quality is enforced** - All changes must pass pre-commit checks
- **Explicitness is required** - No implicit assumptions

---
"""
