extends Node2D

class_name BaseTower

@export var cost: int = 100
@export var power_usage: float = 0
@export var power_generation: float = 0
@export var power_storage: float = 0
@export var durability: int = 100

# Optional power connection reference
var power_source = null

func _ready():
	pass

func process_power(delta: float) -> void:
	pass

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
