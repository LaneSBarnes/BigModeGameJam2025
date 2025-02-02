extends CharacterBody2D

@export var SPEED: float = 400.0
@export var ACCELERATION: float = 1500.0
@export var FRICTION: float = 1000.0

func get_input(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * SPEED, ACCELERATION * delta)
	else:
		# Apply friction when no input
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
func _physics_process(delta):
	get_input(delta)
	move_and_slide()
