extends Node

signal sanity_changed(value: int)
signal memory_changed(value: int)
signal calm_changed(on: bool)    # true = mode tenang (dialog/puzzle)

const MAX_SANITY := 100
const MAX_MEMORY := 10

var sanity := MAX_SANITY
var memory := MAX_MEMORY
var camera_mode := false
var skillcheck_active := false
var previous_scene := ""     # scene sebelumnya, dipakai untuk keluar dari loker
var threat_active := false
var stage_selesai := 0
var _calm := 0    # penghitung, supaya dialog dan puzzle bisa bersamaan

func selesaikan_stage(nomor: int) -> void:
	stage_selesai = max(stage_selesai, nomor)
	
func calm_begin() -> void:
	_calm += 1
	if _calm == 1:
		calm_changed.emit(true)

func calm_end() -> void:
	if _calm == 0:
		return
	_calm -= 1
	if _calm == 0:
		calm_changed.emit(false)

func is_calm() -> bool:
	return _calm > 0

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

func reset() -> void:
	sanity = 100
	stage_selesai = 0
	threat_active = false
	skillcheck_active = false
	previous_scene = ""
	_calm = 0
