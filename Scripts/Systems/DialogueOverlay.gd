class_name DialogueOverlay
extends CanvasLayer
## ============================================================================
## DialogueOverlay — 全屏 AVG 剧情覆盖层（由关卡 Level 在运行时实例）
## ----------------------------------------------------------------------------
## 职责：读剧本 JSON（每段剧情一个文件）+ 角色注册表 Characters.json，
##       按句驱动对话流：说话人立绘/姿态切换、打字机逐字显示、
##       点击 / 回车 / 空格推进，Esc 或"跳过"整段跳过；结束发 finished 信号。
## 数据约定：剧本路径由关卡 Level 根节点 story_* 导出传入；一句只需写
##       speaker + pose，图路径在 Characters.json 注册（写台词不写路径）。
## 容错：文件缺失 / JSON 非法 / 未知角色姿态 → push_error/warning 并降级
##       为无立绘继续（或直接结束），绝不中断关卡流程。
## 布局见 Scenes/Dialogue/DialogueOverlay.tscn；本脚本只驱动显隐/文本/纹理。
## ============================================================================

const CHAR_DB_PATH := "res://Resources/Dialogue/Characters.json"
## 打字机速率：每秒显示字符数（UI 节奏常量，非玩法数值）
const TYPE_CHARS_PER_SEC := 28.0

signal finished(completed: bool)

var _active := false
var _story_path := ""
var _lines: Array = []
var _line_index := -1
var _typing := false
var _char_count := 0
var _typed_chars := 0.0

## 角色注册表缓存：character_key -> {name: String, poses: {pose_key: String}}
var _characters: Dictionary = {}
## 立绘纹理缓存：资源路径 -> Texture2D（避免每次重 load）
var _texture_cache: Dictionary = {}

@onready var _portrait: TextureRect = $Root/Portrait
@onready var _name_label: Label = $Root/DialogueBox/Content/Name
@onready var _text_label: Label = $Root/DialogueBox/Content/Text
@onready var _continue_hint: Label = $Root/DialogueBox/Content/ContinueHint


func _ready() -> void:
	$Root/CatchBtn.pressed.connect(advance)
	$Root/SkipBtn.pressed.connect(skip)
	_continue_hint.visible = false
	hide()


## 剧情播放期间：回车/空格推进，Esc 整段跳过（此时 HUD 已由 Level 抑制暂停）
func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and not event.is_echo():
		skip()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _active or not _typing:
		return
	_typed_chars += delta * TYPE_CHARS_PER_SEC
	var shown := mini(int(_typed_chars), _char_count)
	_text_label.text = _current_text().substr(0, shown)
	if shown >= _char_count:
		_typing = false
		_continue_hint.visible = true


## 外部入口：开始播放一段剧情。缺文件/非法结构 → 直接结束并告警。
func play(story_path: String) -> void:
	if _active:
		push_warning("DialogueOverlay: 已有剧情播放中，忽略 %s" % story_path)
		return
	if not _load_characters():
		push_error("DialogueOverlay: 无法读取角色注册表 %s" % CHAR_DB_PATH)
		_emit_finished(false)
		return
	if not _load_story(story_path):
		push_error("DialogueOverlay: 无法读取/解析剧本 %s" % story_path)
		_emit_finished(false)
		return
	_active = true
	_story_path = story_path
	show()
	_line_index = -1
	_show_next_line()


## 推进一步：打字中 → 立即整句显示；已完整显示 → 下一条（末句则结束）
func advance() -> void:
	if not _active:
		return
	if _typing:
		_typing = false
		_typed_chars = _char_count
		_text_label.text = _current_text()
		_continue_hint.visible = true
		return
	if _line_index >= _lines.size() - 1:
		_end(true)
	else:
		_show_next_line()


## 跳过整段（Esc / 跳过按钮）。跳过也视为"播完"，Level 照常走后续流程。
func skip() -> void:
	if _active:
		_end(false)


## 当前台词全文（供打字机切取）
func _current_text() -> String:
	var line: Dictionary = _lines[_line_index]
	return str(line.get("text", ""))


func _show_next_line() -> void:
	_line_index += 1
	if _line_index >= _lines.size():
		_end(true)
		return
	_apply_line(_lines[_line_index])


func _apply_line(line: Dictionary) -> void:
	var speaker := str(line.get("speaker", ""))
	var pose := str(line.get("pose", ""))
	var name_override := str(line.get("name", ""))
	var text := str(line.get("text", ""))
	if text.is_empty():
		# 空台词直接跳过，不占一次点击
		_show_next_line()
		return
	# 角色名：台词自带 > 注册表 > 隐藏名字栏
	var display_name := name_override
	if display_name.is_empty() and not speaker.is_empty():
		var char_data: Dictionary = _characters.get(speaker, {})
		display_name = str(char_data.get("name", ""))
	_name_label.visible = not display_name.is_empty()
	_name_label.text = display_name
	# 立绘：按 speaker + pose 解析资源路径；未知则降级（先试注册表其它姿态）
	_set_portrait(speaker, pose)
	_text_label.text = ""
	_char_count = text.length()
	_typed_chars = 0.0
	_typing = true
	_continue_hint.visible = false


func _set_portrait(speaker: String, pose: String) -> void:
	var path := ""
	if not speaker.is_empty():
		var char_data: Dictionary = _characters.get(speaker, {})
		if char_data.is_empty():
			push_warning("DialogueOverlay[%s]: 未知角色 '%s'，本句无立绘" % [_story_path, speaker])
		else:
			var poses: Dictionary = char_data.get("poses", {})
			if not pose.is_empty() and poses.has(pose):
				path = str(poses[pose])
			else:
				if not pose.is_empty():
					push_warning("DialogueOverlay[%s]: 角色 '%s' 无姿态 '%s'，退回首个姿态" % [_story_path, speaker, pose])
				if not poses.is_empty():
					path = str(poses.values()[0])
	if path.is_empty():
		_portrait.texture = null
		_portrait.visible = false
		return
	var tex: Texture2D = _cached_texture(path)
	_portrait.texture = tex
	_portrait.visible = tex != null


func _cached_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path]
	var tex := load(path) as Texture2D
	if tex == null:
		push_warning("DialogueOverlay: 立绘资源缺失 %s" % path)
		return null
	_texture_cache[path] = tex
	return tex


func _load_characters() -> bool:
	var fa := FileAccess.open(CHAR_DB_PATH, FileAccess.READ)
	if fa == null:
		return false
	var data = JSON.parse_string(fa.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return false
	_characters = data.get("characters", {})
	return typeof(_characters) == TYPE_DICTIONARY


func _load_story(path: String) -> bool:
	var fa := FileAccess.open(path, FileAccess.READ)
	if fa == null:
		return false
	var data = JSON.parse_string(fa.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var raw = data.get("lines", [])
	if typeof(raw) != TYPE_ARRAY:
		return false
	_lines.clear()
	for item in raw:
		if typeof(item) == TYPE_DICTIONARY:
			_lines.append(item)
	return not _lines.is_empty()


func _end(completed: bool) -> void:
	_active = false
	_typing = false
	_portrait.texture = null
	hide()
	finished.emit(completed)


func _emit_finished(completed: bool) -> void:
	_active = false
	finished.emit(completed)
