## UzKeyboard.Lang 語言介面 (參考, 非必繼承)
##
## 語言包不必 extends 本腳本. 鍵盤以 has_method 呼叫, 缺方法則略過.
## handle_key 回傳 Dictionary:
##   composition: String
##   candidates: Array
##   commit: String (可選, 有值時鍵盤立即 on_commit)

extends RefCounted

# Variable ===================

# GDScript ===================

# Extends ====================

# Interface ==================

## 語言識別
func get_id () -> StringName :
	return &""

## 處理一顆鍵
func handle_key (_key_id : StringName) -> Dictionary :
	return self._state_dict()

## 目前組字
func get_composition () -> String :
	return ""

## 目前候選
func get_candidates () -> Array :
	return []

## 選字, 回傳要送出的字串並清空組字
func select (_index : int) -> String :
	return ""

## 刪一碼. 組字已空時回傳的 composition 為空字串 (鍵盤可轉呼叫 on_backspace)
func backspace () -> Dictionary :
	return self._state_dict()

## 清空組字與候選
func clear () -> void :
	pass

## 載入字典 (可選)
func load_dict (_path : String) -> void :
	pass

## 選項 (可選)
func set_opts (_opts : Dictionary) -> void :
	pass

# Public =====================

# Private ====================

func _state_dict () -> Dictionary :
	return {
		"composition": self.get_composition(),
		"candidates": self.get_candidates(),
	}
