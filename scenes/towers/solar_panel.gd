extends BaseTower

func _generate_power(delta: float):
	if (%DayNightManager.is_day):
		power += delta * charge_rate

func _ready():
	cost = 150
	power_generation = 10  # 10 power units per minute
	durability = 100
