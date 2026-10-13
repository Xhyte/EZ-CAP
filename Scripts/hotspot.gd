extends Control

signal message_requested(text: String)

@export_file("*.tscn") var target_scene := ""     # scene tujuan (kosongkan jika bukan pintu)
@export var locked := false                       # pintu terkunci?
@export var locked_text := "Pintu ini terkunci."
@export var message := ""                         # teks jika objek biasa diklik

@onready var highlight: ColorRect = $Highlight

func _ready() -> void:
	add_to_group("hotspots")
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	highlight.modulate.a = 0.0
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))

func _on_hover(on: bool) -> void:
	print("hover: ", name, " ", on, " | highlight size: ", highlight.size)
	var t := create_tween()
	t.tween_property(highlight, "modulate:a", 1.0 if on else 0.0, 0.15)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if locked:
			message_requested.emit(locked_text)
		elif target_scene != "":
			SceneManager.go_to(target_scene)
		elif message != "":
			message_requested.emit(message)
