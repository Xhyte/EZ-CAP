extends CanvasLayer

@onready var fade: ColorRect = $Fade
var busy := false
var sfx := AudioStreamPlayer.new()     # pemutar suara transisi (mis. pintu)

func _ready() -> void:
	add_child(sfx)

# hold  = lama layar tetap hitam sebelum pindah scene
# sound = suara yang diputar saat transisi dimulai (boleh kosong)
func go_to(path: String, duration := 0.4, hold := 0.0, sound: AudioStream = null) -> void:
	if busy:
		return                       # cegah klik ganda saat transisi
	busy = true
	fade.mouse_filter = Control.MOUSE_FILTER_STOP

	if sound:
		sfx.stream = sound
		sfx.play()

	var t := create_tween()
	t.tween_property(fade, "modulate:a", 1.0, duration)
	await t.finished

	if hold > 0.0:
		await get_tree().create_timer(hold).timeout

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame

	var t2 := create_tween()
	t2.tween_property(fade, "modulate:a", 0.0, duration)
	await t2.finished

	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false
