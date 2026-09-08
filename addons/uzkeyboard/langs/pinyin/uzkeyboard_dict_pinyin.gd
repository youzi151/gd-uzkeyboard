## UzKeyboard.Dict.Pinyin 拼音字典
##
## JSON: { table: { pinyin → 字串陣列 }, keys: [首次出現順序] }
## 有聲調則精確; 無聲調則合併 1-5. 前綴查詢走首字母桶 (cin 序), 不掃全表.

extends RefCounted

# Variable ===================

## 聲調字元
const TONE_CHARS := "12345"

## 候選上限
const CANDI_CAP := 40

## 表
var _table : Dictionary = {}

## 首字母 → cin 序 key 陣列
var _by_first : Dictionary = {}

# GDScript ===================

func _init (path : String = "") :
	if path != "" :
		self.load_from_path(path)

# Public =====================

## 從路徑載入
func load_from_path (path : String) -> void :
	self._table = {}
	self._by_first = {}
	if not FileAccess.file_exists(path) :
		push_warning("uzkeyboard dict not found: " + path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null :
		push_warning("uzkeyboard dict open fail: " + path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	self._ingest(parsed, path)

## 查詢. 精確 + 無調合併 + 前綴 (cin 序, 去重, 封頂)
func lookup (code : String) -> Array :
	if code == "" :
		return []
	var merged : Array = []
	var seen : Dictionary = {}
	self._append_unique(merged, seen, self._table.get(code, []), -1)
	if not self._has_tone(code) :
		for i in TONE_CHARS.length() :
			self._append_unique(merged, seen, self._table.get(code + TONE_CHARS.substr(i, 1), []), -1)
	var first : String = code.substr(0, 1)
	var bucket = self._by_first.get(first, [])
	if typeof(bucket) != TYPE_ARRAY :
		return merged
	for key in bucket :
		if merged.size() >= CANDI_CAP :
			break
		var k : String = str(key)
		if k == code :
			continue
		if not k.begins_with(code) :
			continue
		self._append_unique(merged, seen, self._table.get(k, []), CANDI_CAP)
	return merged

# Private ====================

func _ingest (parsed, path : String) -> void :
	if typeof(parsed) != TYPE_DICTIONARY :
		push_warning("uzkeyboard dict json invalid: " + path)
		return
	var table = parsed.get("table", parsed)
	if typeof(table) != TYPE_DICTIONARY :
		push_warning("uzkeyboard dict json invalid: " + path)
		return
	self._table = table
	var keys = parsed.get("keys", table.keys())
	if typeof(keys) != TYPE_ARRAY :
		keys = table.keys()
	for item in keys :
		var k : String = str(item)
		if k == "" :
			continue
		var ch : String = k.substr(0, 1)
		if not self._by_first.has(ch) :
			self._by_first[ch] = []
		self._by_first[ch].append(k)

func _has_tone (text : String) -> bool :
	if text.is_empty() :
		return false
	return TONE_CHARS.contains(text.substr(text.length() - 1, 1))

func _append_unique (dst : Array, seen : Dictionary, val, cap : int = -1) -> void :
	if typeof(val) != TYPE_ARRAY :
		return
	for item in val :
		if cap >= 0 and dst.size() >= cap :
			return
		var s := str(item)
		if seen.has(s) :
			continue
		seen[s] = true
		dst.push_back(s)
