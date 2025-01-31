class_name PowerNode
extends Node

@export var outputs: Array[PowerNode]
@export var capacity: float = 100
@export var charge: float = 0
@export var charge_rate: float = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (charge > 0):
		var eligibleOutputs: Array[PowerNode]
		for output in outputs:
			if (output.charge < output.capacity):
				eligibleOutputs.append(output)
		for eligibleOutput in eligibleOutputs:
			var given_charge = (eligibleOutput.charge_rate * delta) / eligibleOutputs.size()
			eligibleOutput.charge += given_charge
			charge -= given_charge


#func give_power(requested_power: float) -> float:
	## Give the requested power. If the requested power is too much, give remaining charge.
	#var output_power
	#if (requested_power < charge):
		#output_power = requested_power
	#else:
		#output_power = charge
		#
	## Subtract the charge taken
	#charge -= output_power
	#
	#return output_power
