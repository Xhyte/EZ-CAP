extends Node
# Langkah mendekat -> ketukan -> pemain harus sembunyi dalam react_time.

@export var min_wait := 40.0
@export var max_wait := 70.0
@export var steps_time := 2.0        # jeda antara langkah dan ketukan
@export var react_time := 5.0        # waktu sembunyi setelah ketukan

@onready var steps = get_node_or_null("Steps")
@onready var knock = get_node_or_null("Knock")

var wait_timer := Timer.new()
var knock_timer := Timer.new()
var react_timer := Timer.new()

func _ready() -> void:
	GameState.threat_active = false
	for t in [wait_timer, knock_timer, react_timer]:
		t.one_shot = true
		add_child(t)
	wait_timer.timeout.connect(_approach)
	knock_timer.timeout.connect(_knock)
	react_timer.timeout.connect(_caught)
	_schedule()

func _light():
	return get_tree().get_first_node_in_group("flicker_light")

func _schedule() -> void:
	wait_timer.start(randf_range(min_wait, max_wait))

func _approach() -> void:
	GameState.threat_active = true
	var l = _light()
	if l:
		l.flicker_now()          # <- baru
	if steps and steps.stream:
		steps.play()
	get_parent().show_message("Ada langkah kaki mendekat...")
	knock_timer.start(steps_time)

func _knock() -> void:
	var l = _light()
	if l:
		l.blackout()             # <- baru
	if steps:
		steps.stop()
	if knock and knock.stream:
		knock.play()
	get_parent().show_message("Tok... tok... Sembunyi!")
	react_timer.start(react_time)

func _caught() -> void:
	GameState.threat_active = false
	await Jumpscare.play()
	var l = _light()
	if l:
		l.restore()              # <- baru
	GameState.lose_sanity(25)
	_schedule()
