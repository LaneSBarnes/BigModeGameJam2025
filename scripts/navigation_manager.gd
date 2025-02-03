extends Node2D

var path_nodes: Array[Node] = []
var nav_region: NavigationRegion2D

func _enter_tree():
	print("Navigation Manager entering tree...")
	call_deferred("setup_navigation_region")

func _ready():
	print("Navigation Manager initializing...")
	await get_tree().process_frame
	# Find all path nodes
	find_path_nodes()
	# Initial navigation update
	call_deferred("update_navigation_mesh")

func setup_navigation_region():
	print("Setting up NavigationRegion2D...")
	
	# Remove any existing NavigationRegion2D
	var existing = get_parent().get_node_or_null("NavigationRegion2D")
	if existing:
		existing.queue_free()
	
	# Create new NavigationRegion2D
	nav_region = NavigationRegion2D.new()
	nav_region.name = "NavigationRegion2D"
	nav_region.enabled = true
	
	# Add it to the scene before the first bug spawn
	var spawn_points = get_parent().get_node_or_null("SpawnPoints")
	if spawn_points:
		get_parent().add_child.call_deferred(nav_region)
		get_parent().move_child.call_deferred(nav_region, spawn_points.get_index())
	else:
		get_parent().add_child.call_deferred(nav_region)
	
	nav_region.add_to_group("navigation_regions")
	print("NavigationRegion2D created and added to scene")

func find_path_nodes():
	path_nodes.clear()
	var spawn_points = get_parent().get_node("SpawnPoints")
	if spawn_points:
		for spawn_point in spawn_points.get_children():
			var path = spawn_point.get_node_or_null("Path")
			if path:
				path_nodes.append(path)
				path.add_to_group("navigation_paths")
				print("Found path node: ", path.get_path())
				print("Path points: ", path.points.size())
				# Connect to path's points_changed signal if it exists
				if path.has_signal("points_changed"):
					path.points_changed.connect(_on_path_modified)
	
	print("Found ", path_nodes.size(), " path nodes")



func update_navigation_mesh():
	if not is_instance_valid(nav_region):
		push_error("NavigationRegion2D not valid!")
		return
	
	print("Updating navigation mesh...")
	var nav_poly = NavigationPolygon.new()
	
	# Process each path as walkable areas
	for path_node in path_nodes:
		if not path_node or path_node.points.size() < 2:
			continue
			
		print("Processing path: ", path_node.get_path())
		
		# Get the smooth outline directly from the path node
		var outline = path_node.create_smooth_path_outline()
		
		# Convert to global coordinates and ensure points are not too close together
		var global_outline = PackedVector2Array()
		var last_point = null
		var min_distance = 2.0  # Minimum distance between points to avoid degenerate triangles
		
		for point in outline:
			var global_point = path_node.to_global(point)
			# Skip points that are too close to the last point
			if last_point == null or last_point.distance_to(global_point) > min_distance:
				# Snap coordinates to improve vertex matching
				global_point = Vector2(
					snappedf(global_point.x, 0.1),
					snappedf(global_point.y, 0.1)
				)
				global_outline.append(global_point)
				last_point = global_point
		
		# Ensure we have enough points and they form a valid shape
		if global_outline.size() >= 3:
			# Make sure the shape is closed
			if global_outline[0] != global_outline[-1]:
				global_outline.append(global_outline[0])
			nav_poly.add_outline(global_outline)
	
	if nav_poly.get_outline_count() > 0:
		# Make polygons from the outlines
		nav_poly.make_polygons_from_outlines()
		
		# Debug output for navigation mesh verification
		print("Navigation mesh statistics:")
		print("- Number of outlines: ", nav_poly.get_outline_count())
		print("- Number of vertices: ", nav_poly.get_vertices().size())
		print("- Number of polygons: ", nav_poly.get_polygon_count())
		
		# Print warning if no polygons were generated
		# Print warning if no polygons were generated
		if nav_poly.get_polygon_count() == 0:
			push_warning("Navigation mesh generation failed to create any polygons!")
	
	if nav_poly.get_outline_count() > 0:
		# Generate the navigation polygons
		nav_poly.make_polygons_from_outlines()
		print("Created navigation polygon with ", nav_poly.get_outline_count(), " outlines")
		
		# Update the navigation region
		nav_region.navigation_polygon = nav_poly
		nav_region.enabled = true
		
		# Force update
		nav_region.bake_navigation_polygon(true)
		print("Navigation mesh baked successfully")
		
		# Debug info
		print("Navigation region enabled: ", nav_region.enabled)
		print("Navigation polygon vertices: ", nav_poly.get_vertices().size())
	else:
		push_warning("No valid path segments found to create navigation mesh!")
	
	if nav_poly.get_outline_count() > 0:
		# Generate the navigation polygons
		nav_poly.make_polygons_from_outlines()
		print("Created navigation polygon with ", nav_poly.get_outline_count(), " outlines")
		
		# Update the navigation region
		nav_region.navigation_polygon = nav_poly
		nav_region.enabled = true
		
		# Force update
		nav_region.bake_navigation_polygon(true)
		print("Navigation mesh baked successfully")
		
		# Debug info
		print("Navigation region enabled: ", nav_region.enabled)
		print("Navigation polygon vertices: ", nav_poly.get_vertices().size())
	else:
		push_warning("No valid path segments found to create navigation mesh!")

func _on_path_modified():
	call_deferred("update_navigation_mesh")

# Remove debug visualization
func _process(_delta):
	pass

# Called when a path is created or modified
func notify_path_changed():
	call_deferred("update_navigation_mesh")
