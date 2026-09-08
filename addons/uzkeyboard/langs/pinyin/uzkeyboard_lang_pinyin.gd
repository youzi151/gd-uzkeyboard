## UzKeyboard.Lang.Pinyin 拼音
##
## 組字為羅馬拼音字串 (a-z, v=ü) 加可選聲調 1-5.
## 非法鍵忽略. 空白: 有候選則選第一個; 組字空則送出空白.
## View 英文/符號鍵以 chr_x 或單一字元 id 直接送出.
## 不繼承核心 Lang; 鍵盤以 duck-typed (has_method) 呼叫.

extends RefCounted

# Variable ===================

## 字母
const LETTERS := "abcdefghijklmnopqrstuvwxyz"

## 聲調
const TONES := "12345"

## 本包路徑
const PACK_PATH := "res://addons/uzkeyboard/langs/pinyin"

## 字典腳本
var _dict_script = null

## 字典
var _dict = null

## 組字
var _buffer : String = ""

## 候選快取
var _candidates : Array = []

# GDScript ===================

func _init (_index = null) :
	self._ensure_dict()
	self.load_dict(PACK_PATH.path_join("data/pinyin.json"))

# Interface ==================

func get_id () -> StringName :
	return &"pinyin"

func handle_key (key_id : StringName) -> Dictionary :
	if key_id == &"space" :
		return self._on_space()
	
	var s : String = String(key_id)
	if s.length() == 1 and LETTERS.contains(s) :
		if not self._has_tone() :
			self._buffer += s
			self._refresh_candidates()
		return self._state_dict()
	
	if s.length() == 1 and TONES.contains(s) :
		if self._letter_body() != "" :
			if self._has_tone() :
				self._buffer = self._letter_body() + s
			else :
				self._buffer += s
			self._refresh_candidates()
			return self._state_dict()
		var state := self._state_dict()
		state["commit"] = s
		return state
	
	var direct : String = self._direct_char(key_id)
	if direct != "" :
		var state := self._state_dict()
		state["commit"] = direct
		return state
	
	return self._state_dict()

func get_composition () -> String :
	return self._buffer

func get_candidates () -> Array :
	return self._candidates

func select (index : int) -> String :
	if index < 0 or index >= self._candidates.size() :
		return ""
	var text : String = self._candidates[index]
	self.clear()
	return text

func backspace () -> Dictionary :
	if self._buffer.length() > 0 :
		self._buffer = self._buffer.substr(0, self._buffer.length() - 1)
	self._refresh_candidates()
	return self._state_dict()

func clear () -> void :
	self._buffer = ""
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
		self._dict_script = UZKeyboard.load_script(PACK_PATH.path_join("uzkeyboard_dict_pinyin.gd"))
	if self._dict_script == null :
		return
	self._dict = self._dict_script.new()

## View 自備鍵: chr_x 送出 x; 單一字元且非拼音字母/聲調則直接送出
func _direct_char (key_id : StringName) -> String :
	var s : String = String(key_id)
	if s.begins_with("chr_") and s.length() > 4 :
		return s.substr(4)
	if s.length() == 1 :
		if LETTERS.contains(s) or TONES.contains(s) :
			return ""
		return s
	return ""

func _letter_body () -> String :
	if self._has_tone() :
		return self._buffer.substr(0, self._buffer.length() - 1)
	return self._buffer

func _has_tone () -> bool :
	if self._buffer.is_empty() :
		return false
	return TONES.contains(self._buffer.substr(self._buffer.length() - 1, 1))

func _refresh_candidates () -> void :
	if self._buffer == "" or self._dict == null :
		self._candidates = []
		return
	self._candidates = self._dict.lookup(self._buffer)

func _on_space () -> Dictionary :
	if self._candidates.size() > 0 :
		var text : String = self.select(0)
		var state := self._state_dict()
		state["commit"] = text
		return state
	if self._buffer == "" :
		var state := self._state_dict()
		state["commit"] = " "
		return state
	return self._state_dict()

func _state_dict () -> Dictionary :
	return {
		"composition": self.get_composition(),
		"candidates": self.get_candidates(),
	}
