extends BaseTower
class_name Battery

var current_charge: float = 0

func _ready():
	cost = 200
	power_storage = 20
	durability = 150

func get_charge() -> float:
	return current_charge

func add_charge(amount: float) -> float:
	var space_left = power_storage - current_charge
	var amount_to_add = min(amount, space_left)
	current_charge += amount_to_add
	return amount_to_add

func draw_charge(amount: float) -> float:
	var amount_to_draw = min(amount, current_charge)
	current_charge -= amount_to_draw
	return amount_to_draw
