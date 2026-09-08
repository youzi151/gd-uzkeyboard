## UzKeyboard.View 介面 (參考, 非必繼承)
##
## 組字 / 候選 / 按鍵 不必同一物件, 也不必 extends 本腳本.
## 鍵盤以 has_method 呼叫, 缺方法則略過.
## View 由場景 @export 指定; 可為某一語言的皮膚 (切換面板、殼層鍵).

extends RefCounted

# Variable ===================

# GDScript ===================

# Extends ====================

# Interface ==================

## 組字顯示
func set_text (_txt : String) -> void :
	pass

## 候選. on_select(index)
func set_candidates (_candi_arr : Array, _on_select : Callable) -> void :
	pass

## 綁定按鍵. on_key(key_id). 鍵面由 View 自行產生或綁場景按鈕.
func bind_keys (_on_key : Callable) -> void :
	pass

# Public =====================

# Private ====================
