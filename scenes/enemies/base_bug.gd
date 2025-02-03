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
@onready var sprite: Sprite2D = $Sprite2D

signal bug_died(credits: int)
signal reached_base

func _ready():

	
	# Wait for navigation to be ready
	await get_tree().create_timer(0.5).timeout
	
	# Debug navigation setup
	var navigation_map = get_world_2d().get_navigation_map()
	

	
	# Check if we can find NavigationRegion2D in the scene
	var nav_regions = get_tree().get_nodes_in_group("navigation_regions")
	if nav_regions.is_empty():
		# Try to find any NavigationRegion2D nodes, even if not in group
		var all_nav_regions = get_tree().get_nodes_in_group("navigation_polygon_source_geometry_group")
		if not all_nav_regions.is_empty():
			for region in all_nav_regions:
				# Add it to the navigation_regions group
				region.add_to_group("navigation_regions")
	

	# Calculate health with day scaling (5% increase per day)
	current_health = base_health * pow(1.05, day_number - 1)
	current_speed = base_speed
	
	# Wait a short moment for navigation to be ready
	await get_tree().create_timer(0.2).timeout
	
	# Update health bar
	if has_node("HealthBar"):
		$HealthBar.max_value = current_health
		$HealthBar.value = current_health
	
	# Setup navigation with more debug info
	print("Setting up navigation for bug")
	nav_agent.path_desired_distance = 4.0  # Reduced for tighter path following
	nav_agent.target_desired_distance = 4.0  # Reduced for tighter path following
	nav_agent.radius = 4.0  # Reduced for tighter navigation
	nav_agent.neighbor_distance = 50.0  # Reduced for more individual movement
	nav_agent.max_neighbors = 5  # Reduced for more individual movement
	nav_agent.time_horizon = 1.0  # Reduced for more responsive movement
	nav_agent.avoidance_enabled = false  # Disable avoidance to follow path more closely
	nav_agent.debug_enabled = false  # Enable debug visualization to see the path
	nav_agent.max_speed = base_speed
	nav_agent.max_speed = base_speed
	nav_agent.avoidance_enabled = true

	# IMPORTANT: Wait for the navigation to be ready
	await get_tree().create_timer(0.1).timeout  # Add small delay

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
		
# Only rotate the sprite to face movement direction
	if has_node("Sprite2D"):
		var sprite = get_node("Sprite2D")
		# Calculate the angle to the next position
		var angle = global_position.direction_to(next_position).angle()
		# Set the sprite's rotation
		sprite.rotation = angle
		
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
	var path = nav_agent.get_current_navigation_path()
	print("Navigation path points: ", path.size())
	if path.size() > 0:
		print("Path start: ", path[0])
		print("Path end: ", path[-1])
		# Print intermediate points if any
		if path.size() > 2:
			print("Waypoints: ", path.slice(1, -1))
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
