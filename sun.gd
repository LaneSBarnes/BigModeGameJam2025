extends Node

@export var solar_energy = 0;
var time: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta
	var energy = sin(time * 1)
	solar_energy = energy if (energy >= 0) else 0
