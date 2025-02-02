extends Camera2D

@export var zoom_min = Vector2(0.25, 0.25)
@export var zoom_max = Vector2(2, 2)
@export var camera_follow_speed = 0.15 

@onready var player = get_node("%Player")

func _physics_process(delta):  
	if player:
		var target = player.global_position
		global_position = global_position.lerp(target, camera_follow_speed)

func _input(event: InputEvent) -> void:
	if event.is_action_released("zoom in") and zoom < zoom_max:
		zoom = lerp(zoom, zoom + Vector2(0.1, 0.1), 0.5)
	if event.is_action_released("zoom out") and zoom > zoom_min:
		zoom = lerp(zoom, zoom - Vector2(0.1, 0.1), 0.5)
