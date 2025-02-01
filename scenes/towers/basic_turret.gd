extends BaseTower

@export var damage: int = 10
@export var range: float = 4.0
@export var fire_rate: float = 1.0  # shots per second
@export var rotation_speed: float = 5.0  # radians per second

var time_since_last_shot: float = 0.0
var current_target: BaseBug = null
var projectile_scene = preload("res://scenes/projectiles/basic_projectile.tscn")

@onready var barrel = $Barrel
@onready var detection_area = $DetectionArea

# Store the default rotation
var default_rotation: float = 0.0

func _ready():
	cost = 100
	power_usage = 5  # per shot
	durability = 100
	
	# Setup detection area
	var area = Area2D.new()
	area.name = "DetectionArea"
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = range * 16  # Convert to pixels
	collision_shape.shape = circle_shape
	area.add_child(collision_shape)
	add_child(area)
	
	# Connect detection area signals
	area.body_entered.connect(_on_detection_area_body_entered)
	area.body_exited.connect(_on_detection_area_body_exited)
	
	# Set collision masks
	area.collision_layer = 0
	area.collision_mask = 2  # Layer for bugs
	
	# Store default rotation
	default_rotation = barrel.rotation

func _process(delta):
	# Skip all processing if tower is being placed
	if modulate.a < 1.0:
		return
	time_since_last_shot += delta
	
	# Update target if it's no longer valid
	if current_target and (not is_instance_valid(current_target) or current_target.current_health <= 0):
		current_target = null
	
	# Handle turret rotation
	if current_target and is_instance_valid(current_target):
		# Calculate desired rotation to face target
		var target_pos = current_target.global_position
		var desired_angle = global_position.direction_to(target_pos).angle()
		
		# Smoothly rotate barrel
		barrel.rotation = lerp_angle(barrel.rotation, desired_angle, rotation_speed * delta)
		
		# Try to fire if we're facing the right direction
		if abs(barrel.rotation - desired_angle) < 0.1 and time_since_last_shot >= 1.0 / fire_rate:
			attempt_fire()
	else:
		# Return to default rotation when no target
		barrel.rotation = lerp_angle(barrel.rotation, default_rotation, rotation_speed * delta)
	
	update_power_display()
	print("turret power: " + str(power))

func attempt_fire() -> void:
	if current_target and is_instance_valid(current_target):
		# Create projectile
		var projectile = projectile_scene.instantiate()
		get_tree().root.add_child(projectile)
		projectile.global_position = barrel.global_position
		projectile.setup(damage, current_target)
		
		time_since_last_shot = 0.0

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body is BaseBug:
		if not current_target:
			current_target = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == current_target:
		current_target = find_new_target()

func find_new_target() -> BaseBug:
	var potential_targets = get_node("DetectionArea").get_overlapping_bodies()
	var closest_target: BaseBug = null
	var closest_distance = INF
	
	for body in potential_targets:
		if body is BaseBug and is_instance_valid(body) and body.current_health > 0:
			var distance = global_position.distance_to(body.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_target = body
	
	return closest_target

func get_attack_range() -> float:
	return range

func get_damage() -> int:
	return damage

func update_power_display() -> void:
	if has_node("PowerBar"):
		$PowerBar.max_value = power_storage
		$PowerBar.value = power
		$PowerBar.modulate = Color(0, 1, 1)
