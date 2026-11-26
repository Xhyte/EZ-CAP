extends "res://Scripts/level_base.gd"
# Loker: langkah mendekat -> Mbah Yan mengintip + QTE -> langkah menjauh.

@export var approach_time := 4.0     # lama suara langkah mendekat
@export var leave_time := 3.0        # lama suara langkah menjauh
@export var checks_needed := 1
@export var eye_top := -300.0         # posisi y mata saat mulai mengintip
@export var eye_bottom := 1500.0      # posisi y mata saat selesai
@export var eye_extra_time := 6   # tambahan waktu mata turun
@onready var skill_check = $Skillcheck
@onready var exit_slit = $ExitSlit
@onready var eye: Control = $Eye
@onready var footsteps = $Footsteps
@export var door_sound: AudioStream = preload("res://Sound/smashing-door.mp3")
@export var door_delay := 1.0        # jeda setelah pintu terbuka sebelum langkah terdengar

var door_player := AudioStreamPlayer.new()

var threat_running := false

func _ready() -> void:
	super._ready()
	door_player.stream = door_sound
	add_child(door_player)
	eye.visible = false
	if GameState.threat_active:
		GameState.threat_active = false
		start_threat()
	else:
		show_message("Tidak ada siapa-siapa. Aman.")

# Jalan pintas untuk menguji: tekan T.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T:
		start_threat()

func start_threat() -> void:
	if threat_running:
		return
	threat_running = true
	_lock_exit(true)
	
	# 0. Dia membuka pintu kelas
	show_message("Pintu terbuka... dia masuk.")
	await get_tree().create_timer(1.0).timeout     # <- baru: jeda sebelum suara pintu
	if door_player.stream:
		door_player.play()
	await get_tree().create_timer(door_delay).timeout

	show_message("Langkah mendekat... jangan bergerak.")

	# 1. Langkah makin dekat
	if footsteps.stream:
		footsteps.volume_db = -40.0
		footsteps.play()
		create_tween().tween_property(footsteps, "volume_db", 0.0, approach_time)
	await get_tree().create_timer(approach_time).timeout

	# 2. Mengintip + QTE
	var survived := true
	eye.position.y = eye_top
	eye.visible = true
	var scan := create_tween()
	scan.tween_property(eye, "position:y", eye_bottom,
		checks_needed * (skill_check.duration + eye_extra_time))
	for _i in checks_needed:
		skill_check.start()
		var ok: bool = await skill_check.finished
		if not ok:
			survived = false
			break
		await get_tree().create_timer(6).timeout
	scan.kill()

	eye.visible = false
	if not survived:
		await Jumpscare.play()
		GameState.lose_sanity(25)
		if GameState.sanity <= 0:
			return

	# 3. Langkah menjauh, baru boleh keluar
	show_message("Langkah menjauh...")
	if footsteps.stream:
		create_tween().tween_property(footsteps, "volume_db", -40.0, leave_time)
	await get_tree().create_timer(leave_time).timeout
	footsteps.stop()
	show_message("Sudah aman.")
	_lock_exit(false)
	threat_running = false

func _lock_exit(on: bool) -> void:
	exit_slit.locked = on
	exit_slit.locked_text = "Jangan bergerak..."
