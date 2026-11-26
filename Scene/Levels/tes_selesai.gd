extends Button

@export var stage_manual := 0   # 0 = otomatis dari nama scene

func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()            # hilang otomatis di build rilis
		return
	text = "TES: selesaikan stage %d" % _stage()

func _stage() -> int:
	if stage_manual > 0:
		return stage_manual
	var nama := get_tree().current_scene.scene_file_path.get_file().get_basename()
	return nama.get_slice("_", 1).to_int() - 200

func _pressed() -> void:
	GameState.selesaikan_stage(_stage())
	get_parent().show_message("Stage %d selesai (tes)." % _stage())
