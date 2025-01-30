extends BaseBug

func _ready():
    base_health = 100
    base_speed = 75  # Slow speed
    credit_reward = 50
    special_ability = "Armored"
    super._ready()  # Call parent _ready() to apply day scaling
    
    # Update health bar
    $HealthBar.max_value = current_health
    $HealthBar.value = current_health

func _process(_delta):
    $HealthBar.value = current_health

func take_damage(amount: float) -> void:
    # Armored: takes 25% less damage
    super.take_damage(amount * 0.75)