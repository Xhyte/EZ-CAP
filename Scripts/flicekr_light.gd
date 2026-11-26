extends CanvasLayer

@export var min_wait := 4.0
@export var max_wait := 12.0
@export var base_darkness := 0.35
@export var flicker_darkness := 0.9
@export var flicker_count_min := 3
@export var flicker_count_max := 7

@onready var dark: ColorRect = $Dark
@onready var buzz = get_node_or_null("Buzz")

var override := false   # true = lagi dikendalikan ancaman, kedip acak berhenti

func _ready() -> void:
	add_to_group("flicker_light")
	dark.modulate.a = base_darkness
	_loop()

func _loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(min_wait, max_wait)).timeout
		if not is_inside_tree():
			return
		if not override:
			await _flicker()

func _flicker(n := -1) -> void:
	if buzz and buzz.stream:
		buzz.play()
	if n < 0:
		n = randi_range(flicker_count_min, flicker_count_max)
	for i in n:
		if override:
			return
		dark.modulate.a = randf_range(flicker_darkness - 0.2, flicker_darkness)
		await get_tree().create_timer(randf_range(0.03, 0.12)).timeout
		if override:
			return
		dark.modulate.a = randf_range(base_darkness - 0.1, base_darkness + 0.1)
		await get_tree().create_timer(randf_range(0.03, 0.15)).timeout
	if not override:
		dark.modulate.a = base_darkness

# Dipanggil dari luar:
func flicker_now() -> void:
	if override:
		return
	await _flicker(randi_range(6, 10))

func blackout(level := 0.92) -> void:
	override = true
	dark.modulate.a = level

func restore() -> void:
	override = false
	create_tween().tween_property(dark, "modulate:a", base_darkness, 0.4)

func hide_dark() -> void:
	override = true
	dark.visible = false
