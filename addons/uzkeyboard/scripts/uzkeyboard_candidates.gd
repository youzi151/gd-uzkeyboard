## UzKeyboard.Candidates 候選列
##
## 在宿主 Control 內動態產生候選按鈕.

extends RefCounted

# Public =====================

## 重建候選按鈕
static func rebuild (host : Control, candidates : Array, on_pick : Callable) -> void :
	if host == null :
		return
	
	var children := host.get_children()
	for child in children :
		host.remove_child(child)
	
	var row : HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	host.add_child(row)
	
	for idx in candidates.size() :
		var btn := Button.new()
		btn.text = str(candidates[idx])
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(func () :
			if on_pick.is_valid() :
				on_pick.call(idx)
		)
		row.add_child(btn)

# Private ====================
