"""
Standards Sync Generator

Orchestrates the synchronization pipeline from CONTEXT.md to all tool configs.
"""

from pathlib import Path
from typing import Dict, List

from .parser import ContextParser, Rule
from .transformers import (
    CursorTransformer,
    ClaudeTransformer,
    CopilotTransformer,
    AiderTransformer,
)
from .validator import Validator


class SyncGenerator:
    """Main synchronization generator."""

    def __init__(
        self,
        context_path: Path,
        templates_dir: Path,
        dry_run: bool = False,
        verbose: bool = False,
    ):
        """Initialize generator.

        Args:
            context_path: Path to CONTEXT.md
            templates_dir: Path to templates directory
            dry_run: If True, don't write files
            verbose: If True, print detailed output
        """
        self.context_path = context_path
        self.templates_dir = templates_dir
        self.dry_run = dry_run
        self.verbose = verbose

        # Initialize components
        self.parser = ContextParser(context_path)
        self.validator = Validator()

        # Initialize transformers
        self.transformers = {
            "Cursor": CursorTransformer(templates_dir),
            "Claude": ClaudeTransformer(templates_dir),
            "GitHub Copilot": CopilotTransformer(templates_dir),
            "Aider": AiderTransformer(templates_dir),
            # TODO: Fix Continue.dev YAML generation
            # "Continue.dev": ContinueTransformer(templates_dir),
        }

    def sync(self) -> bool:
        """Run full synchronization pipeline.

        Returns:
            True if successful, False otherwise
        """
        print("🔄 Standards Synchronization System\n")

        # Step 1: Parse CONTEXT.md
        print("📖 Step 1: Parsing CONTEXT.md...")
        try:
            rules = self.parser.parse()
            print(
                f"   ✓ Parsed {len(rules)} rules from {self._count_sections(rules)} sections\n"
            )
            if self.verbose:
                self._print_rules_summary(rules)
        except Exception as e:
            print(f"   ✗ Failed to parse: {e}")
            return False

        # Step 2: Transform for each tool
        print("🔧 Step 2: Transforming for each tool...")
        all_files = {}
        try:
            for tool_name, transformer in self.transformers.items():
                if self.verbose:
                    print(f"   - {tool_name}...", end=" ")
                files = transformer.transform(rules)
                all_files.update(files)
                if self.verbose:
                    print(f"✓ ({len(files)} file(s))")

            if not self.verbose:
                print(
                    f"   ✓ Generated {len(all_files)} file(s) for {len(self.transformers)} tools\n"
                )
            else:
                print()
        except Exception as e:
            print(f"   ✗ Transformation failed: {e}")
            return False

        # Step 3: Validate
        print("✅ Step 3: Validating generated files...")
        if not self.validator.validate_all(all_files):
            print("   ✗ Validation failed")
            self.validator.print_results()
            return False
        print("   ✓ All files validated successfully\n")

        # Step 4: Write files (or dry-run)
        if self.dry_run:
            print("🔍 DRY RUN - Would generate:\n")
            self._print_dry_run_summary(all_files)
        else:
            print("💾 Step 4: Writing files...")
            try:
                self._write_files(all_files)
                print("   ✓ All files written successfully\n")
            except Exception as e:
                print(f"   ✗ Failed to write files: {e}")
                return False

        # Print summary and next steps
        self._print_success_summary(all_files)

        return True

    def _count_sections(self, rules: List[Rule]) -> int:
        """Count unique sections in rules."""
        return len(set(rule.section for rule in rules))

    def _print_rules_summary(self, rules: List[Rule]):
        """Print summary of parsed rules."""
        sections = {}
        for rule in rules:
            if rule.section not in sections:
                sections[rule.section] = []
            sections[rule.section].append(rule)

        print("\n   Rules by section:")
        for section, section_rules in sections.items():
            print(f"     • {section}: {len(section_rules)} rule(s)")
        print()

    def _print_dry_run_summary(self, files: Dict[str, str]):
        """Print dry-run summary."""
        for filepath, content in files.items():
            lines = content.count("\n") + 1
            print(f"📄 {filepath}")
            print(f"   {lines} lines")
            print("   Preview:")
            preview_lines = content.split("\n")[:5]
            for line in preview_lines:
                print(f"   {line}")
            if lines > 5:
                print(f"   ... ({lines - 5} more lines)")
            print()

    def _write_files(self, files: Dict[str, str]):
        """Write generated files to disk."""
        for filepath, content in files.items():
            path = Path(filepath)

            # Create parent directories
            path.parent.mkdir(parents=True, exist_ok=True)

            # Write file
            path.write_text(content, encoding="utf-8")

            if self.verbose:
                print(f"   ✓ {filepath}")

    def _print_success_summary(self, files: Dict[str, str]):
        """Print success summary."""
        print("=" * 60)
        print("✅ Synchronization Complete!")
        print("=" * 60)
        print(f"\nGenerated {len(files)} file(s):")
        for filepath in sorted(files.keys()):
            print(f"  • {filepath}")

        if not self.dry_run:
            print("\n📋 Next Steps:")
            print("  1. Review changes: git diff")
            print("  2. Test with AI tools")
            print("  3. Run pre-commit: pre-commit run --all-files")
            print("  4. Commit: git commit -am 'Sync standards from CONTEXT.md'")
        else:
            print("\n💡 To apply changes, run without --dry-run")
