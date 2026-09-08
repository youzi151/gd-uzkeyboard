## uzkeyboard 虛擬鍵盤
##
## 以 Godot Control 實作的螢幕鍵盤. 語言(組字/候選)為可抽換介面.
## Autoload: UzKeyboard (index_uzkeyboard.gd)
##

@tool
extends EditorPlugin

const AUTOLOAD_NAME := "UZKeyboard"

func _enter_tree () :
	self.add_autoload_singleton(AUTOLOAD_NAME, "res://addons/uzkeyboard/scripts/index_uzkeyboard.gd")

func _exit_tree () :
	self.remove_autoload_singleton(AUTOLOAD_NAME)
