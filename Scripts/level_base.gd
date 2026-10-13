extends Control

@onready var message_label: Label = $MessageLabel
var _tween: Tween

func _ready() -> void:
	message_label.modulate.a = 0.0
	# _ready anak dijalankan lebih dulu, jadi semua hotspot sudah terdaftar
	for h in get_tree().get_nodes_in_group("hotspots"):
		h.message_requested.connect(show_message)

func show_message(text: String) -> void:
	if _tween:
		_tween.kill()
	message_label.text = text
	message_label.modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_interval(1.5)
	_tween.tween_property(message_label, "modulate:a", 0.0, 0.5)
