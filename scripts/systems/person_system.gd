extends RefCounted

const Person = preload("res://scripts/entities/person.gd")
const PlotState = preload("res://scripts/farming/plot_state.gd")


func resolve_day(persons: Array, rng: RandomNumberGenerator, game_state: Object) -> void:
	var sorted: Array = persons.duplicate()
	sorted.sort_custom(func(a: Person, b: Person) -> bool:
		return a.id < b.id
	)
	for person in sorted:
		var action: String = person.roll_action(rng)
		match action:
			"tend":
				_resolve_tend(person, rng, game_state)
			"idle":
				pass


func _resolve_tend(person: Person, rng: RandomNumberGenerator, game_state: Object) -> void:
	var candidates := _plots_needing_tend(game_state)
	if candidates.is_empty():
		return
	var coords: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
	_tend_plot(game_state, coords)
	game_state.player_message("%s tended the crops." % person.display_name)


func _plots_needing_tend(game_state: Object) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for coords in game_state.plots:
		var plot: PlotState = game_state.plots[coords]
		if plot.is_empty():
			continue
		var crop = game_state.get_crop(plot.crop_id)
		if plot.tended or plot.is_mature(crop):
			continue
		if game_state.weather == game_state.Weather.DROUGHT:
			out.append(coords)
		elif game_state.weather == game_state.Weather.FROST and not crop.frost_tolerant:
			out.append(coords)
	return out


func _tend_plot(game_state: Object, coords: Vector2i) -> void:
	var plot: PlotState = game_state.get_plot(coords)
	if plot == null or plot.is_empty():
		return
	plot.tended = true
	game_state.plot_changed.emit(coords)
