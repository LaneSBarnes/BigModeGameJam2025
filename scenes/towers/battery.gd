extends BaseTower

func _ready():
	cost = 200
	power_storage = 100  # 100 power units capacity
	durability = 150

func get_current_power() -> float:
	return power
	
func update_power_display() -> void:
	if has_node("PowerBar"):
		$PowerBar.max_value = power_storage
		$PowerBar.value = power
		$PowerBar.modulate = Color(0, 1, 1)

func _process(delta: float) -> void:
	super._process(delta)
	update_power_display()
	print("battery power: " + str(power))
