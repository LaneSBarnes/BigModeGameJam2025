extends CharacterBody2D

@export var speed: float = 100.0
@export var path_follow_distance: float = 5.0

var current_path: Array = []
var current_path_index: int = 0
var spawn_point: Node2D
var base_target: Node2D

func initialize(spawn: Node2D, base: Node2D):
	spawn_point = spawn
	base_target = base
	global_position = spawn.global_position
	
	# Get the navigation path if it exists
	var path_node = spawn.get_node_or_null("Path")
	if path_node and path_node.has_method("get_global_path"):
		current_path = path_node.get_global_path()
		current_path.append(base.global_position)  # Add base as final destination
	else:
		# Fallback: direct path to base
		current_path = [global_position, base.global_position]
	
	current_path_index = 0

func _physics_process(delta):
	if current_path.size() == 0:
		return
		
	# Get current target point
	var target = current_path[current_path_index]
	
	# Calculate direction to target
	var direction = global_position.direction_to(target)
	
	# Move towards target
	velocity = direction * speed
	move_and_slide()
	
	# Check if we've reached the current point
	if global_position.distance_to(target) < path_follow_distance:
		current_path_index += 1
		if current_path_index >= current_path.size():
			# Reached the end of the path (the base)
			current_path_index = current_path.size() - 1
			# You might want to implement base damage here
			
	# Optional: Update sprite/animation based on movement
	if velocity != Vector2.ZERO:
		# Assuming the sprite is pointing right by default
		rotation = velocity.angle()

# Optional: Add visual debugging of path
func _draw():
	if current_path.size() > 1:
		for i in range(current_path.size() - 1):
			var start = to_local(current_path[i])
			var end = to_local(current_path[i + 1])
			draw_line(start, end, Color.RED, 2.0)
		
		# Draw current target point
		if current_path_index < current_path.size():
			var target = to_local(current_path[current_path_index])
			draw_circle(target, 5.0, Color.YELLOW)