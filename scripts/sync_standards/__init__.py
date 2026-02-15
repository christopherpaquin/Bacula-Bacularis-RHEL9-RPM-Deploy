"""
Standards Synchronization System

Automatically propagates CONTEXT.md changes to tool-specific AI configurations
with preprocessing and tool-specific optimization.

Package structure:
- parser.py: Parse CONTEXT.md into structured rules
- transformers/: Tool-specific transformers
- templates/: Jinja2 templates for each tool
- validator.py: Validate generated files
- generator.py: Orchestrate the sync pipeline
"""

__version__ = "1.0.0"
