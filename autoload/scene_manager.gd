extends CanvasLayer

@onready var fade: ColorRect = $Fade
var busy := false

func go_to(path: String, duration := 0.4) -> void:
	if busy:
		return                       # cegah klik ganda saat transisi
	busy = true
	fade.mouse_filter = Control.MOUSE_FILTER_STOP

	var t := create_tween()
	t.tween_property(fade, "modulate:a", 1.0, duration)
	await t.finished

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame

	var t2 := create_tween()
	t2.tween_property(fade, "modulate:a", 0.0, duration)
	await t2.finished

	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false
