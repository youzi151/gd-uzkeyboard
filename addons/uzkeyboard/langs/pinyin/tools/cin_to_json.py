#!/usr/bin/env python3
"""Convert OpenVanilla-style pinyin.cin %chardef into JSON.

Handles `%chardef begin` with any whitespace (zhuyin tool requires two spaces).
Emits { "table": {code: [chars]}, "keys": [first-seen codes] }.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def _norm_pct(line: str) -> str:
	return "".join(line.split()).lower()


def parse_chardef(text: str) -> tuple[dict[str, list[str]], list[str]]:
	table: dict[str, list[str]] = {}
	keys: list[str] = []
	in_def = False
	for raw in text.splitlines():
		line = raw.strip()
		if not in_def:
			if _norm_pct(line) == "%chardefbegin":
				in_def = True
			continue
		if _norm_pct(line) == "%chardefend":
			break
		if not line or line.startswith("#") or line.startswith("%"):
			continue
		parts = line.split(None, 1)
		if len(parts) != 2:
			continue
		code, ch = parts
		bucket = table.get(code)
		if bucket is None:
			bucket = []
			table[code] = bucket
			keys.append(code)
		if ch not in bucket:
			bucket.append(ch)
	return table, keys


def main() -> None:
	root = Path(__file__).resolve().parents[1]
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument(
		"--input",
		type=Path,
		default=root / "data" / "pinyin.cin",
	)
	parser.add_argument(
		"--output",
		type=Path,
		default=root / "data" / "pinyin.json",
	)
	args = parser.parse_args()
	table, keys = parse_chardef(args.input.read_text(encoding="utf-8"))
	payload = {"table": table, "keys": keys}
	args.output.write_text(
		json.dumps(payload, ensure_ascii=False, separators=(",", ":")),
		encoding="utf-8",
	)
	print(f"wrote {args.output} ({len(keys)} keys, {sum(len(v) for v in table.values())} chars)")


if __name__ == "__main__":
	main()
