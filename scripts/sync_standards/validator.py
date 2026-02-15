"""
Validator

Validates generated configuration files for syntax correctness and consistency.
"""

import yaml
import re
from typing import Dict, List
from pathlib import Path


class ValidationError(Exception):
    """Raised when validation fails."""

    pass


class Validator:
    """Validate generated configuration files."""

    def __init__(self):
        """Initialize validator."""
        self.errors: List[str] = []
        self.warnings: List[str] = []

    def validate_all(self, files: Dict[str, str]) -> bool:
        """Validate all generated files.

        Args:
            files: Dict mapping file paths to content

        Returns:
            True if all validation passes, False otherwise
        """
        self.errors = []
        self.warnings = []

        for filepath, content in files.items():
            self._validate_file(filepath, content)

        return len(self.errors) == 0

    def _validate_file(self, filepath: str, content: str):
        """Validate a single file."""
        path = Path(filepath)

        # Validate based on file type
        if path.suffix == ".yaml" or path.suffix == ".yml":
            self._validate_yaml(filepath, content)
        elif path.suffix == ".mdc":
            self._validate_mdc(filepath, content)
        elif path.suffix == ".md":
            self._validate_markdown(filepath, content)

        # Common validations
        self._validate_common(filepath, content)

    def _validate_yaml(self, filepath: str, content: str):
        """Validate YAML syntax."""
        try:
            yaml.safe_load(content)
        except yaml.YAMLError as e:
            self.errors.append(f"{filepath}: Invalid YAML syntax: {e}")

    def _validate_mdc(self, filepath: str, content: str):
        """Validate .mdc file (YAML frontmatter + Markdown)."""
        # Check for frontmatter
        if not content.startswith("---"):
            self.errors.append(f"{filepath}: Missing YAML frontmatter")
            return

        # Split frontmatter and content
        parts = content.split("---", 2)
        if len(parts) < 3:
            self.errors.append(f"{filepath}: Invalid frontmatter structure")
            return

        frontmatter = parts[1]
        markdown_content = parts[2]

        # Validate frontmatter YAML
        try:
            metadata = yaml.safe_load(frontmatter)
            # Check required fields
            if "priority" not in metadata:
                self.warnings.append(f"{filepath}: Missing 'priority' in frontmatter")
            if "globs" not in metadata:
                self.warnings.append(f"{filepath}: Missing 'globs' in frontmatter")
        except yaml.YAMLError as e:
            self.errors.append(f"{filepath}: Invalid frontmatter YAML: {e}")

        # Validate markdown content
        self._validate_markdown(filepath, markdown_content)

    def _validate_markdown(self, filepath: str, content: str):
        """Validate Markdown syntax."""
        # Check for unclosed code fences
        fence_pattern = r"```"
        fences = re.findall(fence_pattern, content)
        if len(fences) % 2 != 0:
            self.errors.append(f"{filepath}: Unclosed code fence")

        # Check for proper heading hierarchy
        headings = re.findall(r"^(#{1,6})\s+", content, re.MULTILINE)
        if headings:
            levels = [len(h) for h in headings]
            for i in range(1, len(levels)):
                if levels[i] > levels[i - 1] + 1:
                    self.warnings.append(
                        f"{filepath}: Heading hierarchy skip (#{levels[i-1]} -> #{levels[i]})"
                    )

    def _validate_common(self, filepath: str, content: str):
        """Common validations for all files."""
        # Check for trailing whitespace
        lines = content.split("\n")
        for i, line in enumerate(lines, 1):
            if line.endswith(" ") or line.endswith("\t"):
                self.warnings.append(f"{filepath}:{i}: Trailing whitespace")

        # Check file ends with newline
        if content and not content.endswith("\n"):
            self.warnings.append(f"{filepath}: Missing final newline")

        # Check for very long lines (>120 chars, excluding code blocks)
        in_code_block = False
        for i, line in enumerate(lines, 1):
            if line.strip().startswith("```"):
                in_code_block = not in_code_block
                continue

            if not in_code_block and len(line) > 120:
                self.warnings.append(
                    f"{filepath}:{i}: Line too long ({len(line)} chars)"
                )

    def print_results(self):
        """Print validation results."""
        if self.errors:
            print("\n❌ Validation Errors:")
            for error in self.errors:
                print(f"  - {error}")

        if self.warnings:
            print("\n⚠️  Validation Warnings:")
            for warning in self.warnings:
                print(f"  - {warning}")

        if not self.errors and not self.warnings:
            print("\n✅ All validations passed!")
