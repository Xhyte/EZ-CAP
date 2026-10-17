extends Node

signal sanity_changed(value: int)
signal memory_changed(value: int)
signal camera_toggled(active: bool)

const MAX_SANITY := 100
const MAX_MEMORY := 10

var sanity := MAX_SANITY
var memory := MAX_MEMORY
var camera_mode := false
var skillcheck_active := false

func lose_sanity(amount: int) -> void:
	sanity = max(0, sanity - amount)
	sanity_changed.emit(sanity)
	print("Sanity: ", sanity)
	if sanity == 0:
		game_over()

func use_memory() -> bool:
	if memory <= 0:
		return false
	memory -= 1
	memory_changed.emit(memory)
	print("Memori: ", memory)
	return true

func game_over() -> void:
	print("GAME OVER")   # nanti diganti pindah ke scene game over
