extends BaseBug

func _ready():
	base_health = 50
	base_speed = 100  # Normal speed
	credit_reward = 25
	special_ability = "None"
	super._ready()  # Call parent _ready() to apply day scaling
	
	# Update health bar
	$HealthBar.max_value = current_health
	$HealthBar.value = current_health

func _process(_delta):
	$HealthBar.value = current_health
