"""Validate documented Shortcuts JSON with the actual backend request model.

Offline only: no HTTP requests, credentials, or database access. Run with the
backend hash-locked Python environment after implementing the import schema.
"""

import json
from pathlib import Path
import re
import sys


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    sys.path.insert(0, str(root / "backend"))
    from app.health.schemas import ImportRequest
    count = 0
    for name in ("apple-health-contract.md", "apple-health-shortcut.md"):
        doc = (root / "docs" / name).read_text()
        for block in re.findall(r"```json\n(.*?)\n```", doc, re.DOTALL):
            payload = json.loads(block)
            assert "token" not in payload and "Authorization" not in payload
            ImportRequest.model_validate_json(block)
            count += 1
    assert count == 2, "Both contract and instruction must contain JSON examples"
    print(f"Validated {count} documented JSON examples; no network or database access.")


if __name__ == "__main__":
    main()
