"""
Tool-Specific Transformers

Each transformer knows how to convert parsed rules into the optimal format
for a specific AI tool.
"""

from .base import BaseTransformer
from .cursor import CursorTransformer
from .claude import ClaudeTransformer
from .copilot import CopilotTransformer
from .aider import AiderTransformer
from .continue_dev import ContinueTransformer

__all__ = [
    "BaseTransformer",
    "CursorTransformer",
    "ClaudeTransformer",
    "CopilotTransformer",
    "AiderTransformer",
    "ContinueTransformer",
]
