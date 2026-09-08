#!/usr/bin/env python3
"""Convert OpenVanilla-style bpmf.cin %chardef into keycode → characters JSON."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

CHARDEF_BEGIN = "%chardef  begin"
CHARDEF_END = "%chardef  end"


def parse_chardef(text: str) -> dict[str, list[str]]:
	table: dict[str, list[str]] = {}
	in_def = False
	for raw in text.splitlines():
		line = raw.strip()
		if not in_def:
			if line == CHARDEF_BEGIN:
				in_def = True
			continue
		if line == CHARDEF_END:
			break
		if not line or line.startswith("%"):
			continue
		parts = line.split(None, 1)
		if len(parts) != 2:
			continue
		code, ch = parts
		bucket = table.setdefault(code, [])
		if ch not in bucket:
			bucket.append(ch)
	return table


def main() -> None:
	root = Path(__file__).resolve().parents[1]
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument(
		"--input",
		type=Path,
		default=root / "data" / "bpmf.cin",
	)
	parser.add_argument(
		"--output",
		type=Path,
		default=root / "data" / "bpmf.json",
	)
	args = parser.parse_args()
	table = parse_chardef(args.input.read_text(encoding="utf-8"))
	args.output.write_text(
		json.dumps(table, ensure_ascii=False, separators=(",", ":")),
		encoding="utf-8",
	)
	print(f"wrote {args.output} ({len(table)} keys)")


if __name__ == "__main__":
	main()
