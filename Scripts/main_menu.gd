extends Control

@export_file("*.tscn") var start_scene := "res://Scene/Ui/prolog.tscn"

@onready var btn_start: Button = $Center/Buttons/Mulai
@onready var btn_settings: Button = $Center/Buttons/Pengaturan
@onready var btn_quit: Button = $Center/Buttons/Keluar

var settings: SettingsPanel

func _ready() -> void:
	get_tree().paused = false
	GameState.reset()

	settings = SettingsPanel.new()
	settings.visible = false
	settings.closed.connect(func(): settings.visible = false)
	add_child(settings)

	btn_start.pressed.connect(func(): SceneManager.go_to(start_scene))
	btn_settings.pressed.connect(func(): settings.visible = true)
	btn_quit.pressed.connect(func(): get_tree().quit())
