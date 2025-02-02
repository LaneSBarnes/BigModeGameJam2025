extends Sprite2D

func _ready():
	# Ensure it's behind everything
	z_index = -10
	
	# Force update the position and scale
	call_deferred("_update_background")
	
	# Connect to window resize signal
	get_tree().root.size_changed.connect(_update_background)

func _update_background():
	# Wait for one frame to ensure viewport is ready
	await get_tree().process_frame
	
	# Get the viewport size
	var viewport_rect = get_viewport_rect()
	var screen_size = viewport_rect.size
	
	# Center the sprite
	global_position = screen_size / 2
	
	# Calculate the scale needed to cover the screen
	if texture:
		var texture_size = texture.get_size()
		var scale_x = screen_size.x / texture_size.x
		var scale_y = screen_size.y / texture_size.y
		scale = Vector2(scale_x, scale_y)
