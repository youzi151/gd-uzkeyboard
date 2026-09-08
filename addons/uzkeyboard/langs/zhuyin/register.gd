## UzKeyboard 語言包 注音
##
## 向索引註冊本包語言腳本. 索引只認 langs/{name}/register.gd 慣例.

extends RefCounted

# Public =====================

## 註冊到索引, 回傳語言 id
func register (index) -> StringName :
	var lang_script = UZKeyboard.load_script("res://addons/uzkeyboard/langs/zhuyin/uzkeyboard_lang_zhuyin.gd")
	index.import_lang_script(&"zhuyin", lang_script)
	return &"zhuyin"
