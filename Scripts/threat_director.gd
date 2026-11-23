extends Node
# Pasang sebagai node anak di root tiap kelas.

@export var min_wait := 40.0
@export var max_wait := 70.0
@export var react_time := 5.0

var wait_timer := Timer.new()
var react_timer := Timer.new()

func _ready() -> void:
	GameState.threat_active = false
	for t in [wait_timer, react_timer]:
		t.one_shot = true
		add_child(t)
	wait_timer.timeout.connect(_warn)
	react_timer.timeout.connect(_caught)
	_schedule()

func _schedule() -> void:
	wait_timer.start(randf_range(min_wait, max_wait))

func _warn() -> void:
	GameState.threat_active = true
	get_parent().show_message("Terdengar langkah... bersembunyi!")
	react_timer.start(react_time)

func _caught() -> void:
	GameState.threat_active = false
	get_parent().show_message("Mbah Yan menemukanmu!")
	GameState.lose_sanity(25)
	_schedule()
