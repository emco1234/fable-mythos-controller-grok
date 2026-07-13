"""Tests for adapters — verify graceful stub fallback when CLI is missing.

Each repo's adapter is named after its own platform, so this test
file is per-repo. Tests use the env-var override RELIABILITY_<PLATFORM>_BIN
to force a non-existent binary path, so the adapter's stub path is exercised
without depending on whether the actual CLI is installed.
"""
import asyncio
import os
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))


class TestGrokAdapterStub(unittest.TestCase):
    def setUp(self):
        os.environ["RELIABILITY_GROK_BIN"] = "/nonexistent/grok-binary-xyz"

    def test_stub_when_no_binary(self):
        from adapters.grok_adapter import GrokAdapter
        adapter = GrokAdapter()
        async def run():
            return await adapter.spawn("reliability-scout", "test prompt")
        path = asyncio.run(run())
        text = Path(path).read_text(encoding="utf-8")
        self.assertIn("STUB", text)
        # Either "not found in PATH" or "not found at <path>" is acceptable
        self.assertTrue(
            "grok CLI not found" in text or "grok binary not found" in text,
            f"expected grok-not-found reason, got: {text[:200]!r}",
        )

    def test_spawn_writes_prompt_to_transcript(self):
        from adapters.grok_adapter import GrokAdapter
        adapter = GrokAdapter()
        async def run():
            return await adapter.spawn("reliability-lead", "do the thing")
        path = asyncio.run(run())
        text = Path(path).read_text(encoding="utf-8")
        self.assertIn("do the thing", text)


if __name__ == "__main__":
    unittest.main()