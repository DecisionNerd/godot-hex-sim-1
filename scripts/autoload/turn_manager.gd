extends Node

signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)
signal action_consumed(actions_remaining: int)

enum Phase { PLAYER, RESOLUTION }

var turn_number: int = 1
var phase: Phase = Phase.PLAYER
var actions_remaining: int = 2
var actions_per_turn: int = 2


func _ready() -> void:
	_start_turn()


func end_turn() -> void:
	advance_days(1)


func skip_days(day_count: int) -> void:
	advance_days(day_count)


func advance_until_actionable(max_days: int = 364) -> void:
	if phase != Phase.PLAYER:
		return
	if has_actions() and GameState.has_actionable_work():
		GameState.player_message("Work waiting — use your actions today.")
		return
	GameState.begin_day_batch(1)
	var days := 0
	while days < max_days:
		turn_ended.emit(turn_number)
		turn_number += 1
		days += 1
		if GameState.has_actionable_work():
			break
	GameState._batch_stats["days"] = days
	if days == 0:
		GameState._batch_mode = false
	else:
		GameState.end_day_batch()
		if GameState.has_actionable_work():
			GameState.player_message("Stopped — the farm needs you.")
		elif days >= max_days:
			GameState.player_message("No urgent work this year — seasons may open planting later.")
	_start_turn()


func advance_days(day_count: int) -> void:
	if phase != Phase.PLAYER or day_count < 1:
		return
	if day_count > 1:
		GameState.begin_day_batch(day_count)
	for _i in day_count:
		turn_ended.emit(turn_number)
		turn_number += 1
	if day_count > 1:
		GameState.end_day_batch()
	_start_turn()


func consume_action() -> bool:
	if actions_remaining <= 0:
		return false
	actions_remaining -= 1
	action_consumed.emit(actions_remaining)
	return true


func has_actions() -> bool:
	return actions_remaining > 0


func _start_turn() -> void:
	phase = Phase.PLAYER
	actions_remaining = actions_per_turn
	turn_started.emit(turn_number)


func reset_for_test(turn: int = 1, actions: int = -1) -> void:
	turn_number = turn
	phase = Phase.PLAYER
	actions_remaining = actions if actions >= 0 else actions_per_turn


func begin_game_scene() -> void:
	# Autoload turn state survives scene changes; always open the day with labor.
	phase = Phase.PLAYER
	if actions_remaining <= 0:
		actions_remaining = actions_per_turn
	turn_started.emit(turn_number)
