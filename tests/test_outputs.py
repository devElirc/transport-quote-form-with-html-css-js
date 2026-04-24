"""Python smoke checks for the transport-quote-form task harness.

Uses only the stdlib (``unittest``) so ``tests/test.sh`` does not need ``pip``
or ``venv`` on minimal verifier images. The file name ``test_*.py`` satisfies
tools that scan for that pattern. Primary verification remains in
``unit/*.spec.ts`` (Vitest) and ``e2e/*.spec.ts`` (Playwright).
"""

from __future__ import annotations

import unittest
from pathlib import Path


class TestHarnessOutputs(unittest.TestCase):
    """Lightweight checks on /app/index.html and tests packaging."""

    def test_app_index_html_exists(self) -> None:
        self.assertTrue(Path("/app/index.html").is_file())

    def test_app_html_declares_document_title(self) -> None:
        html = Path("/app/index.html").read_text(encoding="utf-8", errors="replace")
        self.assertIn("<title>Transport Quote Form</title>", html)

    def test_app_html_includes_success_and_validation_copy(self) -> None:
        html = Path("/app/index.html").read_text(encoding="utf-8", errors="replace")
        self.assertIn("Success!", html)
        self.assertIn("Please select a valid year, make, and model", html)

    def test_tests_dir_has_pinned_node_lockfiles(self) -> None:
        tests_dir = Path(__file__).resolve().parent
        self.assertTrue((tests_dir / "package.json").is_file())
        self.assertTrue((tests_dir / "package-lock.json").is_file())


if __name__ == "__main__":
    unittest.main()
