extends Node2D

@export var input: PowerNode
@export var color: Color

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	queue_redraw()
	
func _draw() -> void:
	draw_rect(Rect2(0, 0, 100, -100), Color.BLACK)
	draw_rect(Rect2(0, 0, 100, -(input.charge/input.capacity) * 100), color)
