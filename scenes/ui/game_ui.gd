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


func get_mouse_position() -> Vector2:
	# Get the viewport and camera
	var viewport = get_tree().root.get_viewport()
	var camera = get_parent().get_node("Camera2D")
	
	if camera:
		# Get the raw mouse position in the viewport
		var mouse_pos = viewport.get_mouse_position()
		# Convert to global space considering camera zoom and offset
		return camera.get_screen_to_canvas(mouse_pos)
	else:
		# Fallback to viewport mouse position if no camera
		return viewport.get_mouse_position()


func _unhandled_input(event):
	if dragging_tower:
		if event is InputEventMouseMotion:
			dragging_tower.global_position = get_mouse_position()
		
		elif event.is_action_pressed("mouse_left"):
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
				
				dragging_tower.modulate.a = 1.0
				dragging_tower = null
		
		elif event.is_action_pressed("mouse_right"):
			dragging_tower.queue_free()
			dragging_tower = null

func can_place_tower(tower: Node2D) -> bool:
	# Add collision checking here
	return true


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
