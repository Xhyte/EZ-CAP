extends CanvasLayer

@export var start_on := false      # false = awalnya gelap total, pemain harus nyalakan
@export var radius := 220.0
@export var fade_time := 0.15

@onready var dark: ColorRect = $Dark

var is_on := false
var _tween: Tween

func _ready() -> void:
	var mat := dark.material as ShaderMaterial
	mat.set_shader_parameter("radius", radius)
	_set_on(start_on, true)

func _process(_delta: float) -> void:
	var mat := dark.material as ShaderMaterial
	mat.set_shader_parameter("mouse_pos", dark.get_local_mouse_position())
	mat.set_shader_parameter("rect_size", dark.size)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Lights"):
		_set_on(not is_on)

func _set_on(value: bool, instant := false) -> void:
	is_on = value
	var mat := dark.material as ShaderMaterial
	var target := 1.0 if is_on else 0.0
	if instant:
		mat.set_shader_parameter("intensity", target)
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(
		func(v): mat.set_shader_parameter("intensity", v),
		mat.get_shader_parameter("intensity"), target, fade_time)

# Untuk dipakai nanti (cek apakah suatu titik sedang tersorot)
func is_lit(screen_pos: Vector2) -> bool:
	return is_on and screen_pos.distance_to(dark.get_local_mouse_position()) < radius
