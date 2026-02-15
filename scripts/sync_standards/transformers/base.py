"""
Base Transformer

Provides common functionality for all tool-specific transformers.
"""

import re
from pathlib import Path
from typing import Dict, List
from jinja2 import Environment, FileSystemLoader, select_autoescape

from ..parser import Rule


class BaseTransformer:
    """Base class for all tool-specific transformers."""

    # Subclasses override these
    TEMPLATE_NAME: str = ""
    OUTPUT_FILES: Dict[str, List[str]] = {}  # section -> file mapping

    def __init__(self, templates_dir: Path):
        """Initialize transformer with Jinja2 environment."""
        self.env = Environment(
            loader=FileSystemLoader(templates_dir),
            autoescape=select_autoescape(),
            trim_blocks=True,
            lstrip_blocks=True,
        )

        # Register custom filters
        self._register_filters()

    def _register_filters(self):
        """Register Jinja2 custom filters."""
        self.env.filters["make_imperative"] = self._make_imperative
        self.env.filters["make_conversational"] = self._make_conversational
        self.env.filters["summarize"] = self._summarize
        self.env.filters["comment_wrap"] = self._comment_wrap
        self.env.filters["generate_reasoning"] = self._generate_reasoning
        self.env.filters["explain_correct"] = self._explain_correct
        self.env.filters["explain_incorrect"] = self._explain_incorrect

    def transform(self, rules: List[Rule]) -> Dict[str, str]:
        """Transform rules into tool-specific format.

        Args:
            rules: List of parsed rules

        Returns:
            Dict mapping output file paths to their content
        """
        raise NotImplementedError("Subclasses must implement transform()")

    def _render_template(self, template_name: str, **context) -> str:
        """Render a Jinja2 template with context."""
        template = self.env.get_template(template_name)
        return template.render(**context)

    # ===== Text Transformation Filters =====

    def _make_imperative(self, text: str) -> str:
        """Convert text to imperative voice for Cursor."""
        # Replace modal verbs with stronger commands
        replacements = {
            r"\bmust\b": "MUST",
            r"\bshould\b": "MUST",
            r"\bmay\b": "CAN",
            r"\bnever\b": "NEVER",
            r"\balways\b": "ALWAYS",
            r"\brequire\b": "REQUIRE",
            r"\bdo not\b": "DO NOT",
            r"\bdon't\b": "DO NOT",
        }

        for pattern, replacement in replacements.items():
            text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)

        return text

    def _make_conversational(self, text: str) -> str:
        """Convert text to conversational voice for Claude."""
        # Add "you" voice if not present
        text = text.strip()

        # Convert imperatives to "you" statements
        conversational_starters = ["you must", "you should", "you need to"]
        if not any(
            text.lower().startswith(starter) for starter in conversational_starters
        ):
            # Add conversational prefix
            if text.startswith(("MUST", "Must", "NEVER", "Never", "ALWAYS", "Always")):
                text = "You " + text.lower()
            elif not text.lower().startswith("you"):
                text = "You should " + text.lower()

        return text

    def _summarize(self, text: str) -> str:
        """Create one-line summary for Copilot."""
        # Take first sentence
        sentences = re.split(r"[.!?]\s+", text.strip())
        if sentences:
            summary = sentences[0]
            if not summary.endswith("."):
                summary += "."
            return summary
        return text

    def _comment_wrap(self, text: str, prefix: str = "# ") -> str:
        """Wrap text as comments for YAML files."""
        lines = text.split("\n")
        return "\n".join(
            f"{prefix}{line}" if line.strip() else prefix.strip() for line in lines
        )

    def _generate_reasoning(self, rule: Rule) -> str:
        """Generate 'why this matters' explanation."""
        reasoning_map = {
            "security": "This prevents security vulnerabilities and protects sensitive data.",
            "bash": "This ensures scripts are reliable, safe, and handle errors properly.",
            "python": "This improves code quality, maintainability, and catches errors early.",
            "secret": "Committed secrets can be exploited and are nearly impossible to remove from git history.",
            "credential": "Hardcoded credentials are a critical security risk.",
        }

        # Match based on tags
        for tag in rule.tags:
            if tag in reasoning_map:
                return reasoning_map[tag]

        # Match based on content keywords
        content_lower = rule.content.lower()
        for keyword, reasoning in reasoning_map.items():
            if keyword in content_lower:
                return reasoning

        return "This ensures code quality, security, and maintainability."

    def _explain_correct(self, rule: Rule) -> str:
        """Explain why correct example is correct."""
        explanations = {
            "security": "follows security best practices and protects sensitive data",
            "bash": "uses safe shell options and proper error handling",
            "python": "follows Python best practices with proper types and error handling",
            "environment": "loads configuration from environment variables",
            "validation": "validates input before processing",
        }

        content_lower = rule.content.lower()
        for keyword, explanation in explanations.items():
            if keyword in content_lower:
                return explanation

        return "follows best practices and avoids common pitfalls"

    def _explain_incorrect(self, rule: Rule) -> str:
        """Explain why incorrect example is incorrect."""
        explanations = {
            "security": "exposes sensitive data or creates security vulnerabilities",
            "bash": "can fail silently or behave unpredictably",
            "python": "lacks proper type safety and error handling",
            "hardcode": "hardcodes values that should be configurable",
            "secret": "commits secrets directly to the codebase",
        }

        content_lower = rule.content.lower()
        for keyword, explanation in explanations.items():
            if keyword in content_lower:
                return explanation

        return "violates best practices and can lead to issues"
