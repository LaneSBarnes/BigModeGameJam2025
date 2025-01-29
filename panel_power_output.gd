class_name PanelPowerOutput
extends PowerNode

@onready var sun: Node = %Sun
@export var efficiency = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (charge < capacity):
		charge += sun.solar_energy * delta * efficiency
	print("panel_charge: " + str(charge))
