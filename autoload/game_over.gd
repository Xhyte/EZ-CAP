extends CanvasLayer
# Layar game over. Muncul otomatis saat GameState.died dikirim (sanity habis).
# Seluruh UI dibuat lewat kode, jadi tidak perlu scene.

const MAIN_MENU := "res://Scene/Ui/main_menu.tscn"
const RETRY_SCENE := "res://Scene/Levels/corridor.tscn"   # tujuan setelah "Coba Lagi"

var root: Control
var retry_button: Button
var _busy := false

func _ready() -> void:
	layer = 110                                  # di atas pause (100) dan transisi (100)
	process_mode = Node.PROCESS_MODE_ALWAYS      # tetap berjalan saat game di-pause
	_build()
	root.visible = false
	GameState.died.connect(show_screen)

func _build() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP      # klik tidak tembus ke game
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.92)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(560, 0)
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)

	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 110)
	title.add_theme_color_override("font_color", Color(0.75, 0.08, 0.08))
	box.add_child(title)

	var sub := Label.new()
	sub.text = "Kewarasanmu habis. Kampus ini tidak membiarkanmu pergi."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 30)
	sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	box.add_child(sub)

	box.add_child(Control.new())                 # jarak kosong

	retry_button = _button("Coba Lagi", box, _on_retry)
	_button("Menu Utama", box, _on_menu)

func _button(text: String, parent: Control, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 36)
	b.custom_minimum_size = Vector2(0, 70)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func show_screen() -> void:
	_busy = true          # tombol dikunci 1,5 detik supaya klik/spasi dari QTE tidak langsung memencetnya
	get_tree().paused = true
	root.modulate.a = 0.0
	root.visible = true
	retry_button.grab_focus()
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(root, "modulate:a", 1.0, 0.8)
	get_tree().create_timer(1.5).timeout.connect(func(): _busy = false)

func _on_retry() -> void:
	if _busy:
		return
	_busy = true
	root.visible = false
	get_tree().paused = false                    # harus dilepas dulu, kalau tidak transisi macet
	GameState.retry()
	SceneManager.go_to(RETRY_SCENE)

func _on_menu() -> void:
	if _busy:
		return
	_busy = true
	root.visible = false
	get_tree().paused = false
	SceneManager.go_to(MAIN_MENU)                # main_menu.gd memanggil GameState.reset()
