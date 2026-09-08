#!/usr/bin/env python3
"""Build uzkeyboard_view_pinyin.tscn from zhuyin chrome + QWERTY/tone layer."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ZHUYIN = ROOT.parent / "zhuyin" / "uzkeyboard_view_zhuyin.tscn"
OUT = ROOT / "uzkeyboard_view_pinyin.tscn"

BTN = """
[node name="{name}" type="Button" parent="{parent}"]
custom_minimum_size = Vector2(40, 44)
layout_mode = 2
size_flags_horizontal = 3
focus_mode = 0
text = "{text}"
"""

SPACE = """
[node name="space" type="Button" parent="{parent}"]
custom_minimum_size = Vector2(40, 44)
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 8.3
focus_mode = 0
text = "空白"
"""

BACKSPACE = """
[node name="backspace" type="Button" parent="{parent}"]
custom_minimum_size = Vector2(120, 44)
layout_mode = 2
focus_mode = 0
text = "←"
"""

ROW = """
[node name="{name}" type="HBoxContainer" parent="{parent}"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 4
"""


def row_btns(parent: str, names_texts: list[tuple[str, str]]) -> str:
	chunks = []
	for name, text in names_texts:
		chunks.append(BTN.format(name=name, parent=parent, text=text))
	return "".join(chunks)


def make_row(row_name: str, layer: str, names_texts: list[tuple[str, str]], extra: str = "") -> str:
	parent_row = f"{layer}/{row_name}"
	body = ROW.format(name=row_name, parent=layer)
	body += row_btns(parent_row, names_texts)
	body += extra
	return body


def layer_py() -> str:
	layer = "margin/layout/keys/layers/layer_py"
	out = """
[node name="layer_py" type="VBoxContainer" parent="margin/layout/keys/layers"]
visible = false
layout_mode = 2
size_flags_vertical = 3
theme_override_constants/separation = 4
alignment = 2
"""
	r1 = [(ch, ch) for ch in "qwertyuiop"]
	r2 = [(ch, ch) for ch in "asdfghjkl"]
	r3 = [(ch, "v/ü" if ch == "v" else ch) for ch in "zxcvbnm"]
	r4 = [("1", "1"), ("2", "2"), ("3", "3"), ("4", "4"), ("5", "˙")]
	out += make_row("row_1", layer, r1)
	out += make_row("row_2", layer, r2)
	out += make_row("row_3", layer, r3)
	out += make_row("row_4", layer, r4)
	out += ROW.format(name="row_5", parent=layer)
	r5 = layer + "/row_5"
	out += BTN.format(name="to_en", parent=r5, text="En")
	out += BTN.format(name="to_sym", parent=r5, text="@#?")
	out += SPACE.format(parent=r5)
	out += BACKSPACE.format(parent=r5)
	return out


def main() -> None:
	src = ZHUYIN.read_text(encoding="utf-8")
	# chrome: everything before layer_bpmf
	idx = src.index('[node name="layer_bpmf"')
	idx_en = src.index('[node name="layer_en"')
	head = src[:idx]
	tail = src[idx_en:]
	head = head.replace('[gd_scene load_steps=2 format=3 uid="uid://b2c7ahlqrwxnc"]', "[gd_scene load_steps=2 format=3]")
	head = head.replace(
		'uid="uid://2ogteu00470s" path="res://addons/uzkeyboard/langs/zhuyin/uzkeyboard_view_zhuyin.gd"',
		'path="res://addons/uzkeyboard/langs/pinyin/uzkeyboard_view_pinyin.gd"',
	)
	head = head.replace("uzkeyboard_view_zhuyin", "uzkeyboard_view_pinyin")
	head = head.replace('"layer_bpmf"', '"layer_py"')
	head = head.replace("layer_bpmf = NodePath", "layer_py = NodePath")
	head = head.replace("layers/layer_bpmf", "layers/layer_py")
	tail = tail.replace('name="to_bpmf"', 'name="to_py"')
	out = head + layer_py().lstrip("\n") + "\n" + tail
	OUT.write_text(out, encoding="utf-8")
	print(f"wrote {OUT}")


if __name__ == "__main__":
	main()
