extends CharacterBody2D

@export var SPEED: float = 400.0
@export var ACCELERATION: float = 1500.0
@export var FRICTION: float = 1000.0
@export var ROTATION_SPEED: float = 10.0  # Controls how quickly the sprite rotates

func get_input(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * SPEED, ACCELERATION * delta)
		# Calculate the target rotation based on input direction
		var target_rotation = input_direction.angle()
		# Smoothly rotate towards the target rotation
		rotation = lerp_angle(rotation, target_rotation, ROTATION_SPEED * delta)
	else:
		# Apply friction when no input
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
func _physics_process(delta):
	get_input(delta)
	move_and_slide()
