## UzKeyboard.Dict.Zhuyin 注音字典
##
## JSON: 大千 keycode → 字串陣列. 例如 "2j6": ["讀","獨","毒"]
## 查詢前由語言把組字注音轉成 keycode. 無聲調則合併該音節各調 (3/4/6/7).

extends RefCounted

# Variable ===================

## 注音字元 → 大千鍵 (bpmf.cin %keyname)
const ZHUYIN_TO_KEYCODE := {
	"ㄅ": "1", "ㄉ": "2", "ˇ": "3", "ˋ": "4", "ㄓ": "5",
	"ˊ": "6", "˙": "7", "ㄚ": "8", "ㄞ": "9", "ㄢ": "0",
	"ㄦ": "-", "ㄝ": ",", "ㄡ": ".", "ㄥ": "/", "ㄤ": ";",
	"ㄆ": "q", "ㄊ": "w", "ㄍ": "e", "ㄐ": "r", "ㄔ": "t",
	"ㄧ": "u", "ㄛ": "i", "ㄟ": "o", "ㄣ": "p",
	"ㄇ": "a", "ㄋ": "s", "ㄎ": "d", "ㄑ": "f", "ㄕ": "g",
	"ㄘ": "h", "ㄨ": "j", "ㄜ": "k", "ㄠ": "l",
	"ㄈ": "z", "ㄌ": "x", "ㄏ": "c", "ㄒ": "v", "ㄖ": "b",
	"ㄗ": "y", "ㄩ": "m", "ㄙ": "n",
}

## 聲調 keycode (二三四輕; 一聲無鍵)
const TONE_KEYCODES := ["3", "4", "6", "7"]

## 表
var _table : Dictionary = {}

# GDScript ===================

func _init (path : String = "") :
	if path != "" :
		self.load_from_path(path)

# Public =====================

## 從路徑載入
func load_from_path (path : String) -> void :
	if not FileAccess.file_exists(path) :
		push_warning("uzkeyboard dict not found: " + path)
		self._table = {}
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null :
		push_warning("uzkeyboard dict open fail: " + path)
		self._table = {}
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY :
		push_warning("uzkeyboard dict json invalid: " + path)
		self._table = {}
		return
	self._table = parsed

## 注音組字 → 大千 keycode. 未知字元則空字串
func zhuyin_to_keycode (composition : String) -> String :
	if composition == "" :
		return ""
	var code := ""
	for i in composition.length() :
		var ch := composition.substr(i, 1)
		if not ZHUYIN_TO_KEYCODE.has(ch) :
			push_warning("uzkeyboard unknown zhuyin glyph: " + ch)
			return ""
		code += ZHUYIN_TO_KEYCODE[ch]
	return code

## 查詢. 有聲調則精確; 無聲調則合併該音節各調
func lookup (keycode : String) -> Array :
	if keycode == "" :
		return []
	if self._has_tone(keycode) :
		return self._as_str_array(self._table.get(keycode, []))
	var merged : Array = []
	var seen : Dictionary = {}
	self._append_unique(merged, seen, self._table.get(keycode, []))
	for tone in TONE_KEYCODES :
		self._append_unique(merged, seen, self._table.get(keycode + tone, []))
	return merged

# Private ====================

func _has_tone (text : String) -> bool :
	if text.is_empty() :
		return false
	return TONE_KEYCODES.has(text.substr(text.length() - 1, 1))

func _as_str_array (val) -> Array :
	var result : Array = []
	if typeof(val) != TYPE_ARRAY :
		return result
	for item in val :
		result.push_back(str(item))
	return result

func _append_unique (dst : Array, seen : Dictionary, val) -> void :
	if typeof(val) != TYPE_ARRAY :
		return
	for item in val :
		var s := str(item)
		if seen.has(s) :
			continue
		seen[s] = true
		dst.push_back(s)
