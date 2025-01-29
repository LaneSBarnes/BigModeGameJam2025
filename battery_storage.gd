class_name BatteryStorage
extends PowerNode

@export var charge_rate: float = 0.1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (charge < capacity):
		var requested_power = charge_rate * delta
		charge += input.give_power(requested_power)
	print("battery_charge: " + str(charge))
