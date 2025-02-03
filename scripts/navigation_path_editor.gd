extends Line2D

signal points_modified

var ground_texture: Texture2D

@export var edit_mode: bool = true
@export var path_width: float = 150.0  # Width of the navigation path
var selected_point: int = -1
var hovering_point: int = -1
const POINT_SNAP_DISTANCE = 10.0
var is_dragging: bool = false

func _ready():
	# Make sure points are initially set
	if points.size() == 0:
		points = PackedVector2Array([Vector2.ZERO])
	
	# Load the ground texture
	ground_texture = load("res://assets/textures/path_texture.tres")
	
	# Initial navigation update
	update_navigation_region()

func _input(event):
	# We need to handle input before the editor does
	if not edit_mode:
		return
	
	if event is InputEventMouseMotion:
		var local_pos = to_local(get_global_mouse_position())
		hovering_point = -1
		
		# Check if hovering over any point
		for i in points.size():
			if local_pos.distance_to(points[i]) < POINT_SNAP_DISTANCE:
				hovering_point = i
				break
		
		# Move selected point if dragging
		if selected_point != -1 and is_dragging:
			points.set(selected_point, local_pos)
			queue_redraw()
			emit_signal("points_modified")
			update_navigation_region()
			get_viewport().set_input_as_handled()
			
	elif event is InputEventMouseButton:
		var local_pos = to_local(get_global_mouse_position())
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				var point_selected = false
				
				# Check if clicking on an existing point
				for i in points.size():
					if local_pos.distance_to(points[i]) < POINT_SNAP_DISTANCE:
						selected_point = i
						point_selected = true
						get_viewport().set_input_as_handled()
						break
				
				# If not clicking existing point, add new point
				if not point_selected:
					# Find the closest segment to insert the point
					var insert_index = find_insert_index(local_pos)
					points.insert(insert_index, local_pos)
					selected_point = insert_index
					queue_redraw()
					emit_signal("points_modified")
					update_navigation_region()
					get_viewport().set_input_as_handled()
			else:
				is_dragging = false
				if selected_point != -1:
					selected_point = -1
					get_viewport().set_input_as_handled()
		
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Remove point if right clicking on it
			for i in points.size():
				if local_pos.distance_to(points[i]) < POINT_SNAP_DISTANCE:
					if points.size() > 1:  # Don't remove last point
						points.remove_at(i)
						queue_redraw()
						emit_signal("points_modified")
						update_navigation_region()
						get_viewport().set_input_as_handled()
					break

func find_insert_index(new_point: Vector2) -> int:
	if points.size() < 2:
		return points.size()
	
	var closest_dist = INF
	var insert_index = points.size()
	
	# Find the segment where the point should be inserted
	for i in range(points.size() - 1):
		var start = points[i]
		var end = points[i + 1]
		var segment_dist = get_point_to_segment_distance(new_point, start, end)
		
		if segment_dist < closest_dist:
			closest_dist = segment_dist
			insert_index = i + 1
	
	return insert_index

func get_point_to_segment_distance(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var segment = segment_end - segment_start
	var point_vec = point - segment_start
	
	var segment_length_squared = segment.length_squared()
	if segment_length_squared == 0:
		return point_vec.length()
	
	var t = max(0, min(1, point_vec.dot(segment) / segment_length_squared))
	var projection = segment_start + segment * t
	
	return point.distance_to(projection)

func _draw():
	# Draw the path segments with the ground texture
	if points.size() >= 2:
		for i in range(points.size() - 1):
			var start = points[i]
			var end = points[i + 1]
			var direction = (end - start).normalized()
			var perpendicular = Vector2(-direction.y, direction.x) * path_width/2
			
			var poly = PackedVector2Array([
				start + perpendicular,
				start - perpendicular,
				end - perpendicular,
				end + perpendicular
			])
			
			# Draw textured path segment
			draw_colored_polygon(poly, Color.WHITE, poly, ground_texture)
	
	# Only show debug visualization in editor
	if Engine.is_editor_hint() and edit_mode:
		# Draw points on top
		for i in points.size():
			var color = Color.WHITE
			if i == selected_point:
				color = Color.YELLOW
			elif i == hovering_point:
				color = Color.LIGHT_BLUE
			draw_circle(points[i], 5.0, color)
			
			# Draw point indices for debugging
			draw_string(ThemeDB.fallback_font, points[i] + Vector2(10, -10), str(i), color)

func update_navigation_region():
	var nav_region = get_parent().get_parent().get_node("NavigationRegion2D")
	if not nav_region:
		print("ERROR: NavigationRegion2D not found in scene!")
		print("Current node path: ", get_path())
		print("Parent: ", get_parent().name)
		print("Parent's parent: ", get_parent().get_parent().name)
		return
	print("Navigation update starting...")
	print("Navigation region found at: ", nav_region.get_path())
	if not nav_region:
		return
	
	var nav_poly = NavigationPolygon.new()
	
	# Add the base navigation area (full ground)
	var ground_outline = PackedVector2Array([
		Vector2(-2000, -2000),
		Vector2(2000, -2000),
		Vector2(2000, 2000),
		Vector2(-2000, 2000)
	])
	nav_poly.add_outline(ground_outline)
	
	# Add navigation paths from all spawn points
	var spawn_points = get_parent().get_parent().get_node("SpawnPoints")
	if spawn_points:
		for spawn_point in spawn_points.get_children():
			var path_node = spawn_point.get_node_or_null("Path")
			if path_node and path_node.points.size() >= 2:
				create_path_polygon(nav_poly, path_node)
	
	# Generate the navigation polygons
	nav_poly.make_polygons_from_outlines()
	nav_region.navigation_polygon = nav_poly
	
	# Force navigation update
	nav_region.bake_navigation_polygon()

func create_path_polygon(nav_poly: NavigationPolygon, path_node: Line2D):
	var path_points = path_node.points
	for i in range(path_points.size() - 1):
		var start = path_node.to_global(path_points[i])
		var end = path_node.to_global(path_points[i + 1])
		var direction = (end - start).normalized()
		var perpendicular = Vector2(-direction.y, direction.x) * path_width/2
		
		# Create a polygon for this path segment
		var segment_outline = PackedVector2Array([
			start + perpendicular,
			start - perpendicular,
			end - perpendicular,
			end + perpendicular
		])
		nav_poly.add_outline(segment_outline)

# Get the path points in global coordinates
func get_global_path() -> Array:
	var global_points = []
	for point in points:
		global_points.append(to_global(point))
	return global_points
