extends Control

## TestUZKeyboard
## 
## 提供給各語言包測試使用, 具體場景可參考 langs/direct/test_uzkeyboard_direct.tscn
##

# Variable ===================

## 輸出
@export
var output_label : Label = null

## 鍵盤
@export
var keyboard : Control = null

# GDScript ===================

func _ready () :
	self.keyboard.set_commit_handler(self._on_commit)
	self.keyboard.on_backspace = self._on_backspace
	self.keyboard.show_keyboard()

func _on_commit (text : String) -> void :
	self.output_label.text += text

func _on_backspace () -> void :
	var s : String = self.output_label.text
	if s.length() <= 0 :
		return
	self.output_label.text = s.substr(0, s.length() - 1)
