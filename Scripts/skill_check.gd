extends Control
# Skill check melingkar ala Dead by Daylight.
# Jarum berputar searah jarum jam dari jam 12. Tekan Space (atau klik kiri)
# saat jarum berada di zona putih. Telat atau salah = gagal.

signal finished(success: bool)

@export var duration := 1.4          # detik untuk satu putaran penuh
@export var zone_degrees := 40.0     # lebar zona sukses (derajat)
@export var ring_radius := 110.0

var active := false
var progress := 0.0                  # 0..1 putaran
var zone_start := 0.0                # posisi awal zona, 0..1 putaran

func _ready() -> void:
	visible = false

func start() -> void:
	zone_start = randf_range(0.30, 0.85)   # zona acak, tidak terlalu dekat awal
	progress = 0.0
	active = true
	visible = true
	queue_redraw()

func _process(delta: float) -> void:
	if not active:
		return
	progress += delta / duration
	if progress >= 1.0:
		_resolve(false)              # telat / tidak menekan
		return
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not active:
		return
	var pressed := false
	if event.is_action_pressed("ui_accept"):
		pressed = true
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		pressed = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if pressed:
		get_viewport().set_input_as_handled()
		var zone_w := zone_degrees / 360.0
		_resolve(progress >= zone_start and progress <= zone_start + zone_w)

func _resolve(success: bool) -> void:
	active = false
	visible = false
	finished.emit(success)

func _draw() -> void:
	if not active:
		return
	var c := size / 2.0
	var start_a := -PI / 2.0                       # jam 12
	var zone_a0 := start_a + zone_start * TAU
	var zone_a1 := zone_a0 + deg_to_rad(zone_degrees)
	draw_circle(c, ring_radius + 24.0, Color(0, 0, 0, 0.55))
	draw_arc(c, ring_radius, 0.0, TAU, 96, Color(0.85, 0.85, 0.85), 4.0, true)
	draw_arc(c, ring_radius, zone_a0, zone_a1, 24, Color.WHITE, 14.0, true)
	var na := start_a + progress * TAU
	draw_line(c, c + Vector2(cos(na), sin(na)) * (ring_radius + 10.0), Color(0.9, 0.1, 0.1), 4.0, true)
	draw_string(ThemeDB.fallback_font, Vector2(0.0, c.y + 10.0), "SPACE",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, Color.WHITE)
