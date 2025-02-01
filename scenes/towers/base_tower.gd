extends StaticBody2D

class_name BaseTower

@export var cost: int = 100
@export var power_usage: float = 0
@export var power_generation: float = 0
@export var power: float = 0
@export var power_storage: float = 100
@export var durability: int = 100
@export var charge_rate: float = 1	
@export var outputs: Array[BaseTower]

func _ready():
	pass

func _process(delta: float) -> void:
	process_power(delta)

func process_power(delta: float) -> void:
	if (power > 0):
		# Filter out any outputs that are already full on power
		var eligibleOutputs: Array[BaseTower]
		for output in outputs:
			if (output.power < output.power_storage):
				eligibleOutputs.append(output)
				
		# Evenly distribute power to the outputs
		for eligibleOutput in eligibleOutputs:
			var given_power = (eligibleOutput.charge_rate * delta) / eligibleOutputs.size()
			eligibleOutput.power += given_power
			power -= given_power

func take_damage(amount: int) -> void:
	durability -= amount
	if durability <= 0:
		queue_free()

func get_power_needs() -> float:
	return power_usage

func get_power_generation() -> float:
	return power_generation

func get_power_storage() -> float:
	return power_storage
