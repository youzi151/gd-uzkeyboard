## UzKeyboard 拼音畫面
##
## 場景皮膚. 少量槽位 @export; 按鍵以節點名 get_node.
## 面板切換不呼叫 on_key.

extends Control

# Variable ===================

const LAYER_PY : StringName = &"py"
const LAYER_EN : StringName = &"en"
const LAYER_SYM : StringName = &"sym"

const KEY_BACKSPACE : StringName = &"backspace"
const KEY_HIDE : StringName = &"hide"

const SYM_EMIT := {
	"at": "@", "hash": "#", "dollar": "$", "percent": "%", "amp": "&",
	"star": "*", "minus": "-", "plus": "+", "lpar": "(", "rpar": ")",
	"bang": "!", "quest": "?", "comma": ",", "dot": ".", "apos": "'",
	"quot": "\"", "colon": ":", "semi": ";", "slash": "/", "bslash": "\\",
}

## 組字
@export
var composition_label : Label = null
## 候選列 (HBox, 候選鈕仍動態長在裡面)
@export
var candidates : Control = null
## 拼音面板
@export
var layer_py : Control = null
## 英文面板
@export
var layer_en : Control = null
## 符號面板
@export
var layer_sym : Control = null
## 候選列
@export
var bar_candi : Control = null

## 目前面板
var _layer_id : StringName = LAYER_PY
## 英文大寫
var _en_shift : bool = false
## 符號全形 (East Asian Width)
var _sym_ea_width : bool = false
## 送出鍵
var _on_key : Callable
## 是否已綁按鍵
var _wired : bool = false

# GDScript ===================

# Public =====================

## 組字顯示
func set_text (txt : String) -> void :
	if self.composition_label == null :
		return
	self.composition_label.text = txt
	self._refresh_candidates()

## 候選
func set_candidates (candi_arr : Array, on_select : Callable) -> void :
	if self.candidates == null :
		return
	self._clear_children(self.candidates)
	if typeof(candi_arr) != TYPE_ARRAY :
		return
	for idx in candi_arr.size() :
		var btn := Button.new()
		btn.text = str(candi_arr[idx])
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(on_select.bind(idx))
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		self.candidates.add_child(btn)
	self._refresh_candidates()

## 綁定 on_key. 鍵面已在場景裡
func bind_keys (on_key : Callable) -> void :
	self._on_key = on_key
	if not self._wired :
		self._wire_all()
		self._wired = true
	self._apply_en_shift_labels()
	self._apply_sym_ea_width_labels()
	self._show_layer(self._layer_id)

# Private ====================

func _wire_all () -> void :
	self._wire_layer_btns(self.layer_py, self._on_py_btn)
	self._wire_layer_btns(self.layer_en, self._on_en_btn)
	self._wire_layer_btns(self.layer_sym, self._on_sym_btn)

func _wire_layer_btns (root : Node, handler : Callable) -> void :
	if root == null :
		return
	var stack : Array = [root]
	while stack.size() > 0 :
		var node : Node = stack.pop_back()
		for child in node.get_children() :
			stack.append(child)
			if child is BaseButton :
				child.pressed.connect(handler.bind(child))

func _on_py_btn (btn : BaseButton) -> void :
	var n : String = str(btn.name)
	match n :
		"to_en" :
			self._show_layer(LAYER_EN)
		"to_sym" :
			self._show_layer(LAYER_SYM)
		_ :
			self._emit(StringName(n))

func _on_en_btn (btn : BaseButton) -> void :
	var n : String = str(btn.name)
	match n :
		"to_py" :
			self._show_layer(LAYER_PY)
		"to_sym" :
			self._show_layer(LAYER_SYM)
		"shift" :
			self._en_shift = not self._en_shift
			self._apply_en_shift_labels()
		_ :
			if n.length() == 1 :
				var ch : String = n.to_upper() if self._en_shift else n.to_lower()
				self._emit(StringName("chr_" + ch))
			else :
				self._emit(StringName(n))

func _on_sym_btn (btn : BaseButton) -> void :
	var n : String = str(btn.name)
	match n :
		"to_py" :
			self._show_layer(LAYER_PY)
		"to_en" :
			self._show_layer(LAYER_EN)
		"ea_width" :
			self._sym_ea_width = not self._sym_ea_width
			self._apply_sym_ea_width_labels()
		_ :
			if SYM_EMIT.has(n) :
				self._emit(StringName(self._to_ea_width(str(SYM_EMIT[n]))))
			elif n.length() == 1 and n.is_valid_int() :
				self._emit(StringName(self._to_ea_width(n)))
			else :
				self._emit(StringName(n))

func _refresh_candidates () -> void :
	if self.bar_candi == null or self.candidates == null or self.composition_label == null :
		return
	self.bar_candi.visible = self._layer_id == LAYER_PY \
		and (self.candidates.get_child_count() > 0 \
		or self.composition_label.text.length() > 0)

func _apply_en_shift_labels () -> void :
	if self.layer_en == null :
		return
	var stack : Array = [self.layer_en]
	while stack.size() > 0 :
		var node : Node = stack.pop_back()
		for child in node.get_children() :
			stack.append(child)
			if child is Button :
				var n : String = str(child.name)
				if n.length() == 1 and "abcdefghijklmnopqrstuvwxyz".contains(n.to_lower()) :
					child.text = n.to_upper() if self._en_shift else n.to_lower()

func _apply_sym_ea_width_labels () -> void :
	if self.layer_sym == null :
		return
	var stack : Array = [self.layer_sym]
	while stack.size() > 0 :
		var node : Node = stack.pop_back()
		for child in node.get_children() :
			stack.append(child)
			if child is Button :
				var n : String = str(child.name)
				if n == "ea_width" :
					child.text = "全" if self._sym_ea_width else "半"
				elif SYM_EMIT.has(n) :
					child.text = self._to_ea_width(str(SYM_EMIT[n]))
				elif n.length() == 1 and n.is_valid_int() :
					child.text = self._to_ea_width(n)

func _to_ea_width (ch : String) -> String :
	if not self._sym_ea_width or ch.length() != 1 :
		return ch
	var c : int = ch.unicode_at(0)
	if c >= 0x21 and c <= 0x7E :
		return String.chr(c + 0xFEE0)
	return ch

func _show_layer (layer_id : StringName) -> void :
	self._layer_id = layer_id
	if self.layer_py != null :
		self.layer_py.visible = (layer_id == LAYER_PY)
	if self.layer_en != null :
		self.layer_en.visible = (layer_id == LAYER_EN)
	if self.layer_sym != null :
		self.layer_sym.visible = (layer_id == LAYER_SYM)
	self._refresh_candidates()

func _emit (key_id : StringName) -> void :
	if self._on_key.is_valid() :
		self._on_key.call(key_id)

func _clear_children (node : Node) -> void :
	if node == null :
		return
	var children := node.get_children()
	for child in children :
		node.remove_child(child)
