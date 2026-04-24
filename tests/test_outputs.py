"""Pytest smoke checks for the transport-quote-form task harness.

These tests exist so automated review tools that expect ``test_*.py`` under
``tests/`` can complete. Primary behavioral verification remains in
``unit/*.spec.ts`` (Vitest) and ``e2e/*.spec.ts`` (Playwright), orchestrated by
``tests/test.sh``.
"""

from __future__ import annotations

from pathlib import Path


def test_app_index_html_exists() -> None:
    """Verify the agent-authored single-page app exists at /app/index.html."""
    assert Path("/app/index.html").is_file()


def test_app_html_declares_document_title() -> None:
    """Verify /app/index.html contains the exact required document title tag."""
    html = Path("/app/index.html").read_text(encoding="utf-8", errors="replace")
    assert "<title>Transport Quote Form</title>" in html


def test_app_html_includes_success_and_validation_copy() -> None:
    """Verify instruction-mandated user-visible strings exist in the shipped HTML."""
    html = Path("/app/index.html").read_text(encoding="utf-8", errors="replace")
    assert "Success!" in html
    assert "Please select a valid year, make, and model" in html


def test_tests_dir_has_pinned_node_lockfiles() -> None:
    """Verify Node packaging files required by the verifier are present under /tests/."""
    tests_dir = Path(__file__).resolve().parent
    assert (tests_dir / "package.json").is_file()
    assert (tests_dir / "package-lock.json").is_file()
