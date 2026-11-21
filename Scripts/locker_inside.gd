extends "res://Scripts/level_base.gd"
# Scene di dalam loker: pintu sedikit terbuka, pemain harus lolos skill check
# saat ancaman hantu muncul.

@export var warning_time := 3.0      # jeda tanda bahaya sebelum skill check
@export var checks_needed := 1       # jumlah skill check beruntun (belum final)

@onready var skill_check = $SkillCheck
@onready var exit_slit = $ExitSlit

var threat_running := false

# PEMICU SEMENTARA UNTUK PENGUJIAN: tekan T.
# Nanti diganti pemicu asli dari event hantu.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T:
		start_threat()

func start_threat() -> void:
	if threat_running:
		return
	threat_running = true
	_lock_exit(true)
	show_message("Ada sesuatu di luar... jangan bergerak.")
	await get_tree().create_timer(warning_time).timeout

	for _i in checks_needed:
		skill_check.start()
		var ok: bool = await skill_check.finished
		if not ok:
			_on_failed()
			return
		await get_tree().create_timer(0.6).timeout
	_on_survived()

func _on_survived() -> void:
	show_message("Ancaman sudah lewat...")
	_lock_exit(false)
	threat_running = false

func _on_failed() -> void:
	# TODO: konsekuensi gagal BELUM diputuskan tim (sanity? game over? jumpscare?)
	print("Skill check GAGAL")
	show_message("Ketahuan!")
	_lock_exit(false)
	threat_running = false

func _lock_exit(on: bool) -> void:
	exit_slit.locked = on
	exit_slit.locked_text = "Jangan bergerak..."
