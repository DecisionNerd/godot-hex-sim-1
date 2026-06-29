extends Control


func _ready() -> void:
	if not $Center/VBox/BackBtn.pressed.is_connected(_on_back):
		$Center/VBox/BackBtn.pressed.connect(_on_back)


func _on_back() -> void:
	SceneRouter.go_to_start()
