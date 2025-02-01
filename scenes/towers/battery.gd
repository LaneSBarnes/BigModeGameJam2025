extends BaseTower

func _ready():
	cost = 200
	power_storage = 100  # 100 power units capacity
	durability = 150

func get_current_power() -> float:
	return power
