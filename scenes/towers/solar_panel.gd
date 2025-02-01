extends BaseTower

func _generate_power(delta: float):
	if (%DayNightManager.is_day && power < power_storage):
		power += delta * charge_rate

func _ready():
	cost = 150
	power_generation = 10  # 10 power units per minute
	durability = 100

func _process(delta: float) -> void:
	_generate_power(delta)
	super._process(delta)
	print("panel power: " + str(power))
