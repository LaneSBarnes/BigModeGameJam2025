extends Node

@export var outputs: Array[PowerNode]
@export var solar_energy = 0;
@export var strength = 1
@export var day_length = 60 # seconds
var time: float

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta
	var energy = strength * sin(time / day_length * TAU)
	solar_energy = energy if (energy >= 0) else 0
	print("solar_energy: " + str(solar_energy))
	
	var eligibleOutputs: Array[PowerNode]
	for output in outputs:
		if (output.charge < output.capacity):
			eligibleOutputs.append(output)
	for eligibleOutput in eligibleOutputs:
		eligibleOutput.charge += solar_energy * eligibleOutput.charge_rate * delta
