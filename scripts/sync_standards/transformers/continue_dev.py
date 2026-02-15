"""
Continue.dev Transformer

Transforms rules into Continue.dev YAML format.
"""

from typing import Dict, List

from ..parser import Rule
from .base import BaseTransformer


class ContinueTransformer(BaseTransformer):
    """Transform rules to Continue.dev YAML format."""

    TEMPLATE_NAME = "continue.yaml.j2"
    OUTPUT_FILE = ".continue/config.yaml"

    def transform(self, rules: List[Rule]) -> Dict[str, str]:
        """Transform rules into Continue.dev config."""
        parts = [self._build_header()]

        parts.append("rules:")

        # Generate YAML entries for each rule
        for rule in rules:
            rule_content = self._render_template(self.TEMPLATE_NAME, rule=rule)
            # Add list item prefix and indent
            lines = rule_content.split("\n")
            if lines:
                # First line gets "- " prefix and 0 indent
                indented_lines = [f"  - {lines[0]}"]
                # Rest get 4-space indent (2 for list level + 2 for continuation)
                for line in lines[1:]:
                    if line.strip():
                        indented_lines.append(f"    {line}")
                    else:
                        indented_lines.append("")
                parts.append("\n".join(indented_lines))

        content = "\n".join(parts)
        return {self.OUTPUT_FILE: content}

    def _build_header(self) -> str:
        """Build file header."""
        return """# Continue.dev Configuration
# AUTO-GENERATED from CONTEXT.md

# This file contains coding standards and rules derived from CONTEXT.md
"""
