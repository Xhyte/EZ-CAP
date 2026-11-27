extends Control
# Prolog: gambar diam + teks mengetik + suara. Seluruh UI dibuat lewat kode.
# Klik kiri / Space = lanjut. Klik kanan atau tombol "Lewati" = langsung ke game.

@export_file("*.tscn") var next_scene := "res://Scene/Levels/corridor.tscn"
@export var bg_kelas: Texture2D       # kosong = otomatis pakai gambar kelas bawaan
@export var bg_lorong: Texture2D      # kosong = otomatis pakai gambar koridor bawaan
@export var karani: Texture2D         # seret gambar Karani dari FileSystem ke sini
@export var ez: Texture2D             # seret gambar Ez dari FileSystem ke sini

const DEFAULT_KELAS := "res://Assets/kelas pintu kanan.png"
const DEFAULT_LORONG := "res://Assets/Coridor.png"
const HUM_PATH := "res://Sound/Fluorescent Light Humming.mp3"
const HUM_DB := -12.0
const SCREEN := Vector2(1920, 1080)
const CHAR_BOX := Vector2(800, 780)   # kotak tempat gambar karakter (rasio gambar dijaga)
const CHAR_TOP := 80.0

# bg: "" = layar hitam | "kelas" | "lorong"
# dark: 0..1 seberapa gelap | hum: dengung lampu (kalau tidak ditulis, tetap seperti sebelumnya)
# char: "" | "karani" | "ez"
const SLIDES := [
	{"text": "Kuliah hari itu panjang. Terlalu panjang.",
		"bg": "", "hum": true},
	{"text": "Karani tidak ingat kapan matanya terpejam.",
		"bg": ""},
	{"text": "Saat terbangun, tidak ada suara. Tidak ada siapa-siapa.",
		"bg": "kelas", "dark": 0.35, "char": "karani"},
	{"text": "Lampu padam. Hanya cahaya bulan yang masuk lewat jendela.",
		"bg": "kelas", "dark": 0.7, "hum": false},
	{"text": "Kampus ini seharusnya ramai. Malam ini, ia terasa menahan napas.",
		"bg": "lorong", "dark": 0.5},
	{"text": "Lalu, dari bangku paling belakang, ada yang berbisik: \"Akhirnya kamu bangun.\"",
		"bg": "kelas", "dark": 0.65, "char": "ez"},
]

var _bg_front: TextureRect
var _bg_back: TextureRect
var _bg_tex: Texture2D = null
var _drifts := {}
var _dark: ColorRect
var _char: TextureRect
var _char_key := ""
var _char_tween: Tween
var _label: Label
var _hum: AudioStreamPlayer
var _hum_on := false
var _hum_tween: Tween
var _type_tween: Tween
var _index := 0
var _typing := false
var _can_input := false
var _done := false

func _ready() -> void:
	if bg_kelas == null:
		bg_kelas = _try_load(DEFAULT_KELAS)
	if bg_lorong == null:
		bg_lorong = _try_load(DEFAULT_LORONG)
	_build()
	_show_slide(0)
	await get_tree().create_timer(0.6).timeout    # cegah klik ganda dari menu utama
	_can_input = true

func _try_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

# ---------------------------------------------------------------- UI

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE        # input lewat _unhandled_input

	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)

	_bg_front = _make_bg()
	_bg_back = _make_bg()

	_char = TextureRect.new()
	_char.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_char.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_char.size = CHAR_BOX
	_char.modulate.a = 0.0
	_char.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_char)

	_dark = ColorRect.new()
	_dark.color = Color(0, 0, 0, 0)
	_dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dark)

	var strip := ColorRect.new()
	strip.color = Color(0, 0, 0, 0.55)
	strip.position = Vector2(0, 860)
	strip.size = Vector2(SCREEN.x, 220)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)

	_label = Label.new()
	_label.position = Vector2(160, 885)
	_label.size = Vector2(1600, 170)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 44)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 8)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	var hint := Label.new()
	hint.text = "klik untuk lanjut"
	hint.position = Vector2(SCREEN.x - 360, 1035)
	hint.size = Vector2(320, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override("font_size", 22)
	hint.modulate.a = 0.3
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	var pulse := create_tween().set_loops()
	pulse.tween_property(hint, "modulate:a", 0.8, 0.9)
	pulse.tween_property(hint, "modulate:a", 0.3, 0.9)

	var skip := Button.new()
	skip.text = "Lewati >>"
	skip.position = Vector2(SCREEN.x - 260, 32)
	skip.size = Vector2(220, 56)
	skip.focus_mode = Control.FOCUS_NONE
	skip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	skip.add_theme_font_size_override("font_size", 26)
	skip.add_theme_stylebox_override("normal", _style(Color(0, 0, 0, 0.5)))
	skip.add_theme_stylebox_override("hover", _style(Color(0.2, 0.2, 0.2, 0.7)))
	skip.add_theme_stylebox_override("pressed", _style(Color(0.3, 0.3, 0.3, 0.8)))
	skip.pressed.connect(_finish)
	add_child(skip)

	_hum = AudioStreamPlayer.new()
	if ResourceLoader.exists(HUM_PATH):
		_hum.stream = load(HUM_PATH)
		if _hum.stream is AudioStreamMP3:
			(_hum.stream as AudioStreamMP3).loop = true
	add_child(_hum)

func _make_bg() -> TextureRect:
	var r := TextureRect.new()
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.pivot_offset = SCREEN / 2.0
	r.modulate.a = 0.0
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r

func _style(color: Color) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = color
	st.set_border_width_all(2)
	st.border_color = Color(0.85, 0.85, 0.85, 0.8)
	st.set_corner_radius_all(6)
	return st

# ---------------------------------------------------------------- alur

func _unhandled_input(event: InputEvent) -> void:
	if _done or not _can_input:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_advance()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_finish()
	elif event.is_action_pressed("ui_accept"):
		_advance()

func _advance() -> void:
	if _typing:                                   # klik saat mengetik = tampilkan semua
		if _type_tween:
			_type_tween.kill()
		_label.visible_ratio = 1.0
		_typing = false
		return
	_index += 1
	if _index >= SLIDES.size():
		_finish()
	else:
		_show_slide(_index)

func _show_slide(i: int) -> void:
	var s: Dictionary = SLIDES[i]
	_set_bg(_bg_for(s.get("bg", "")))
	create_tween().tween_property(_dark, "color:a", float(s.get("dark", 0.0)), 1.5)
	_set_char(s.get("char", ""))
	_set_hum(s.get("hum", _hum_on))

	var text: String = s["text"]
	_label.text = text
	_label.visible_ratio = 0.0
	_typing = true
	if _type_tween:
		_type_tween.kill()
	_type_tween = create_tween()
	_type_tween.tween_property(_label, "visible_ratio", 1.0, maxf(0.6, text.length() * 0.04))
	_type_tween.finished.connect(func(): _typing = false)

func _finish() -> void:
	if _done:
		return
	_done = true
	if _hum.playing:
		create_tween().tween_property(_hum, "volume_db", -60.0, 0.4)
	SceneManager.go_to(next_scene)

# ---------------------------------------------------------------- efek

func _bg_for(key: String) -> Texture2D:
	match key:
		"kelas":
			return bg_kelas
		"lorong":
			return bg_lorong
	return null

# Pindah latar dengan crossfade + zoom sangat pelan (Ken Burns).
func _set_bg(tex: Texture2D) -> void:
	if tex == _bg_tex:
		return
	_bg_tex = tex
	if tex == null:                               # kembali ke layar hitam
		create_tween().tween_property(_bg_front, "modulate:a", 0.0, 0.8)
		return
	var incoming := _bg_back
	incoming.texture = tex
	incoming.modulate.a = 0.0
	move_child(incoming, 2)                       # tepat di atas latar lama, di bawah karakter
	create_tween().tween_property(incoming, "modulate:a", 1.0, 0.8)
	_bg_back = _bg_front
	_bg_front = incoming
	_drift(incoming)

func _drift(rect: TextureRect) -> void:
	if _drifts.has(rect):
		_drifts[rect].kill()
	rect.scale = Vector2.ONE
	var t := create_tween()
	t.tween_property(rect, "scale", Vector2(1.08, 1.08), 40.0)
	_drifts[rect] = t

func _set_char(key: String) -> void:
	if key == _char_key:
		return
	_char_key = key
	if _char_tween:
		_char_tween.kill()
	_char_tween = create_tween()
	_char_tween.tween_property(_char, "modulate:a", 0.0, 0.3)

	var tex: Texture2D = null
	var on_left := true
	var tint := Color.WHITE
	match key:
		"karani":
			tex = karani
			on_left = true
			tint = Color(0.9, 0.9, 0.95)
		"ez":
			tex = ez
			on_left = false
			tint = Color(0.55, 0.55, 0.65)         # gelap, nyaris siluet
	if tex == null:                               # tidak ada gambar: karakter hanya menghilang
		return
	_char_tween.tween_callback(func():
		_char.texture = tex
		_char.position = Vector2(
				80.0 if on_left else SCREEN.x - 80.0 - CHAR_BOX.x, CHAR_TOP)
		_char.modulate = Color(tint.r, tint.g, tint.b, 0.0))
	_char_tween.tween_property(_char, "modulate:a", 1.0, 1.0)

func _set_hum(on: bool) -> void:
	if on == _hum_on:
		return
	_hum_on = on
	if _hum.stream == null:
		return
	if _hum_tween:
		_hum_tween.kill()
	_hum_tween = create_tween()
	if on:
		_hum.volume_db = -40.0
		_hum.play()
		_hum_tween.tween_property(_hum, "volume_db", HUM_DB, 1.5)
	else:
		_hum_tween.tween_property(_hum, "volume_db", -60.0, 1.0)
		_hum_tween.tween_callback(_hum.stop)
