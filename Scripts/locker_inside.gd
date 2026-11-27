extends "res://Scripts/level_base.gd"
# Loker: pintu terbuka -> langkah mendekat -> Mbah Yan berada di kelas beberapa detik
# (selama itu QTE berulang dengan jeda, mata turun pelan) -> langkah menjauh -> boleh keluar.

@export var approach_time := 4.0          # lama suara langkah mendekat
@export var presence_min := 10.0          # lama Mbah Yan berada di kelas (acak min..max)
@export var presence_max := 18.0
@export var qte_gap := 2.0                # jeda antar QTE
@export var leave_time := 3.0             # lama suara langkah menjauh
@export var eye_top := -300.0             # posisi y mata saat mulai mengintip
@export var eye_bottom := 1500.0          # posisi y mata saat Mbah Yan pergi
@export var door_sound: AudioStream = preload("res://Sound/smashing-door.mp3")
@export var door_delay := 1.0             # jeda setelah suara pintu sebelum langkah terdengar

@onready var skill_check = $Skillcheck
@onready var exit_slit = $ExitSlit
@onready var eye: Control = $Eye
@onready var footsteps = $Footsteps

var door_player := AudioStreamPlayer.new()
var threat_running := false
var presence_left := 0.0                  # sisa waktu Mbah Yan di kelas (detik)

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

# Waktu keberadaan Mbah Yan berkurang lewat _process, jadi ikut berhenti saat pause.
func _process(delta: float) -> void:
	if presence_left > 0.0:
		presence_left -= delta

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
	await _wait(1.0)
	if not is_inside_tree():
		return
	if door_player.stream:
		door_player.play()
	await _wait(door_delay)
	if not is_inside_tree():
		return

	show_message("Langkah mendekat... jangan bergerak.")

	# 1. Langkah makin dekat
	if footsteps.stream:
		footsteps.volume_db = -40.0
		footsteps.play()
		create_tween().tween_property(footsteps, "volume_db", 0.0, approach_time)
	await _wait(approach_time)
	if not is_inside_tree():
		return

	# 2. Mbah Yan ada di kelas: mata turun pelan, QTE berulang sampai waktunya habis
	presence_left = randf_range(presence_min, presence_max)
	eye.position.y = eye_top
	eye.visible = true
	var scan := create_tween()
	scan.tween_property(eye, "position:y", eye_bottom, presence_left)
	while presence_left > 0.0:
		skill_check.start()
		var ok: bool = await skill_check.finished
		if not is_inside_tree():
			return
		if not ok:
			await Jumpscare.play()
			if not is_inside_tree():
				return
			GameState.lose_sanity(25)
			if GameState.is_dead:
				return                        # layar game over yang mengambil alih
		await _wait(qte_gap)                  # jeda sebelum QTE berikutnya
		if not is_inside_tree():
			return
	scan.kill()
	eye.visible = false

	# 3. Langkah menjauh, baru boleh keluar
	show_message("Langkah menjauh...")
	if footsteps.stream:
		create_tween().tween_property(footsteps, "volume_db", -40.0, leave_time)
	await _wait(leave_time)
	if not is_inside_tree():
		return
	footsteps.stop()
	show_message("Sudah aman.")
	_lock_exit(false)
	threat_running = false

# Timer yang ikut berhenti saat game di-pause (create_timer biasa tidak).
func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout

func _lock_exit(on: bool) -> void:
	exit_slit.locked = on
	exit_slit.locked_text = "Jangan bergerak..."
