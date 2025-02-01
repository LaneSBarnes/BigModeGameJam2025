extends BaseBug

func _ready():
	base_health = 30
	base_speed = 150  # Fast speed
	credit_reward = 65
	special_ability = "Dodge"
	super._ready()  # Call parent _ready() to apply day scaling
	
	# Update health bar
	$HealthBar.max_value = current_health
	$HealthBar.value = current_health

func _process(delta):
	$HealthBar.value = current_health

func take_damage(amount: float) -> void:
	# 20% chance to dodge
	if randf() > 0.2:
		super.take_damage(amount)
	# Could add a dodge animation or effect here
