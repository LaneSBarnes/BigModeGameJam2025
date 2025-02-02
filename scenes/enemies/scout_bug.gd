extends BaseBug

func _ready():
	base_health = 30
	base_speed = 150  
	credit_reward = 65
	special_ability = "Dodge"
	super._ready()
	$HealthBar.max_value = current_health
	$HealthBar.value = current_health

func _process(delta):
	$HealthBar.value = current_health

func take_damage(amount: float) -> void:
	if randf() > 0.2:
		super.take_damage(amount)
