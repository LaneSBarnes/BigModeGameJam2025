extends Node

signal power_updated(solar_power: float, stored_power: float)

var total_solar_power: float = 0.0
var total_stored_power: float = 0.0
var solar_panels: Array = []
var batteries: Array = []
var is_collecting: bool = true

func _ready():
	if get_parent().has_node("DayNightManager"):
		var day_night = get_parent().get_node("DayNightManager")
		day_night.day_started.connect(_on_day_started)
		day_night.night_started.connect(_on_night_started)

func _process(delta):
	if is_collecting:
		update_power(delta)

func register_solar_panel(panel):
	solar_panels.append(panel)

func unregister_solar_panel(panel):
	solar_panels.erase(panel)

func register_battery(battery):
	batteries.append(battery)

func unregister_battery(battery):
	batteries.erase(battery)

func update_power(delta):
	# Update solar power generation
	total_solar_power = 0.0
	for panel in solar_panels:
		total_solar_power += panel.get_power_output()
	
	# Update battery storage
	total_stored_power = 0.0
	var power_to_store = total_solar_power * delta
	
	for battery in batteries:
		if power_to_store > 0:
			power_to_store = battery.store_power(power_to_store)
		total_stored_power += battery.get_stored_power()
	
	emit_signal("power_updated", total_solar_power, total_stored_power)

func _on_day_started():
	is_collecting = true

func _on_night_started():
	is_collecting = false

func get_available_power() -> float:
	return total_stored_power

func use_power(amount: float) -> bool:
	var power_left = amount
	
	for battery in batteries:
		if power_left <= 0:
			break
		power_left -= battery.use_power(power_left)
	
	total_stored_power = 0.0
	for battery in batteries:
		total_stored_power += battery.get_stored_power()
	
	emit_signal("power_updated", total_solar_power, total_stored_power)
	return power_left <= 0  # Return true if all power was successfully used
