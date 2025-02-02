extends Line2D

@export var edit_mode: bool = true
var ground_texture: Texture2D
@export var path_width: float = 100.0  # Width of the navigation path
var selected_point: int = -1
var hovering_point: int = -1
const POINT_SNAP_DISTANCE = 10.0

func _ready():
	# Make sure points are initially set
	if points.size() == 0:
		points = PackedVector2Array([Vector2.ZERO])
	
	# Load the ground texture
	ground_texture = load("res://assets/textures/path_texture.tres")

func _input(event):
	# Only allow editing in the editor
	if not Engine.is_editor_hint():
		return
	
	if not edit_mode:
		return
		
	if event is InputEventMouseMotion:
		var local_pos = get_local_mouse_position()
		hovering_point = -1
		
		# Check if hovering over any point
		for i in points.size():
			if local_pos.distance_to(points[i]) < POINT_SNAP_DISTANCE:
				hovering_point = i
				break
		
		# Move selected point if dragging
		if selected_point != -1:
			points.set(selected_point, local_pos)
			queue_redraw()
			# Notify navigation manager to update
			var nav_manager = get_parent().get_parent().get_parent().get_node_or_null("NavigationManager")
			if nav_manager:
				nav_manager.update_navigation_mesh()
			
	elif event is InputEventMouseButton:
		var local_pos = get_local_mouse_position()
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Check if clicking on an existing point
				for i in points.size():
					if local_pos.distance_to(points[i]) < POINT_SNAP_DISTANCE:
						selected_point = i
						return
						
				# If not clicking existing point, add new point
				points.append(local_pos)
				selected_point = points.size() - 1
				queue_redraw()
				# Notify navigation manager to update
				var nav_manager = get_parent().get_parent().get_parent().get_node_or_null("NavigationManager")
				if nav_manager:
					nav_manager.update_navigation_mesh()
			else:
				selected_point = -1
				
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Remove point if right clicking on it
			for i in points.size():
				if local_pos.distance_to(points[i]) < POINT_SNAP_DISTANCE:
					if points.size() > 1:  # Don't remove last point
						points.remove_at(i)
						queue_redraw()
						# Notify navigation manager to update
						var nav_manager = get_parent().get_parent().get_parent().get_node_or_null("NavigationManager")
						if nav_manager:
							nav_manager.update_navigation_mesh()
					break

func _draw():
	# Draw the path with smooth corners
	if points.size() >= 2:
		var outline = create_smooth_path_outline()
		draw_colored_polygon(outline, Color.WHITE, outline, ground_texture)
	
	# Only show debug visualization in editor
	if Engine.is_editor_hint() and edit_mode:
		# Draw points
		for i in points.size():
			var color = Color.WHITE
			if i == selected_point:
				color = Color.YELLOW
			elif i == hovering_point:
				color = Color.LIGHT_BLUE
			draw_circle(points[i], 5.0, color)

func create_smooth_path_outline() -> PackedVector2Array:
	var outline = PackedVector2Array()
	var segments = 8  # Number of segments to use for corner rounding
	
	# Forward edge (right side of path)
	for i in range(points.size()):
		var current = points[i]
		var prev_point = current
		var next_point = current
		var prev_dir = Vector2.ZERO
		var next_dir = Vector2.ZERO
		
		# Get previous and next points for smooth corners
		if i > 0:
			prev_point = points[i - 1]
			prev_dir = (current - prev_point).normalized()
		if i < points.size() - 1:
			next_point = points[i + 1]
			next_dir = (next_point - current).normalized()
		
		# If this is a corner point (not first or last)
		if i > 0 and i < points.size() - 1:
			# Calculate corner radius (half the path width or less)
			var corner_radius = min(path_width / 2, (current - prev_point).length() / 2, (next_point - current).length() / 2)
			
			# Create rounded corner
			var start_angle = prev_dir.angle()
			var end_angle = next_dir.angle()
			var angle_diff = wrapf(end_angle - start_angle, -PI, PI)
			
			# Add points for rounded corner
			for s in range(segments + 1):
				var t = float(s) / segments
				var angle = start_angle + angle_diff * t
				var offset = Vector2(cos(angle + PI/2), sin(angle + PI/2)) * path_width/2
				outline.append(current + offset)
		else:
			# For end points, just add the perpendicular offset
			var dir = prev_dir if i == points.size() - 1 else next_dir
			var perpendicular = Vector2(-dir.y, dir.x) * path_width/2
			outline.append(current + perpendicular)
	
	# Return edge (left side of path, in reverse)
	for i in range(points.size() - 1, -1, -1):
		var current = points[i]
		var prev_point = current
		var next_point = current
		var prev_dir = Vector2.ZERO
		var next_dir = Vector2.ZERO
		
		if i > 0:
			prev_point = points[i - 1]
			prev_dir = (current - prev_point).normalized()
		if i < points.size() - 1:
			next_point = points[i + 1]
			next_dir = (next_point - current).normalized()
		
		# If this is a corner point (not first or last)
		if i > 0 and i < points.size() - 1:
			# Calculate corner radius (half the path width or less)
			var corner_radius = min(path_width / 2, (current - prev_point).length() / 2, (next_point - current).length() / 2)
			
			# Create rounded corner
			var start_angle = next_dir.angle()
			var end_angle = prev_dir.angle()
			var angle_diff = wrapf(end_angle - start_angle, -PI, PI)
			
			# Add points for rounded corner
			for s in range(segments + 1):
				var t = float(s) / segments
				var angle = start_angle + angle_diff * t
				var offset = Vector2(cos(angle - PI/2), sin(angle - PI/2)) * path_width/2
				outline.append(current + offset)
		else:
			# For end points, just add the perpendicular offset
			var dir = prev_dir if i == points.size() - 1 else next_dir
			var perpendicular = Vector2(-dir.y, dir.x) * path_width/2
			outline.append(current - perpendicular)
	
	return outline

# Get the path as an array of global positions
func get_path_points() -> Array:
	var global_points = []
	for point in points:
		global_points.append(to_global(point))
	return global_points
