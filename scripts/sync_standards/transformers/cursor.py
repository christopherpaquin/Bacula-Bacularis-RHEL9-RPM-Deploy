"""
Cursor Transformer

Transforms rules into Cursor .mdc format with imperative style.
"""

from typing import Dict, List
from collections import defaultdict

from ..parser import Rule
from .base import BaseTransformer


class CursorTransformer(BaseTransformer):
    """Transform rules to Cursor .mdc files."""

    TEMPLATE_NAME = "cursor.mdc.j2"

    # Map sections to cursor rule files
    FILE_MAPPING = {
        "Design Principles": ".cursor/rules/001_workspace.mdc",
        "Bash Standards": ".cursor/rules/003_bash_standards.mdc",
        "Python Standards": ".cursor/rules/004_python_standards.mdc",
        "YAML": ".cursor/rules/005_config_standards.mdc",
        "JSON": ".cursor/rules/005_config_standards.mdc",
        "Security": ".cursor/rules/006_security.mdc",
        "Pre-commit": ".cursor/rules/007_precommit.mdc",
        "Documentation": ".cursor/rules/008_documentation.mdc",
    }

    def transform(self, rules: List[Rule]) -> Dict[str, str]:
        """Transform rules into Cursor .mdc files."""
        # Group rules by output file
        files_rules = defaultdict(list)

        for rule in rules:
            # Determine which file this rule belongs to
            output_file = self._get_output_file(rule)
            if output_file:
                files_rules[output_file].append(rule)

        # Generate file content
        output_files = {}
        for filepath, file_rules in files_rules.items():
            content = self._generate_file_content(file_rules)
            output_files[filepath] = content

        return output_files

    def _get_output_file(self, rule: Rule) -> str:
        """Determine output file for a rule."""
        # Check direct section mapping
        for section_key, filepath in self.FILE_MAPPING.items():
            if section_key.lower() in rule.section.lower():
                return filepath

        # Check by tags
        if "security" in rule.tags:
            return ".cursor/rules/006_security.mdc"
        if "bash" in rule.tags:
            return ".cursor/rules/003_bash_standards.mdc"
        if "python" in rule.tags:
            return ".cursor/rules/004_python_standards.mdc"

        # Default to workspace rules
        return ".cursor/rules/001_workspace.mdc"

    def _generate_file_content(self, rules: List[Rule]) -> str:
        """Generate content for a single .mdc file."""
        parts = []

        for rule in rules:
            # Render this rule using template
            rule_content = self._render_template(self.TEMPLATE_NAME, rule=rule)
            parts.append(rule_content)

        return "\n\n---\n\n".join(parts)
