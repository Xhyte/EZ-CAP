extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	GameState.selesaikan_stage(1)
	text = "Stage 1 selesai"
