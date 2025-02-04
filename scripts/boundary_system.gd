extends Node2D

@export var boundary_rect: Rect2 = Rect2(-500, -500, 1000, 1000)  # Default 1000x1000 area centered at origin
@export var show_boundary: bool = true  # Toggle boundary visibility in game
@export var outer_color: Color = Color(0, 0, 0, 1)  # Color of the area outside boundaries
@export var outer_margin: float = 2000.0  # How far the black background extends

@onready var player: CharacterBody2D = get_node("%Player")  # Using the same unique name reference as camera
@onready var viewport_size: Vector2 = get_viewport_rect().size

func _ready():
	# Ensure we redraw when the viewport size changes
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	# Initial draw
	queue_redraw()

func _physics_process(_delta):
	if not player:
		return
		
	# Get the player's collision shape size
	var collision_shape: CollisionShape2D = player.get_node("CollisionShape2D")
	var radius: float = collision_shape.shape.radius
	
	# Clamp player position to stay within boundaries, accounting for player size
	var new_position = player.global_position
	new_position.x = clamp(
		new_position.x, 
		boundary_rect.position.x + radius,
		boundary_rect.position.x + boundary_rect.size.x - radius
	)
	new_position.y = clamp(
		new_position.y,
		boundary_rect.position.y + radius,
		boundary_rect.position.y + boundary_rect.size.y - radius
	)
	
	# Update player position if it would go outside bounds
	if new_position != player.global_position:
		player.global_position = new_position
		# Optional: Reset velocity when hitting boundary
		player.velocity = Vector2.ZERO

func _draw():
	# Draw the outer black area using a series of rectangles
	# Top
	draw_rect(Rect2(
		boundary_rect.position - Vector2(outer_margin, outer_margin),
		Vector2(boundary_rect.size.x + outer_margin * 2, outer_margin)
	), outer_color)
	
	# Bottom
	draw_rect(Rect2(
		boundary_rect.position + Vector2(0, boundary_rect.size.y),
		Vector2(boundary_rect.size.x + outer_margin * 2, outer_margin)
	), outer_color)
	
	# Left
	draw_rect(Rect2(
		boundary_rect.position - Vector2(outer_margin, 0),
		Vector2(outer_margin, boundary_rect.size.y)
	), outer_color)
	
	# Right
	draw_rect(Rect2(
		boundary_rect.position + Vector2(boundary_rect.size.x, 0),
		Vector2(outer_margin, boundary_rect.size.y)
	), outer_color)
	
	# Draw boundary line if enabled
	if show_boundary:
		draw_rect(boundary_rect, Color.WHITE, false, 2.0)

func _on_viewport_size_changed():
	viewport_size = get_viewport_rect().size
	queue_redraw()
