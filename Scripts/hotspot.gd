extends Control

signal message_requested(text: String)

@export_file("*.tscn") var target_scene := ""     # scene tujuan (kosongkan jika bukan pintu)
@export var go_back := false                      # true = kembali ke scene sebelumnya (keluar loker)
@export var locked := false                       # terkunci?
@export var locked_text := "Pintu ini terkunci."
@export var message := ""                         # teks jika objek biasa diklik
@export var butuh_stage := 0
@onready var highlight: CanvasItem = $Highlight

func _ready() -> void:
	add_to_group("hotspots")
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	highlight.modulate.a = 0.0
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))

func _on_hover(on: bool) -> void:
	create_tween().tween_property(highlight, "modulate:a", 1.0 if on else 0.0, 0.15)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if locked or GameState.stage_selesai < butuh_stage:
			message_requested.emit(locked_text)
		elif go_back:
			_go(GameState.previous_scene)
		elif target_scene != "":
			_go(target_scene)
		elif message != "":
			message_requested.emit(message)

func _go(dest: String) -> void:
	if dest == "":
		push_warning("Hotspot '%s': scene tujuan kosong." % name)
		return
	# catat scene saat ini agar bisa kembali (mis. keluar dari loker)
	GameState.previous_scene = get_tree().current_scene.scene_file_path
	SceneManager.go_to(dest)

func _has_point(point: Vector2) -> bool:
	var poly := get_node_or_null("Highlight") as Polygon2D
	if poly:
		return Geometry2D.is_point_in_polygon(point - poly.position, poly.polygon)
	return Rect2(Vector2.ZERO, size).has_point(point)
