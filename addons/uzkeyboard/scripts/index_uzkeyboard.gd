extends Node

# desc ==========

## 索引 UzKeyboard 虛擬鍵盤
##
## 集中載入核心類別腳本. 語言實作由 langs/{name}/register.gd 註冊.
## 經 Autoload 存取自身, 其他腳本不需知道索引檔路徑.

# Variable ===================

## 路徑
var SCRIPT_PATH : String = "res://addons/uzkeyboard/scripts"

## 根路徑
var ROOT_PATH : String = "res://addons/uzkeyboard"

## 版本
const VERSION := "0.1.0"

## 鍵盤
var Keyboard
## 語言介面
var Lang
## 畫面介面 (方法清單參考)
var View
## 候選列
var Candidates

## 語言 名稱:腳本
var name_to_lang_script := {}

## 是否已經初始化
var _is_indexed := false

# GDScript ===================

func _ready () :
	self.index()

# Public =====================

## 建立索引
func index () :
	if self._is_indexed : return self
	
	var root_node : Node = self.get_tree().root
	if root_node.has_node("UREQ") :
		
		var UREQ = root_node.get_node("UREQ")
		
		# 綁定 索引
		UREQ.gbind(&"UzKeyboard", func():
			self._uzkeyboard_init()
			return self
		, {
			"alias" : [],
		})
		
	self._uzkeyboard_init()
	
	self._is_indexed = true
	
	return self

## 載入語言包 langs/{pack_name}/register.gd, 回傳語言 id
func load_lang_pack (pack_name) -> StringName :
	if not self._is_indexed : self.index()
	var path := self.ROOT_PATH.path_join("langs").path_join(str(pack_name)).path_join("register.gd")
	var script = self.load_script(path)
	if script == null :
		push_warning("uzkeyboard lang pack not found: " + path)
		return &""
	return script.new().register(self)

## 匯入 語言 腳本
func import_lang_script (import_name, path_or_script) :
	self.name_to_lang_script[import_name] = path_or_script

## 取得 語言 腳本
func get_lang_script (name_or_path) :
	if not self._is_indexed : self.index()
	if self.name_to_lang_script.has(name_or_path) :
		var stored = self.name_to_lang_script[name_or_path]
		if stored is Script :
			return stored
		return self.load_script(str(stored))
	if typeof(name_or_path) == TYPE_STRING or typeof(name_or_path) == TYPE_STRING_NAME :
		var as_str := str(name_or_path)
		if as_str.begins_with("res://") :
			return self.load_script(as_str)
	if name_or_path is Script :
		return name_or_path
	return null

## 建立 語言
func new_lang (id) :
	if not self._is_indexed : self.index()
	var script = self.get_lang_script(id)
	if script == null :
		return null
	return script.new(self)


## 讀取腳本
func load_script (path: String, is_reload := false) :
	var stack = get_stack()
	for each in stack :
		if each.source == path :
			push_error("can't load script [%s] already in run stack" % [path])
			return null
	
	var ext : String = path.get_extension()
	if not ext.begins_with("gd") : return null
	
	var pathc : String = path
	if ext == "gd" : pathc = path + "c"
	if ResourceLoader.exists(pathc) :
		path = pathc
	
	var cache_mode = -1
	if is_reload :
		cache_mode = ResourceLoader.CACHE_MODE_IGNORE_DEEP
	
	if cache_mode != -1 : return ResourceLoader.load(path, &"GDScript", cache_mode)
	else : return ResourceLoader.load(path, &"GDScript")

# Private ====================

func _uzkeyboard_init () :
	if self.Keyboard != null :
		return
	
	self.Keyboard = self.load_script(self.SCRIPT_PATH.path_join("uzkeyboard.gd"))
	self.Lang = self.load_script(self.SCRIPT_PATH.path_join("uzkeyboard_lang.gd"))
	self.View = self.load_script(self.SCRIPT_PATH.path_join("uzkeyboard_view.gd"))
	self.Candidates = self.load_script(self.SCRIPT_PATH.path_join("uzkeyboard_candidates.gd"))
