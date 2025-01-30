extends CharacterBody2D

class_name BaseBug

@export var base_health: float = 50
@export var base_speed: float = 100
@export var credit_reward: int = 25
@export var day_number: int = 1

var current_health: float
var current_speed: float
var special_ability: String = "None"
var target_position: Vector2
var has_reached_base: bool = false

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

signal bug_died(credits: int)
signal reached_base

func _ready():
	print("Bug spawned at: ", global_position)
	# Calculate health with day scaling (5% increase per day)
	current_health = base_health * pow(1.05, day_number - 1)
	current_speed = base_speed
	
	# Update health bar
	if has_node("HealthBar"):
		$HealthBar.max_value = current_health
		$HealthBar.value = current_health
	
	# Setup navigation with more debug info
	print("Setting up navigation for bug")
	nav_agent.path_desired_distance = 4.0  # Reduced back to default
	nav_agent.target_desired_distance = 4.0  # Reduced back to default
	nav_agent.radius = 16.0  # Add this line
	nav_agent.neighbor_distance = 100.0  # Add this line
	nav_agent.max_neighbors = 10  # Add this line
	nav_agent.time_horizon = 1.0  # Add this line
	nav_agent.max_speed = base_speed
	nav_agent.avoidance_enabled = true

	# IMPORTANT: Wait for the navigation to be ready
	await get_tree().create_timer(0.1).timeout  # Add small delay
	#nav_agent.debug_enabled = true

func _physics_process(delta):
	if has_reached_base:
		return
	
	# Don't check navigation_finished immediately
	var next_position: Vector2 = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)
	
	# Only move if we have a valid direction
	if direction != Vector2.ZERO:
		velocity = direction * current_speed
		move_and_slide()
		
		# Update rotation to face movement direction
		rotation = velocity.angle()
		
		# Debug info
		print("Moving - Position: ", global_position, " Next: ", next_position, " Dir: ", direction)
	else:
		print("No valid direction found")
	
	# Only mark as reached if we're very close to target
	if global_position.distance_to(target_position) < 20:
		if not has_reached_base:
			print("Bug reached destination naturally")
			has_reached_base = true
			emit_signal("reached_base")

func set_target(target: Vector2) -> void:
	print("Setting target for bug: ", target)
	if target == global_position:
		print("Warning: Target is same as current position!")
		return
		
	target_position = target
	# Force navigation recalculation
	nav_agent.target_position = target_position
	# Wait a frame and verify path
	await get_tree().physics_frame
	print("Path to target exists: ", nav_agent.is_target_reachable())
	print("Distance to target: ", nav_agent.distance_to_target())
func take_damage(amount: float) -> void:
	current_health -= amount
	if current_health <= 0:
		die()

func die() -> void:
	if not is_queued_for_deletion():
		emit_signal("bug_died", credit_reward)
		queue_free()

func get_health_percentage() -> float:
	return current_health / (base_health * pow(1.05, day_number - 1)) * 100
