## UzKeyboard 虛擬鍵盤
##
## 轉發語言介面與 View. 畫面由場景 @export 指定, 不動態建立預設 View.
## 類別腳本經 Autoload UZKeyboard 索引.

extends Control

# Variable ===================

## 殼層鍵: 退格
const KEY_BACKSPACE : StringName = &"backspace"
## 殼層鍵: 清除組字
const KEY_CLEAR : StringName = &"clear"
## 殼層鍵: 隱藏鍵盤
const KEY_HIDE : StringName = &"hide"

## 送出字串
var on_commit : Callable
## 組字已空仍退格
var on_backspace : Callable

## 語言包資料夾名 (langs/{lang_pack}/register.gd)
@export
var lang_pack : StringName = &""

## 組字 View (有 set_text 才用)
@export
var composition_view : Node = null
## 候選 View (有 set_candidates 才用)
@export
var candidates_view : Node = null
## 按鍵 View (有 bind_keys 才用)
@export
var keys_view : Node = null

## 目前語言
var _lang = null

## 實際呼叫的組字 View
var _composition_view : Node = null
## 實際呼叫的候選 View
var _candidates_view : Node = null
## 實際呼叫的按鍵 View
var _keys_view : Node = null

# GDScript ===================

func _ready () :
	self._ensure_views()
	if self._lang == null and self.lang_pack != &"" :
		var lang_id : StringName = UZKeyboard.load_lang_pack(self.lang_pack)
		if lang_id == &"" :
			lang_id = self.lang_pack
		self.set_lang(lang_id)

# Public =====================

## 顯示
func show_keyboard () -> void :
	self.visible = true

## 隱藏
func hide_keyboard () -> void :
	self.visible = false

## 設置送出
func set_commit_handler (cb : Callable) -> void :
	self.on_commit = cb

## 註冊語言
func register_lang (id : StringName, script) -> void :
	UZKeyboard.import_lang_script(id, script)

## 切換語言 (重建鍵盤)
func set_lang (id : StringName) -> void :
	self._ensure_views()
	var lang = UZKeyboard.new_lang(id)
	if lang == null :
		push_warning("uzkeyboard unknown lang: " + str(id))
		return
	self._lang = lang
	self._bind_keys()
	self._apply_lang_view()

## 選候選
func select_candidate (index : int) -> void :
	var text = self._lang_call("select", [index], "")
	self._apply_lang_view()
	self._emit_commit(str(text))

# Private ====================

func _ensure_views () -> void :
	self._composition_view = self.composition_view if self._node_has(self.composition_view, "set_text") else null
	self._candidates_view = self.candidates_view if self._node_has(self.candidates_view, "set_candidates") else null
	self._keys_view = self.keys_view if self._node_has(self.keys_view, "bind_keys") else null

func _bind_keys () -> void :
	self._view_call(self._keys_view, "bind_keys", [self._on_key])

func _on_key (key_id : StringName) -> void :
	if key_id == KEY_BACKSPACE :
		self._on_backspace_pressed()
		return
	if key_id == KEY_CLEAR :
		self._on_clear_pressed()
		return
	if key_id == KEY_HIDE :
		self.hide_keyboard()
		return
	var state = self._lang_call("handle_key", [key_id], null)
	self._apply_handle_state(state)

func _on_backspace_pressed () -> void :
	var before : String = str(self._lang_call("get_composition", [], ""))
	if before == "" :
		self._emit_backspace_empty()
		return
	var state = self._lang_call("backspace", [], null)
	if state == null :
		self._apply_lang_view()
		return
	self._apply_handle_state(state)

func _on_clear_pressed () -> void :
	self._lang_call("clear", [], null)
	self._apply_state("", [])

func _apply_state (composition : String, candidates) -> void :
	self._view_call(self._composition_view, "set_text", [composition])
	var list : Array = candidates if typeof(candidates) == TYPE_ARRAY else []
	self._view_call(self._candidates_view, "set_candidates", [list, self.select_candidate])

func _emit_commit (text : String) -> void :
	if text == "" :
		return
	if self.on_commit.is_valid() :
		self.on_commit.call(text)

func _emit_backspace_empty () -> void :
	if self.on_backspace.is_valid() :
		self.on_backspace.call()

func _node_has (node : Node, method_name : String) -> bool :
	return node != null and node.has_method(method_name)

func _view_call (node : Node, method_name : String, args : Array = []) -> void :
	if not self._node_has(node, method_name) :
		return
	node.callv(method_name, args)

## 語言 duck-typed 呼叫. 無方法則略過; 無方法時可讀同名屬性
func _lang_call (method_name : String, args : Array = [], default_val = null) :
	if self._lang == null :
		return default_val
	if self._lang.has_method(method_name) :
		return self._lang.callv(method_name, args)
	if args.is_empty() and method_name in self._lang :
		return self._lang.get(method_name)
	return default_val

func _apply_lang_view () -> void :
	self._apply_state(
		str(self._lang_call("get_composition", [], "")),
		self._lang_call("get_candidates", [], [])
	)

func _apply_handle_state (state) -> void :
	if typeof(state) != TYPE_DICTIONARY :
		self._apply_lang_view()
		return
	var composition = state.get("composition", self._lang_call("get_composition", [], ""))
	var candidates = state.get("candidates", self._lang_call("get_candidates", [], []))
	self._apply_state(str(composition), candidates)
	if state.has("commit") :
		self._emit_commit(str(state["commit"]))
