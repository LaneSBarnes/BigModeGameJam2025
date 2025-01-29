extends Node2D

@onready var sun: Node = %Sun
@export var color: Color

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 100, -100), Color.BLACK)
	draw_rect(Rect2(0, 0, 100, -sun.solar_energy * 100), color)
