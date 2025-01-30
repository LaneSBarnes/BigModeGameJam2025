extends Node2D

# This will store all available paths to the base
var paths: Array[Path2D] = []
@export var player_base: NodePath
var base: StaticBody2D

func _ready():
	if player_base:
		base = get_node(player_base)
	update_paths()

# Call this when you add new paths or when the map changes
func update_paths() -> void:
	paths.clear()
	# Get all Path2D children
	for child in get_children():
		if child is Path2D:
			paths.append(child)

# Get a random path for a bug to follow
func get_random_path() -> Path2D:
	if paths.size() > 0:
		return paths[randi() % paths.size()]
	return null

# Get the closest path to a given position
func get_closest_path(position: Vector2) -> Path2D:
	var closest_path: Path2D = null
	var closest_distance: float = INF
	
	for path in paths:
		var distance = position.distance_to(path.curve.get_point_position(0))
		if distance < closest_distance:
			closest_distance = distance
			closest_path = path
	
	return closest_path

# Add a new path from a starting point to the base
func create_path(start_point: Vector2) -> Path2D:
	var new_path = Path2D.new()
	var curve = Curve2D.new()
	
	# Add the start point
	curve.add_point(start_point)
	
	# Add some intermediate points (you might want to make this more sophisticated)
	var mid_point = (start_point + base.position) / 2
	mid_point += Vector2(randf_range(-100, 100), randf_range(-100, 100))
	curve.add_point(mid_point)
	
	# Add the end point (base position)
	curve.add_point(base.position)
	
	new_path.curve = curve
	add_child(new_path)
	paths.append(new_path)
	
	return new_path
