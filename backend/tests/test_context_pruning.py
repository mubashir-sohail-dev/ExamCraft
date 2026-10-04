import pytest
from core.config import settings
from routers.generation import prune_retrieved_context


def test_max_context_chars_config_default():
    """Asserts that settings.MAX_CONTEXT_CHARS default is 12000."""
    assert settings.MAX_CONTEXT_CHARS == 12000


def test_context_pruning_boundary_enforcement():
    """Verifies that large contexts are pruned to <= 12000 chars along paragraph/newline boundaries."""
    # Create 25,000 character synthetic context with distinct paragraphs
    paragraphs = [
        f"Paragraph {i}: This is detailed educational textbook content explaining chemistry principles with formulas like H<sub>2</sub>O and CO<sub>2</sub>. It provides in-depth explanations for students studying Class 9 sciences." * 5
        for i in range(50)
    ]
    large_context = "\n\n".join(paragraphs)
    assert len(large_context) > 20000

    pruned = prune_retrieved_context(large_context, max_chars=12000)

    assert len(pruned) <= 12000
    assert len(pruned) >= 9600  # Should be within last 20% window
    # Should end at a clean boundary (no dangling partial tags or words)
    assert not pruned.endswith("\n")


def test_context_under_threshold_not_truncated():
    """Verifies that context under the 12000 character limit is not modified or truncated."""
    short_context = "This is a brief textbook excerpt of 500 characters.\n\n" * 10
    assert len(short_context) < 12000

    pruned = prune_retrieved_context(short_context, max_chars=12000)
    assert pruned == short_context.strip() or pruned == short_context


def test_context_pruning_empty_or_none():
    """Verifies edge cases for empty or None context."""
    assert prune_retrieved_context("", max_chars=12000) == ""
    assert prune_retrieved_context(None, max_chars=12000) is None


def test_sub_sup_html_preservation():
    """Verifies that chemical/math HTML formatting tags are preserved within pruned output."""
    context_with_formulas = "Topic 1: Water molecule is H<sub>2</sub>O.\n\nTopic 2: Quadratic term is x<sup>2</sup> + 2x + 1.\n\n" * 50
    pruned = prune_retrieved_context(context_with_formulas, max_chars=12000)

    assert len(pruned) <= 12000
    assert "H<sub>2</sub>O" in pruned
    assert "x<sup>2</sup>" in pruned
