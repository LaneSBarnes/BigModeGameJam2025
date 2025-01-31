extends Node2D

@onready var spawn_points = $SpawnPoints
@onready var player_base = $PlayerBase
@onready var game_ui = $GameUI
@onready var game_over = $CanvasLayer/GameOver

var bug_scenes = [
	preload("res://scenes/enemies/worker_bug.tscn"),
	preload("res://scenes/enemies/soldier_bug.tscn"),
	preload("res://scenes/enemies/scout_bug.tscn")
]

func _ready():
	print("Test scene initializing...")
	if game_over:
		game_over.visible = false
	# Connect base signals
	if player_base:
		player_base.connect("base_damaged", _on_player_base_damaged)
		player_base.connect("base_destroyed", _on_player_base_destroyed)
	
	# Set up the test bug after a short delay
	call_deferred("setup_test_bug")

func setup_test_bug():
	await get_tree().physics_frame
	if has_node("TestBug"):
		var test_bug = $TestBug
		# Make sure the bug is at the correct starting position
		test_bug.global_position = Vector2(-450, 0)
		await get_tree().physics_frame
		test_bug.set_target(player_base.global_position)

func _on_spawn_timer_timeout():
	spawn_bug()

func spawn_bug():
	# Get a random spawn point
	var spawn_points_array = spawn_points.get_children()
	var spawn_point = spawn_points_array[randi() % spawn_points_array.size()]
	
	# Create the bug instance
	var bug_scene = bug_scenes[randi() % bug_scenes.size()]
	var bug = bug_scene.instantiate()
	
	# Set initial position before adding to scene
	bug.position = spawn_point.position
	add_child(bug)
	
	# Verify position and print debug info
	print("Spawned bug at position: ", bug.global_position)
	print("Distance to base: ", bug.global_position.distance_to(player_base.global_position))
	
	# Connect signals
	bug.connect("bug_died", _on_bug_died)
	bug.connect("reached_base", _on_bug_reached_base)
	
	# Wait for two physics frames to ensure proper navigation setup
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	if is_instance_valid(bug) and is_instance_valid(player_base):
		print("Setting target for bug: ", player_base.global_position)
		bug.set_target(player_base.global_position)

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
