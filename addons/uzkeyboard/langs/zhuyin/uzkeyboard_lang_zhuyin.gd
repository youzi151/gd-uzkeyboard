## UzKeyboard.Lang.Zhuyin 注音
##
## 大千式 26 鍵排列 (QWERTY 位置對應注音). 組字順序: 聲母 → 介音 → 韻母 → 聲調.
## 非法順序忽略該鍵. 空白: 有候選則選第一個; 組字空則送出空白.
## View 英文/符號鍵以 chr_x 或單一字元 id 直接送出.
## 不繼承核心 Lang; 鍵盤以 duck-typed (has_method) 呼叫.

extends RefCounted

# Variable ===================

## 聲母
const INITIALS := {
	&"b": "ㄅ", &"p": "ㄆ", &"m": "ㄇ", &"f": "ㄈ",
	&"d": "ㄉ", &"t": "ㄊ", &"n": "ㄋ", &"l": "ㄌ",
	&"g": "ㄍ", &"k": "ㄎ", &"h": "ㄏ",
	&"j": "ㄐ", &"q": "ㄑ", &"x": "ㄒ",
	&"zh": "ㄓ", &"ch": "ㄔ", &"sh": "ㄕ", &"r": "ㄖ",
	&"z": "ㄗ", &"c": "ㄘ", &"s": "ㄙ",
}

## 介音
const MEDIALS := {
	&"i": "ㄧ", &"u": "ㄨ", &"iu": "ㄩ",
}

## 韻母
const FINALS := {
	&"a": "ㄚ", &"o": "ㄛ", &"e": "ㄜ", &"eh": "ㄝ",
	&"ai": "ㄞ", &"ei": "ㄟ", &"au": "ㄠ", &"ou": "ㄡ",
	&"an": "ㄢ", &"en": "ㄣ", &"ang": "ㄤ", &"eng": "ㄥ", &"er": "ㄦ",
}

## 聲調
const TONES := {
	&"tone_2": "ˊ", &"tone_3": "ˇ", &"tone_4": "ˋ", &"tone_5": "˙",
}

## 本包路徑
const PACK_PATH := "res://addons/uzkeyboard/langs/zhuyin"

## 字典腳本
var _dict_script = null

## 字典
var _dict = null

## 組字槽
var _initial : String = ""
var _medial : String = ""
var _final : String = ""
var _tone : String = ""

## 候選快取
var _candidates : Array = []

# GDScript ===================

func _init (_index = null) :
	self._ensure_dict()
	self.load_dict(PACK_PATH.path_join("data/bpmf.json"))

# Interface ==================

func get_id () -> StringName :
	return &"zhuyin"

func handle_key (key_id : StringName) -> Dictionary :
	if key_id == &"space" :
		return self._on_space()
	
	if TONES.has(key_id) :
		if self._has_body() :
			self._tone = TONES[key_id]
			self._refresh_candidates()
		return self._state_dict()
	
	if INITIALS.has(key_id) :
		self._initial = INITIALS[key_id]
		self._refresh_candidates()
		return self._state_dict()
	
	if MEDIALS.has(key_id) :
		self._medial = MEDIALS[key_id]
		self._refresh_candidates()
		return self._state_dict()
	
	if FINALS.has(key_id) :
		self._final = FINALS[key_id]
		self._refresh_candidates()
		return self._state_dict()
	
	var direct : String = self._direct_char(key_id)
	if direct != "" :
		var state := self._state_dict()
		state["commit"] = direct
		return state
	
	return self._state_dict()

func get_composition () -> String :
	return self._initial + self._medial + self._final + self._tone

func get_candidates () -> Array :
	return self._candidates

func select (index : int) -> String :
	if index < 0 or index >= self._candidates.size() :
		return ""
	var text : String = self._candidates[index]
	self.clear()
	return text

func backspace () -> Dictionary :
	if self._tone != "" :
		self._tone = ""
	elif self._final != "" :
		self._final = ""
	elif self._medial != "" :
		self._medial = ""
	elif self._initial != "" :
		self._initial = ""
	self._refresh_candidates()
	return self._state_dict()

func clear () -> void :
	self._initial = ""
	self._medial = ""
	self._final = ""
	self._tone = ""
	self._candidates = []

func load_dict (path : String) -> void :
	self._ensure_dict()
	if self._dict == null :
		return
	self._dict.load_from_path(path)
	self._refresh_candidates()

# Private ====================

func _ensure_dict () -> void :
	if self._dict != null :
		return
	if self._dict_script == null :
		self._dict_script = UZKeyboard.load_script(PACK_PATH.path_join("uzkeyboard_dict_zhuyin.gd"))
	if self._dict_script == null :
		return
	self._dict = self._dict_script.new()

## View 自備鍵: chr_x 送出 x; 單一字元且非注音 id 則直接送出
func _direct_char (key_id : StringName) -> String :
	var s : String = String(key_id)
	if s.begins_with("chr_") and s.length() > 4 :
		return s.substr(4)
	if s.length() == 1 :
		return s
	return ""

func _has_body () -> bool :
	return self._initial != "" or self._medial != "" or self._final != ""

func _refresh_candidates () -> void :
	var comp := self.get_composition()
	if comp == "" or self._dict == null :
		self._candidates = []
		return
	self._candidates = self._dict.lookup(self._dict.zhuyin_to_keycode(comp))

func _on_space () -> Dictionary :
	if self._candidates.size() > 0 :
		var text : String = self.select(0)
		var state := self._state_dict()
		state["commit"] = text
		return state
	if not self._has_body() :
		var state := self._state_dict()
		state["commit"] = " "
		return state
	return self._state_dict()

func _state_dict () -> Dictionary :
	return {
		"composition": self.get_composition(),
		"candidates": self.get_candidates(),
	}
