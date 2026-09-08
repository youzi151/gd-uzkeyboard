## UzKeyboard.Lang.Direct
##
## 無組字. 把 View 送來的 key_id 直接 commit 成字元.
## space → 空白; chr_x → x; 單一字元 id → 該字元.
## 不繼承核心 Lang; 鍵盤以 duck-typed (has_method) 呼叫.

extends RefCounted

# GDScript ===================

func _init (_index = null) :
	pass

# Interface ==================

func get_id () -> StringName :
	return &"direct"

func handle_key (key_id : StringName) -> Dictionary :
	var text : String = self._direct_char(key_id)
	if text == "" :
		return self._state_dict()
	var state := self._state_dict()
	state["commit"] = text
	return state

func get_composition () -> String :
	return ""

func get_candidates () -> Array :
	return []

func select (_index : int) -> String :
	return ""

func backspace () -> Dictionary :
	return self._state_dict()

func clear () -> void :
	pass

# Private ====================

func _direct_char (key_id : StringName) -> String :
	if key_id == &"space" :
		return " "
	var s : String = String(key_id)
	if s.begins_with("chr_") and s.length() > 4 :
		return s.substr(4)
	if s.length() == 1 :
		return s
	return ""

func _state_dict () -> Dictionary :
	return {
		"composition": "",
		"candidates": [],
	}
