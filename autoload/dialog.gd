extends CanvasLayer

signal finished

var root: Control
var name_label: Label
var text_label: Label
var _tween: Tween
var _active := false
var _typing := false
var _advance := false

func _ready() -> void:
	layer = 80
	_build()
	root.visible = false

func _build() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.gui_input.connect(_on_gui_input)
	add_child(root)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 80
	panel.offset_right = -80
	panel.offset_top = -280
	panel.offset_bottom = -40
	root.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	margin.add_child(box)

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 34)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	box.add_child(name_label)

	text_label = Label.new()
	text_label.add_theme_font_size_override("font_size", 38)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(text_label)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		if _typing:
			if _tween:
				_tween.kill()
			text_label.visible_ratio = 1.0
			_typing = false
		else:
			_advance = true

# Pemakaian: await Dialog.say([["Ez", "Akhirnya kamu bangun."], ["Karani", "Siapa kamu?"]])
func say(lines: Array) -> void:
	if _active:
		return
	_active = true
	root.visible = true
	for line in lines:
		var who: String = line[0]
		var text: String = line[1]
		name_label.text = who
		text_label.text = text
		text_label.visible_ratio = 0.0
		_typing = true
		_advance = false
		_tween = create_tween()
		_tween.tween_property(text_label, "visible_ratio", 1.0, maxf(0.3, text.length() * 0.03))
		_tween.finished.connect(func(): _typing = false)
		while not _advance:
			await get_tree().process_frame
	root.visible = false
	_active = false
	finished.emit()
