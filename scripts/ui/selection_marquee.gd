extends Control

var marquee_rect := Rect2()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_marquee(from_screen: Vector2, to_screen: Vector2) -> void:
	marquee_rect = Rect2(from_screen, to_screen - from_screen)
	queue_redraw()


func clear_marquee() -> void:
	marquee_rect = Rect2()
	queue_redraw()


func _draw() -> void:
	if marquee_rect.size.length_squared() < 4.0:
		return
	var rect := marquee_rect
	var pos := rect.position
	var size := rect.size
	if size.x < 0.0:
		pos.x += size.x
		size.x = absf(size.x)
	if size.y < 0.0:
		pos.y += size.y
		size.y = absf(size.y)
	draw_rect(Rect2(pos, size), Color(1.0, 0.92, 0.45, 0.18), true)
	draw_rect(Rect2(pos, size), Color(1.0, 0.92, 0.45, 0.9), false, 2.0)
