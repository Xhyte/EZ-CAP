extends CanvasLayer

@onready var image: Control = $Image
@onready var scream = $Scream

func _ready() -> void:
	image.visible = false

func play(duration := 1.0) -> void:
	image.pivot_offset = image.size / 2.0
	image.scale = Vector2(1.1, 1.1)     # diperbesar agar tepi tidak terlihat saat bergetar
	image.visible = true
	if scream.stream:
		scream.play()
	var start := image.position
	var t := create_tween()
	for i in 8:
		var offset := Vector2(randf_range(-25, 25), randf_range(-25, 25))
		t.tween_property(image, "position", start + offset, duration / 8.0)
	await t.finished
	image.position = start
	image.visible = false
