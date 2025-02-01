extends Node2D

var speed: float = 200.0  # Slower than basic projectile due to weight
var damage: float = 30.0  # Matches heavy turret's default damage
var target: BaseBug = null
var max_lifetime: float = 7.0  # Longer lifetime due to slower speed
var lifetime: float = 0.0

func _ready():
	# Set initial rotation to face target
	if target and is_instance_valid(target):
		rotation = global_position.direction_to(target.global_position).angle()

func _process(delta):
	lifetime += delta
	if lifetime > max_lifetime:
		queue_free()
		return
	
	if not target or not is_instance_valid(target):
		queue_free()
		return
	
	# Move towards target
	var direction = global_position.direction_to(target.global_position)
	global_position += direction * speed * delta
	rotation = direction.angle()
	
	# Check if we've hit the target
	if global_position.distance_to(target.global_position) < 15:  # Larger hit area than basic projectile
		hit_target()

func setup(damage_amount: float, target_bug: BaseBug):
	damage = damage_amount
	target = target_bug

func hit_target():
	if target and is_instance_valid(target):
		target.take_damage(damage)
		# Additional damage to armored enemies could be handled in the bug's take_damage function
		# based on the projectile type if needed
	queue_free()
