## UzKeyboard.ViewExample 開發示例畫面
##
## 自備英文與符號鍵, 橫向捲動. 示範 View 自定鍵面 + on_key 1:1.
## 配 langs/direct. 殼層鍵由本 View 產生. 掛在場景上指到鍵盤 @export.

extends Control

# Variable ===================

const KEY_BACKSPACE : StringName = &"backspace"
const KEY_CLEAR : StringName = &"clear"
const KEY_HIDE : StringName = &"hide"

const LETTERS := "abcdefghijklmnopqrstuvwxyz"
const SYMBOLS := "1234567890@#$%&*-+()!?,.'\":;/\\"

## 根垂直列
var _vbox : VBoxContainer = null
## 上方留白
var _spacer : Control = null
## 組字
var _composition_label : Label = null
## 候選宿主
var _candidates_host : Control = null
## 橫向捲動
var _scroll : ScrollContainer = null
## 鍵列
var _keys_row : HBoxContainer = null
## 殼層列
var _chrome_row : HBoxContainer = null

# GDScript ===================

# Public =====================

## 組字顯示
func set_text (txt : String) -> void :
	self._ensure_composition()
	self._composition_label.text = txt

## 候選
func set_candidates (candi_arr : Array, on_select : Callable) -> void :
	self._ensure_candidates()
	UZKeyboard.Candidates.rebuild(self._candidates_host, candi_arr, on_select)

## 綁定 on_key. 鍵面由本 View 列出, 不向語言要 layout
func bind_keys (on_key : Callable) -> void :
	self._ensure_keys()
	self._clear_children(self._keys_row)
	for i in LETTERS.length() :
		var ch : String = LETTERS[i]
		self._keys_row.add_child(self._emit_btn(ch, StringName("chr_" + ch), on_key))
	self._keys_row.add_child(self._emit_btn("空白", &"space", on_key))
	for i in SYMBOLS.length() :
		var ch : String = SYMBOLS[i]
		self._keys_row.add_child(self._emit_btn(ch, StringName(ch), on_key))
	self._clear_children(self._chrome_row)
	self._chrome_row.add_child(self._emit_btn("退格", KEY_BACKSPACE, on_key, func(btn: Button):
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	))
	self._chrome_row.add_child(self._emit_btn("清除", KEY_CLEAR, on_key, func(btn: Button):
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	))
	self._chrome_row.add_child(self._emit_btn("隱藏", KEY_HIDE, on_key, func(btn: Button):
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	))

# Private ====================

func _ensure_root () -> void :
	if self._vbox != null :
		return
	self.set_anchors_preset(Control.PRESET_FULL_RECT)
	self._vbox = VBoxContainer.new()
	self._vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	self._vbox.add_theme_constant_override("separation", 6)
	self.add_child(self._vbox)
	self._spacer = Control.new()
	self._spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	self._spacer.size_flags_stretch_ratio = 1.0
	self._vbox.add_child(self._spacer)

func _ensure_composition () -> void :
	if self._composition_label != null :
		return
	self._ensure_root()
	self._composition_label = Label.new()
	self._composition_label.add_theme_font_size_override("font_size", 20)
	self._vbox.add_child(self._composition_label)
	self._restack()

func _ensure_candidates () -> void :
	if self._candidates_host != null :
		return
	self._ensure_root()
	var candidates := ScrollContainer.new()
	candidates.custom_minimum_size = Vector2(0, 48)
	candidates.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	self._vbox.add_child(candidates)
	self._candidates_host = candidates
	self._restack()

func _ensure_keys () -> void :
	if self._scroll != null :
		return
	self._ensure_root()
	self._scroll = ScrollContainer.new()
	self._scroll.custom_minimum_size = Vector2(0, 52)
	self._scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	self._scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	self._vbox.add_child(self._scroll)
	self._keys_row = HBoxContainer.new()
	self._keys_row.add_theme_constant_override("separation", 4)
	self._scroll.add_child(self._keys_row)
	self._chrome_row = HBoxContainer.new()
	self._chrome_row.add_theme_constant_override("separation", 4)
	self._chrome_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	self._vbox.add_child(self._chrome_row)
	self._restack()

func _emit_btn (label : String, key_id : StringName, on_key : Callable, extra_settle : Callable = Callable()) -> Button :
	var btn := Button.new()
	btn.text = label
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(40, 44)
	if on_key.is_valid() :
		btn.pressed.connect(on_key.bind(key_id))
	if extra_settle.is_valid() :
		extra_settle.call(btn)
	return btn

func _restack () -> void :
	if self._vbox == null :
		return
	var order : Array = []
	if self._spacer != null :
		order.append(self._spacer)
	if self._composition_label != null :
		order.append(self._composition_label)
	if self._candidates_host != null :
		order.append(self._candidates_host)
	if self._scroll != null :
		order.append(self._scroll)
	if self._chrome_row != null :
		order.append(self._chrome_row)
	for i in order.size() :
		self._vbox.move_child(order[i], i)

func _clear_children (node : Node) -> void :
	if node == null :
		return
	var children := node.get_children()
	for child in children :
		node.remove_child(child)
