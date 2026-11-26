class_name SettingsPanel
extends Control

signal closed

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(500, 0)
	box.add_theme_constant_override("separation", 24)
	center.add_child(box)

	var title := Label.new()
	title.text = "PENGATURAN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	box.add_child(title)

	var vol_label := Label.new()
	vol_label.text = "Volume"
	vol_label.add_theme_font_size_override("font_size", 32)
	box.add_child(vol_label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	slider.custom_minimum_size = Vector2(0, 40)
	slider.value_changed.connect(_on_volume)
	box.add_child(slider)

	var fs := CheckBox.new()
	fs.text = "Layar penuh"
	fs.add_theme_font_size_override("font_size", 32)
	fs.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs.toggled.connect(_on_fullscreen)
	box.add_child(fs)

	var back := Button.new()
	back.text = "Kembali"
	back.add_theme_font_size_override("font_size", 32)
	back.custom_minimum_size = Vector2(0, 70)
	back.pressed.connect(func(): closed.emit())
	box.add_child(back)

func _on_volume(v: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(v))
	AudioServer.set_bus_mute(0, v <= 0.0)

func _on_fullscreen(on: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)
