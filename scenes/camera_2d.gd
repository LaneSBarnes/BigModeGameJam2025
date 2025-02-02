extends Camera2D

@export var zoom_min = Vector2(0.25,0.25)
@export var zoom_max = Vector2(2,2)
@export var camera_follow_speed = 0.025

func _process(delta):
	position = position.lerp(%Player.position, camera_follow_speed)

func _input(event: InputEvent) -> void:
	var zoomTest = zoom
	if event.is_action_released("zoom in") && zoom < zoom_max:
		zoom = lerp(zoom, zoom + Vector2(0.1,0.1), 0.5)
	if event.is_action_released("zoom out") && zoom > zoom_min:
		zoom = lerp(zoom, zoom - Vector2(0.1,0.1), 0.5)
