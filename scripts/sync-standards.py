#!/usr/bin/env python3
"""
Standards Synchronization CLI

Command-line interface for synchronizing CONTEXT.md to tool-specific configurations.

Usage:
    python3 scripts/sync-standards.py [OPTIONS]

Options:
    --dry-run       Preview changes without writing files
    --verbose       Show detailed output
    --help          Show this help message

Examples:
    # Preview changes
    python3 scripts/sync-standards.py --dry-run

    # Run synchronization
    python3 scripts/sync-standards.py

    # Verbose output
    python3 scripts/sync-standards.py --verbose
"""

import sys
import argparse
from pathlib import Path

# Add sync_standards to path
sys.path.insert(0, str(Path(__file__).parent))

from sync_standards.generator import SyncGenerator


def main():
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Synchronize CONTEXT.md to tool-specific AI configurations",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Preview changes without writing
  %(prog)s --dry-run

  # Run full synchronization
  %(prog)s

  # Verbose mode with detailed output
  %(prog)s --verbose
        """,
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview changes without writing files",
    )

    parser.add_argument(
        "--verbose", "-v", action="store_true", help="Show detailed output"
    )

    parser.add_argument(
        "--context",
        type=Path,
        default=Path("CONTEXT.md"),
        help="Path to CONTEXT.md (default: CONTEXT.md)",
    )

    args = parser.parse_args()

    # Determine paths
    repo_root = Path.cwd()
    context_path = repo_root / args.context
    templates_dir = Path(__file__).parent / "sync_standards" / "templates"

    # Validate paths
    if not context_path.exists():
        print(f"❌ Error: CONTEXT.md not found at {context_path}")
        print("   Run this script from the repository root")
        return 1

    if not templates_dir.exists():
        print(f"❌ Error: Templates directory not found at {templates_dir}")
        return 1

    # Create generator and run
    generator = SyncGenerator(
        context_path=context_path,
        templates_dir=templates_dir,
        dry_run=args.dry_run,
        verbose=args.verbose,
    )

    success = generator.sync()

    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
