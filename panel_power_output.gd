extends Node

@onready var sun: Node = %Sun
@export var power_output = 0
@export var efficiency = 0.2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	power_output = sun.solar_energy * efficiency
	print("power_output: " + str(power_output))
