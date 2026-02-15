"""
CONTEXT.md Parser

Extracts structured rules from CONTEXT.md for transformation into
tool-specific configurations.
"""

import re
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple
from pathlib import Path


@dataclass
class CodeExample:
    """Represents a code example (correct or incorrect)."""

    code: str
    language: str
    is_correct: bool  # True = correct example, False = incorrect
    explanation: Optional[str] = None


@dataclass
class Rule:
    """Represents a rule extracted from CONTEXT.md."""

    section: str  # e.g., "Bash Standards", "Python Standards"
    subsection: Optional[str]  # e.g., "3.1 File Naming"
    title: str  # e.g., "Never Commit Secrets"
    content: str  # Main rule content
    examples: List[CodeExample] = field(default_factory=list)
    priority: int = 50  # 0-100, higher = more important
    scope: List[str] = field(default_factory=lambda: ["all"])  # File globs
    tags: List[str] = field(default_factory=list)  # e.g., ["security", "bash"]


class ContextParser:
    """Parse CONTEXT.md into structured rules."""

    # Section priorities (higher = more important)
    SECTION_PRIORITIES = {
        "Security": 100,
        "Pre-commit": 90,
        "Bash Standards": 70,
        "Python Standards": 70,
        "Design Principles": 60,
        "YAML": 50,
        "JSON": 50,
        "Documentation": 40,
    }

    # Section to file scope mapping
    SECTION_SCOPES = {
        "Bash Standards": ["*.sh", "*.bash"],
        "Python Standards": ["*.py"],
        "YAML": ["*.yaml"],
        "JSON": ["*.json"],
    }

    def __init__(self, context_path: Path):
        """Initialize parser with path to CONTEXT.md."""
        self.context_path = context_path
        self.content = self._read_file()

    def _read_file(self) -> str:
        """Read CONTEXT.md file."""
        if not self.context_path.exists():
            raise FileNotFoundError(f"CONTEXT.md not found at {self.context_path}")
        return self.context_path.read_text(encoding="utf-8")

    def parse(self) -> List[Rule]:
        """Parse CONTEXT.md and extract all rules."""
        rules = []

        # Split into major sections (## headers)
        sections = self._split_into_sections()

        for section_title, section_content in sections.items():
            # Extract rules from this section
            section_rules = self._parse_section(section_title, section_content)
            rules.extend(section_rules)

        return rules

    def _split_into_sections(self) -> Dict[str, str]:
        """Split document into major sections by ## headers."""
        sections = {}
        current_section = None
        current_content = []

        for line in self.content.split("\n"):
            # Detect ## headers (major sections)
            if line.startswith("## "):
                # Save previous section
                if current_section:
                    sections[current_section] = "\n".join(current_content)

                # Start new section
                current_section = line[3:].strip()
                # Remove section numbers (e.g., "3. Bash Standards" -> "Bash Standards")
                current_section = re.sub(r"^\d+\.\s*", "", current_section)
                current_content = []
            elif current_section:
                current_content.append(line)

        # Save last section
        if current_section:
            sections[current_section] = "\n".join(current_content)

        return sections

    def _parse_section(self, section_title: str, section_content: str) -> List[Rule]:
        """Parse a section into individual rules."""
        rules = []

        # Determine priority and scope
        priority = self._get_priority(section_title)
        scope = self._get_scope(section_title)
        tags = self._get_tags(section_title)

        # Split into subsections (### headers)
        subsections = self._split_into_subsections(section_content)

        if subsections:
            # Section has subsections - create rule for each
            for subsection_title, subsection_content in subsections.items():
                rule = self._create_rule(
                    section=section_title,
                    subsection=subsection_title,
                    content=subsection_content,
                    priority=priority,
                    scope=scope,
                    tags=tags,
                )
                if rule:
                    rules.append(rule)
        else:
            # No subsections - entire section is one rule
            rule = self._create_rule(
                section=section_title,
                subsection=None,
                content=section_content,
                priority=priority,
                scope=scope,
                tags=tags,
            )
            if rule:
                rules.append(rule)

        return rules

    def _split_into_subsections(self, content: str) -> Dict[str, str]:
        """Split content into subsections by ### headers."""
        subsections = {}
        current_subsection = None
        current_content = []

        for line in content.split("\n"):
            # Detect ### headers (subsections)
            if line.startswith("### "):
                # Save previous subsection
                if current_subsection:
                    subsections[current_subsection] = "\n".join(current_content)

                # Start new subsection
                current_subsection = line[4:].strip()
                # Remove subsection numbers (e.g., "3.1 Naming" -> "Naming")
                current_subsection = re.sub(r"^\d+\.\d+\s*", "", current_subsection)
                current_content = []
            elif current_subsection:
                current_content.append(line)

        # Save last subsection
        if current_subsection:
            subsections[current_subsection] = "\n".join(current_content)

        return subsections

    def _create_rule(
        self,
        section: str,
        subsection: Optional[str],
        content: str,
        priority: int,
        scope: List[str],
        tags: List[str],
    ) -> Optional[Rule]:
        """Create a Rule object from parsed content."""
        # Extract text content (remove code blocks for now)
        text_content, examples = self._extract_content_and_examples(content)

        # Skip if no meaningful content
        if not text_content.strip():
            return None

        # Use subsection as title if available, otherwise use first sentence
        title = subsection if subsection else self._extract_title(text_content)

        return Rule(
            section=section,
            subsection=subsection,
            title=title,
            content=text_content.strip(),
            examples=examples,
            priority=priority,
            scope=scope,
            tags=tags,
        )

    def _extract_content_and_examples(
        self, content: str
    ) -> Tuple[str, List[CodeExample]]:
        """Extract text content and code examples separately."""
        text_parts = []
        examples = []

        # Split by code fences
        parts = re.split(r"```(\w+)?\n(.*?)```", content, flags=re.DOTALL)

        for i, part in enumerate(parts):
            if i % 3 == 0:
                # Text content
                text_parts.append(part)
            elif i % 3 == 2:
                # Code block (language in parts[i-1], code in parts[i])
                language = parts[i - 1] if parts[i - 1] else "text"
                code = part.strip()

                # Determine if correct or incorrect example
                preceding_text = text_parts[-1] if text_parts else ""
                is_correct = self._is_correct_example(preceding_text, code)

                examples.append(
                    CodeExample(code=code, language=language, is_correct=is_correct)
                )

        text_content = "".join(text_parts)
        return text_content, examples

    def _is_correct_example(self, preceding_text: str, code: str) -> bool:
        """Determine if a code example is correct or incorrect."""
        # Check preceding text for indicators
        incorrect_indicators = [
            "wrong",
            "incorrect",
            "bad",
            "don't",
            "never",
            "avoid",
            "❌",
        ]
        correct_indicators = ["correct", "right", "good", "do this", "✅"]

        # Check last few lines of preceding text
        last_lines = preceding_text.strip().split("\n")[-3:]
        last_text = " ".join(last_lines).lower()

        for indicator in incorrect_indicators:
            if indicator in last_text:
                return False

        for indicator in correct_indicators:
            if indicator in last_text:
                return True

        # Check code itself for comment indicators
        if "# WRONG" in code or "# BAD" in code or "# ❌" in code:
            return False
        if "# CORRECT" in code or "# GOOD" in code or "# ✅" in code:
            return True

        # Default: assume correct
        return True

    def _extract_title(self, text: str) -> str:
        """Extract title from text content (first sentence or meaningful phrase)."""
        # Remove leading dashes/bullets
        text = re.sub(r"^[-*]\s*", "", text.strip())

        # Get first sentence
        sentences = re.split(r"[.!?]\s+", text)
        if sentences:
            title = sentences[0].strip()
            # Limit length
            if len(title) > 60:
                title = title[:57] + "..."
            return title

        return "Rule"

    def _get_priority(self, section: str) -> int:
        """Get priority for a section."""
        for key, priority in self.SECTION_PRIORITIES.items():
            if key.lower() in section.lower():
                return priority
        return 50  # Default

    def _get_scope(self, section: str) -> List[str]:
        """Get file scope for a section."""
        for key, scope in self.SECTION_SCOPES.items():
            if key.lower() in section.lower():
                return scope
        return ["all"]

    def _get_tags(self, section: str) -> List[str]:
        """Get tags for a section."""
        tags = []
        section_lower = section.lower()

        tag_map = {
            "bash": ["bash", "shell", "script"],
            "python": ["python"],
            "security": ["security", "secret", "credential"],
            "yaml": ["yaml"],
            "json": ["json"],
            "documentation": ["documentation", "doc"],
        }

        for tag, keywords in tag_map.items():
            if any(keyword in section_lower for keyword in keywords):
                tags.append(tag)

        return tags
