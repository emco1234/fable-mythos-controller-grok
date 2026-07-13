"""
Grok Build CLI adapter for the Walking Skeleton controller.

Spawns an agent via `grok` CLI and writes the transcript to .transcripts/.
NOTE: This is a scaffold — wire to the real Grok CLI invocation in P2.
"""
from __future__ import annotations

import asyncio
from datetime import datetime, timezone
from pathlib import Path

from controller import PlatformAdapter


TRANSCRIPT_DIR = Path(".transcripts")


class GrokAdapter(PlatformAdapter):
    """Spawn a Grok subagent via the `grok` CLI and capture its transcript."""

    async def spawn(self, agent_name: str, prompt: str) -> str:
        TRANSCRIPT_DIR.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        transcript_path = TRANSCRIPT_DIR / f"{agent_name}-{timestamp}.md"

        # Scaffold: write the prompt as the transcript. Replace with real
        # `grok spawn --agent <name> --prompt <prompt>` in P2.
        transcript_path.write_text(
            f"# Transcript stub for {agent_name}\n\nPrompt:\n\n{prompt}\n",
            encoding="utf-8",
        )

        # Yield to the event loop so async dispatch is testable
        await asyncio.sleep(0)
        return str(transcript_path)