extends Node2D

@onready var spawn_points = $SpawnPoints
@onready var player_base = $PlayerBase
@onready var game_ui = $GameUI
@onready var game_over = $CanvasLayer/GameOver
@onready var navigation_region = $NavigationRegion2D

var bug_scenes = [
	preload("res://scenes/enemies/worker_bug.tscn"),
	preload("res://scenes/enemies/soldier_bug.tscn"),
	preload("res://scenes/enemies/scout_bug.tscn")
]

# Wave settings
var base_bugs_per_night: int = 5
var bugs_increment_per_night: int = 2
var bugs_remaining_in_wave: int = 0
@onready var day_night_manager = $DayNightManager

func _ready():
	print("Test scene initializing...")
	if game_over:
		game_over.visible = false
	
	# Connect base signals
	if player_base:
		player_base.connect("base_damaged", _on_player_base_damaged)
		player_base.connect("base_destroyed", _on_player_base_destroyed)
	
	# Connect day/night signals
	if day_night_manager:
		day_night_manager.day_started.connect(_on_day_started)
		day_night_manager.night_started.connect(_on_night_started)
	
	# Initial path setup
	update_all_navigation_paths()
	$SpawnTimer.stop()

func update_all_navigation_paths():
	# Get the first path node and trigger its update function
	# This will handle updating the entire navigation region
	for spawn_point in spawn_points.get_children():
		var path = spawn_point.get_node_or_null("Path")
		if path and path.has_method("update_navigation_region"):
			path.update_navigation_region()
			break

func _on_day_started():
	print("Day started - Stopping spawns")
	$SpawnTimer.stop()

func _on_night_started():
	print("Night started - Beginning wave")
	start_wave()

func start_wave():
	var current_cycle = day_night_manager.get_current_cycle()
	bugs_remaining_in_wave = base_bugs_per_night + (bugs_increment_per_night * (current_cycle - 1))
	print("Starting wave with ", bugs_remaining_in_wave, " bugs")
	$SpawnTimer.start()

func _on_spawn_timer_timeout():
	spawn_bug()

func spawn_bug():
	if bugs_remaining_in_wave <= 0:
		$SpawnTimer.stop()
		return
	print("Spawning bug. Remaining in wave: ", bugs_remaining_in_wave)

	# Get a random spawn point
	var spawn_points_array = spawn_points.get_children()
	var spawn_point = spawn_points_array[randi() % spawn_points_array.size()]
	
	# Create the bug instance
	var bug_scene = bug_scenes[randi() % bug_scenes.size()]
	var bug = bug_scene.instantiate()
	
	# Set initial position
	bug.position = spawn_point.position
	add_child(bug)
	
	# Wait for physics setup
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Set the target for the bug
	if is_instance_valid(bug) and is_instance_valid(player_base):
		print("Setting target for bug: ", player_base.global_position)
		if bug.has_method("set_target"):
			bug.set_target(player_base.global_position)
	
	# Connect signals
	if bug.has_signal("bug_died"):
		bug.connect("bug_died", _on_bug_died)
	if bug.has_signal("reached_base"):
		bug.connect("reached_base", _on_bug_reached_base)
	
	bugs_remaining_in_wave -= 1
	print("Bugs remaining in wave: ", bugs_remaining_in_wave)

func _on_bug_died(credits_amount: int):
	print("Bug died! Earned ", credits_amount, " credits")
	if game_ui:
		game_ui.add_credits(credits_amount)
	
func _on_bug_reached_base():
	print("Bug reached the base!")

func _on_player_base_damaged(current_health: float, max_health: float):
	var health_percentage = (current_health / max_health) * 100
	print("Base damaged! Health: %d%%" % health_percentage)

func _on_player_base_destroyed():
	print("Base destroyed! Game Over!")
	$SpawnTimer.stop()
	if game_ui:
		game_ui.visible = false
	if game_over:
		game_over.show_game_over()

# Toggle path editing mode for all paths
func toggle_path_edit_mode(enabled: bool):
	for spawn_point in spawn_points.get_children():
		var path = spawn_point.get_node_or_null("Path")
		if path and path.has_method("set"):
			path.set("edit_mode", enabled)
