"""
Aider Transformer

Transforms rules into Aider YAML comments format.
"""

from typing import Dict, List

from ..parser import Rule
from .base import BaseTransformer


class AiderTransformer(BaseTransformer):
    """Transform rules to Aider YAML format."""

    TEMPLATE_NAME = "aider.yml.j2"
    OUTPUT_FILE = ".aider/.aider.conf.yml"

    def transform(self, rules: List[Rule]) -> Dict[str, str]:
        """Transform rules into Aider config."""
        parts = [self._build_header()]

        # Aider uses comments in YAML, so we'll append rules as comments
        parts.append("\n# === Standards from CONTEXT.md ===\n")

        for rule in rules:
            rule_content = self._render_template(self.TEMPLATE_NAME, rule=rule)
            parts.append(rule_content)

        content = "\n".join(parts)
        return {self.OUTPUT_FILE: content}

    def _build_header(self) -> str:
        """Build file header."""
        return """# Aider Configuration
# AUTO-GENERATED from CONTEXT.md

# Aider reads CONTEXT.md directly, but key standards are summarized here as comments
"""
