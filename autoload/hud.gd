extends CanvasLayer
# HUD kiri atas: tombol pause + bar sanity, tampil di semua scene kecuali menu utama.
# Seluruh UI dibuat lewat kode, jadi tidak perlu scene.

const HIDDEN_SCENES := [
	"res://Scene/Ui/main_menu.tscn",
]
const BAR_SIZE := Vector2(360, 24)
const MARGIN := Vector2(40, 32)
const PAUSE_BUTTON_SIZE := Vector2(64, 64)

var holder: HBoxContainer          # baris kiri atas: tombol pause + sanity
var box: VBoxContainer
var title: Label
var bar: ProgressBar
var fill: StyleBoxFlat
var _tween: Tween
var _flash: Tween

func _ready() -> void:
	layer = 60                                   # di atas lampu/senter (5), di bawah dialog (80)
	process_mode = Node.PROCESS_MODE_ALWAYS      # tetap bergerak saat game di-pause
	_build()
	GameState.sanity_changed.connect(_on_sanity_changed)
	_set_value(GameState.sanity, true)

func _build() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	holder = HBoxContainer.new()
	holder.position = MARGIN
	holder.add_theme_constant_override("separation", 20)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(holder)

	holder.add_child(_make_pause_button())

	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(box)

	title = Label.new()
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 8)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)

	bar = ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = GameState.MAX_SANITY
	bar.show_percentage = false
	bar.custom_minimum_size = BAR_SIZE
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.65)
	bg.set_border_width_all(2)
	bg.border_color = Color(0.85, 0.85, 0.85, 0.8)
	bg.set_corner_radius_all(4)

	fill = StyleBoxFlat.new()
	fill.set_corner_radius_all(3)

	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	box.add_child(bar)

func _make_pause_button() -> Button:
	var b := Button.new()
	b.text = "II"
	b.custom_minimum_size = PAUSE_BUTTON_SIZE
	b.focus_mode = Control.FOCUS_NONE            # supaya Space (tombol QTE) tidak ikut menekannya
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 30)
	b.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _button_style(Color(0, 0, 0, 0.55)))
	b.add_theme_stylebox_override("hover", _button_style(Color(0.15, 0.15, 0.15, 0.75)))
	b.add_theme_stylebox_override("pressed", _button_style(Color(0.3, 0.3, 0.3, 0.85)))
	b.pressed.connect(func(): PauseMenu.open())
	return b

func _button_style(color: Color) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = color
	st.set_border_width_all(2)
	st.border_color = Color(0.85, 0.85, 0.85, 0.8)
	st.set_corner_radius_all(6)
	return st

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	holder.visible = scene != null and not HIDDEN_SCENES.has(scene.scene_file_path)

func _on_sanity_changed(value: int) -> void:
	_set_value(value, false)

func _set_value(value: int, instant: bool) -> void:
	var dropped := float(value) < bar.value
	title.text = "SANITY  %d" % value
	fill.bg_color = _color_for(float(value) / GameState.MAX_SANITY)

	if _tween:
		_tween.kill()
	if instant:
		bar.value = value
		return
	_tween = create_tween()
	_tween.tween_property(bar, "value", float(value), 0.5) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if dropped:                                  # kilat merah saat sanity berkurang
		if _flash:
			_flash.kill()
		box.modulate = Color(1.0, 0.3, 0.3)
		_flash = create_tween()
		_flash.tween_property(box, "modulate", Color.WHITE, 0.8)

func _color_for(ratio: float) -> Color:
	if ratio > 0.6:
		return Color(0.55, 0.85, 0.65)           # aman
	if ratio > 0.3:
		return Color(0.95, 0.75, 0.30)           # waspada
	return Color(0.85, 0.15, 0.15)               # kritis
