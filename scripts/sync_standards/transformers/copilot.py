"""
GitHub Copilot Transformer

Transforms rules into concise GitHub Copilot format.
"""

from typing import Dict, List

from ..parser import Rule
from .base import BaseTransformer


class CopilotTransformer(BaseTransformer):
    """Transform rules to GitHub Copilot concise format."""

    TEMPLATE_NAME = "copilot.md.j2"
    OUTPUT_FILE = ".github/copilot-instructions.md"

    def transform(self, rules: List[Rule]) -> Dict[str, str]:
        """Transform rules into GitHub Copilot instructions."""
        parts = [self._build_header().rstrip()]

        # Group by section
        sections = {}
        for rule in rules:
            if rule.section not in sections:
                sections[rule.section] = []
            sections[rule.section].append(rule)

        # Generate concise content
        for section_name, section_rules in sections.items():
            parts.append(f"# {section_name}")

            for rule in section_rules:
                rule_content = self._render_template(
                    self.TEMPLATE_NAME, rule=rule
                ).strip()
                parts.append(rule_content)

        # Join with exactly one blank line
        content = "\n\n".join(parts) + "\n"
        return {self.OUTPUT_FILE: content}

    def _build_header(self) -> str:
        """Build file header."""
        return """# GitHub Copilot Instructions

**AUTO-GENERATED** from CONTEXT.md - Do not edit manually.

Quick reference guide for GitHub Copilot code generation.
"""
