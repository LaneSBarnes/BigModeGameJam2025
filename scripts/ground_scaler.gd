extends TextureRect

@onready var boundary_node = get_parent()

func _ready():
	# Make sure we have both the texture and boundary
	if not texture or not boundary_node:
		push_error("Ground scaling script: Missing texture or boundary node")
		return
		
	# Get the boundary rectangle
	var bounds: Rect2 = boundary_node.boundary_rect
	
	# Set anchors to fill entire parent
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1
	
	# Set position to match boundary position
	position = bounds.position
	
	# Set size to exactly match boundary size
	size = bounds.size
	
	# Configure texture properties for full coverage
	# Using IGNORE_SIZE_LIMIT for expand_mode
	expand_mode = 1
	# Using STRETCH_SCALE_ON_EXPAND for stretch_mode
	stretch_mode = 6
	
	# Ensure layout update
	queue_redraw()
