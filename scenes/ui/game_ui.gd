extends CanvasLayer

var dragging_tower: Node2D = null
var tower_scenes = {
	"Basic Turret": preload("res://scenes/towers/basic_turret.tscn"),
	"Rapid Turret": preload("res://scenes/towers/rapid_turret.tscn"),
	"Heavy Turret": preload("res://scenes/towers/heavy_turret.tscn"),
	"Solar Panel": preload("res://scenes/towers/solar_panel.tscn"),
	"Battery": preload("res://scenes/towers/battery.tscn")
}

var tower_costs = {
	"Basic Turret": 100,
	"Rapid Turret": 200,
	"Heavy Turret": 300,
	"Solar Panel": 150,
	"Battery": 200
}

var credits: int = 450  # Starting credits
var valid_placement_color = Color(0.0, 1.0, 0.0, 0.3)
var invalid_placement_color = Color(1.0, 0.0, 0.0, 0.3)

const PLACEMENT_DISTANCE = 140.0  # Distance in front of player to place tower

@onready var credits_label = $TopBar/HBoxContainer/CreditsInfo/Value
@onready var day_label = $TopBar/HBoxContainer/DayNightInfo/Label
@onready var time_progress = $TopBar/HBoxContainer/DayNightInfo/TimeProgress
@onready var solar_power_label = $TopBar/HBoxContainer/PowerInfo/SolarPower/Value
@onready var stored_power_label = $TopBar/HBoxContainer/PowerInfo/StoredPower/Value
@onready var tower_buttons = $TowerPanel/VBoxContainer/TowerButtons
@onready var day_night_manager = get_parent().get_node("DayNightManager")

func _ready():
	setup_tower_buttons()
	
	# Connect to managers
	var day_night = get_parent().get_node_or_null("DayNightManager")
	if day_night:
		day_night.cycle_tick.connect(_on_cycle_tick)
		day_night.day_started.connect(_on_day_started)
		day_night.night_started.connect(_on_night_started)
	
	var power_manager = get_parent().get_node_or_null("PowerManager")
	if power_manager:
		power_manager.power_updated.connect(_on_power_updated)
	update_credits_display()

func update_credits_display():
	credits_label.text = str(credits)

func add_credits(amount: int):
	credits += amount
	update_credits_display()

func setup_tower_buttons():
	for tower_name in tower_scenes.keys():
		var button = Button.new()
		button.text = tower_name + "\n$" + str(tower_costs[tower_name])
		button.custom_minimum_size = Vector2(80, 80)
		button.pressed.connect(_on_tower_button_pressed.bind(tower_name))
		tower_buttons.add_child(button)

func _on_tower_button_pressed(tower_name: String):
	if credits < tower_costs[tower_name]:
		print("Not enough credits for " + tower_name)
		return
		
	if dragging_tower != null:
		dragging_tower.queue_free()
	
	var tower_scene = tower_scenes[tower_name]
	dragging_tower = tower_scene.instantiate()
	get_parent().add_child(dragging_tower)
	dragging_tower.modulate.a = 0.5
	# Set initial position to in front of player
	update_tower_position()

func get_placement_position() -> Vector2:
	var player = get_parent().get_node("Player")
	if player:
		# Calculate position in front of player using their rotation
		var offset = Vector2.RIGHT.rotated(player.rotation) * PLACEMENT_DISTANCE
		return player.global_position + offset
	return Vector2.ZERO

func update_tower_position():
	if dragging_tower:
		dragging_tower.global_position = get_placement_position()
		var can_place = can_place_tower(dragging_tower)
		dragging_tower.modulate = valid_placement_color if can_place else invalid_placement_color

func _unhandled_input(event):
	if dragging_tower:
		if event.is_action_pressed("mouse_left"):
			# Check if position is valid
			if can_place_tower(dragging_tower):
				# Deduct cost when placing
				var tower_name = ""
				for name in tower_scenes.keys():
					if tower_scenes[name].get_path() == dragging_tower.scene_file_path:
						tower_name = name
						break
						
				credits -= tower_costs[tower_name]
				update_credits_display()
				dragging_tower.modulate = Color.WHITE
				var collision_shape = dragging_tower.get_node("CollisionShape2D")
				collision_shape.disabled = false
				# If this is a power-related tower, register it with the power manager
				if dragging_tower.has_method("get_power_generation") or \
					dragging_tower.has_method("get_power_storage"):
					var power_manager = get_parent().get_node_or_null("PowerManager")
					if power_manager:
						if dragging_tower.has_method("get_power_generation"):
							power_manager.register_solar_panel(dragging_tower)
						if dragging_tower.has_method("get_power_storage"):
							power_manager.register_battery(dragging_tower)
							
				dragging_tower = null
			else:
				# Optional: Play invalid placement sound/effect
				pass
				
		elif event.is_action_pressed("mouse_right"):
			dragging_tower.queue_free()
			dragging_tower = null

func can_place_tower(tower: Node2D) -> bool:
	# Check if we have enough credits
	var tower_name = ""
	for name in tower_scenes.keys():
		if tower_scenes[name].get_path() == tower.scene_file_path:
			tower_name = name
			break
			
	if credits < tower_costs[tower_name]:
		return false
		
	# Get physics world
	var space = get_parent().get_world_2d().direct_space_state
	
	# Use the tower's collision shape
	var collision_shape = tower.get_node("CollisionShape2D")
	if not collision_shape:
		print("No collision shape found for tower")
		return false
	
	# Temporarily disable the tower's collision
	var original_disabled = collision_shape.disabled
	collision_shape.disabled = true
	
	# Create overlap test using shape query
	var params = PhysicsShapeQueryParameters2D.new()
	params.shape = collision_shape.shape
	params.transform = collision_shape.global_transform
	params.collision_mask = 14  # Towers (4) + Base (3) + Bugs (2) = 14
	params.collide_with_areas = true
	params.collide_with_bodies = true
	
	var results = space.intersect_shape(params)
	
	if results:
		return false  # Colliding with towers, base, or bugs
	
	return true

func update_tower_buttons():
	for tower_name in tower_costs.keys():
		for button in tower_buttons.get_children():
			if button.text.begins_with(tower_name):
				button.disabled = credits < tower_costs[tower_name]
				# Optional: Update button appearance based on affordability
				button.modulate = Color.WHITE if credits >= tower_costs[tower_name] else Color(0.5, 0.5, 0.5)

func _process(_delta):
	if tower_buttons.get_child_count() > 0:
		update_tower_buttons()
	if dragging_tower:
		update_tower_position()

func _on_cycle_tick(time_remaining: float, is_day: bool):
	var total_duration = day_night_manager.DAY_DURATION if is_day else day_night_manager.NIGHT_DURATION
	time_progress.value = (1.0 - (time_remaining / total_duration)) * 100
	time_progress.modulate = Color(0.2, 1.0, 0.2) if is_day else Color(0.2, 0.2, 1.0)

func _on_day_started():
	day_label.text = "Day " + str(get_parent().get_node("DayNightManager").get_current_cycle())

func _on_night_started():
	day_label.text = "Night " + str(get_parent().get_node("DayNightManager").get_current_cycle())

func _on_power_updated(solar_power: float, stored_power: float):
	solar_power_label.text = "%.1f" % solar_power
	stored_power_label.text = "%.1f" % stored_power
