class_name PowerNode
extends Node

@export var input: PowerNode
@export var capacity: float = 100
@export var charge: float = 0

func give_power(requested_power: float) -> float:
	# Give the requested power. If the requested power is too much, give remaining charge.
	var output_power
	if (requested_power < charge):
		output_power = requested_power
	else:
		output_power = charge
		
	# Subtract the charge taken
	charge -= output_power
	
	return output_power
