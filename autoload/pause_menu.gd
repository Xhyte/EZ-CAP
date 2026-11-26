extends CanvasLayer

const MAIN_MENU := "res://Scene/Ui/main_menu.tscn"   # sesuaikan dengan lokasi main_menu.tscn

var menu: Control
var settings: SettingsPanel

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	menu.visible = false

func _build() -> void:
	menu = Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(450, 0)
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)

	var title := Label.new()
	title.text = "PAUSE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	box.add_child(title)

	_button("Lanjutkan", box, resume)
	_button("Pengaturan", box, func(): settings.visible = true)
	_button("Menu Utama", box, _to_main_menu)

	settings = SettingsPanel.new()
	settings.visible = false
	settings.closed.connect(func(): settings.visible = false)
	add_child(settings)

func _button(text: String, parent: Control, callback: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 36)
	b.custom_minimum_size = Vector2(0, 70)
	b.pressed.connect(callback)
	parent.add_child(b)

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path == MAIN_MENU:
		return
	get_viewport().set_input_as_handled()
	if settings.visible:
		settings.visible = false
	elif menu.visible:
		resume()
	else:
		open()

func open() -> void:
	menu.visible = true
	get_tree().paused = true

func resume() -> void:
	menu.visible = false
	settings.visible = false
	get_tree().paused = false

func _to_main_menu() -> void:
	resume()
	SceneManager.go_to(MAIN_MENU)
