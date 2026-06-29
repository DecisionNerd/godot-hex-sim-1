extends Control


func _ready() -> void:
	$Center/VBox/BackBtn.pressed.connect(_on_back)


func _on_back() -> void:
	SceneRouter.go_to_start()
