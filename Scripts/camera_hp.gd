extends CanvasLayer

signal photo_taken(pos: Vector2)

@onready var overlay: Control = $Overlay
@onready var flash: ColorRect = $Overlay/Flash
@onready var warning: Label = $Overlay/Warning
@onready var shutter: AudioStreamPlayer = $ShutterSound

func _ready() -> void:
	add_to_group("camera_hp")
	overlay.visible = false
	warning.visible = false
	flash.modulate.a = 0.0

func _process(_delta: float) -> void:
	if get_tree().paused or GameState.skillcheck_active:
		return    # saat skill check, input diurus oleh skill check

	if Input.is_action_just_pressed("camera_toggle"):
		_set_camera(not GameState.camera_mode)
	elif GameState.camera_mode and Input.is_action_just_pressed("photo"):
		take_photo()

func _set_camera(active: bool) -> void:
	print("Mode kamera: ", active)
	GameState.camera_mode = active
	overlay.visible = active
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE
	GameState.camera_toggled.emit(active)

func take_photo() -> bool:
	if not GameState.use_memory():
		_show_warning()
		return false
	shutter.play()
	flash.modulate.a = 1.0
	create_tween().tween_property(flash, "modulate:a", 0.0, 0.25)
	photo_taken.emit(get_viewport().get_mouse_position())
	return true

func _show_warning() -> void:
	warning.visible = true
	await get_tree().create_timer(1.2).timeout
	warning.visible = false
