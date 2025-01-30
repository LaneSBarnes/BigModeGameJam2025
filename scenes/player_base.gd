extends StaticBody2D

signal base_destroyed
signal base_damaged(current_health: float, max_health: float)

@export var max_health: float = 1000.0
var current_health: float

func _ready():
	print("Player base ready at: ", global_position)
	current_health = max_health
	update_health_display()
	
	# Connect the area entered signal
	if has_node("Area2D"):
		print("Setting up Area2D collision detection")
		$Area2D.monitoring = true
		$Area2D.body_entered.connect(_on_bug_entered)
	else:
		print("Warning: No Area2D found on player base!")

func take_damage(amount: float) -> void:
	print("Base taking damage: ", amount)
	current_health = max(0, current_health - amount)
	update_health_display()
	emit_signal("base_damaged", current_health, max_health)
	
	if current_health <= 0:
		destroy()

func update_health_display() -> void:
	if has_node("HealthBar"):
		$HealthBar.max_value = max_health
		$HealthBar.value = current_health
		
		# Update color based on health percentage
		var health_percent = current_health / max_health
		if health_percent > 0.6:
			$HealthBar.modulate = Color(0, 1, 0)  # Green
		elif health_percent > 0.3:
			$HealthBar.modulate = Color(1, 1, 0)  # Yellow
		else:
			$HealthBar.modulate = Color(1, 0, 0)  # Red

func destroy() -> void:
	emit_signal("base_destroyed")
	print("Base destroyed!")

func _on_bug_entered(body: Node2D) -> void:
	print("Body entered base area: ", body.name)
	if body is BaseBug and not body.has_reached_base:
		print("Valid bug collision detected")
		# When a bug reaches the base:
		body.has_reached_base = true
		# 1. Deal damage based on the bug's strength (use a fixed amount for now)
		take_damage(50)  # Fixed damage amount
		# 2. Destroy the bug
		body.die()
	else:
		print("Invalid collision or bug already processed")

func get_health_percentage() -> float:
	return (current_health / max_health) * 100
