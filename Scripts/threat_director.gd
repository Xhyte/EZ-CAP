extends Node
# Langkah mendekat -> ketukan -> pemain harus sembunyi dalam react_time.

@export var min_wait := 40.0
@export var max_wait := 70.0
@export var steps_time := 2.0        # jeda antara langkah dan ketukan
@export var react_time := 5.0        # waktu sembunyi setelah ketukan
@export var steps_sound: AudioStream = preload("res://Sound/Monster Footsteps 3.mp3")
@export var knock_sound: AudioStream = preload("res://Sound/knock door.mp3")

var steps := AudioStreamPlayer.new()
var knock := AudioStreamPlayer.new()
var wait_timer := Timer.new()
var knock_timer := Timer.new()
var react_timer := Timer.new()

func _ready() -> void:
	GameState.threat_active = false
	steps.stream = steps_sound
	knock.stream = knock_sound
	add_child(steps)
	add_child(knock)
	for t in [wait_timer, knock_timer, react_timer]:
		t.one_shot = true
		add_child(t)
	wait_timer.timeout.connect(_approach)
	knock_timer.timeout.connect(_knock)
	react_timer.timeout.connect(_caught)
	GameState.calm_changed.connect(_on_calm_changed)
	_schedule()

func _light():
	return get_tree().get_first_node_in_group("flicker_light")

func _schedule() -> void:
	wait_timer.start(randf_range(min_wait, max_wait))

func _approach() -> void:
	if GameState.is_calm() or SceneManager.busy:   # dialog/pindah scene: tunda
		_schedule()
		return
	GameState.threat_active = true
	var l = _light()
	if l:
		l.flicker_for(steps_time)
	if steps.stream:
		steps.play()
	get_parent().show_message("Ada langkah kaki mendekat...")
	knock_timer.start(steps_time)

func _knock() -> void:
	if SceneManager.busy:
		return
	var l = _light()
	if l:
		l.blackout()
	steps.stop()
	if knock.stream:
		knock.play()
	get_parent().show_message("Tok... tok... Sembunyi!")
	react_timer.start(react_time)

func _caught() -> void:
	if SceneManager.busy:            # pemain sedang pindah (mis. ke loker): lolos
		return
	GameState.threat_active = false
	var l = _light()
	if l:
		l.hide_dark()
	await Jumpscare.play()
	if l:
		l.dark.visible = true
		l.restore()
	GameState.lose_sanity(25)
	_schedule()
	
# Kalau dialog/puzzle dibuka di tengah ancaman, ancamannya dibatalkan.
func _on_calm_changed(on: bool) -> void:
	if not on:
		return
	if knock_timer.is_stopped() and react_timer.is_stopped():
		return                       # tidak ada ancaman yang sedang berjalan
	knock_timer.stop()
	react_timer.stop()
	steps.stop()
	GameState.threat_active = false
	var l = _light()
	if l:
		l.restore()
	_schedule()
