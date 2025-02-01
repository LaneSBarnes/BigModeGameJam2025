extends Node

signal power_updated(solar_power: float, stored_power: float)

var solar_panels: Array[BaseTower] = []
var batteries: Array[Battery] = []
var current_solar_power: float = 0.0
var current_time_remaining: float = 0.0
var is_currently_day: bool = true
var is_transitioning: bool = false  # New flag for cycle transitions

# Constants
const UPDATE_INTERVAL = 0.5
const BASE_SOLAR_EFFICIENCY = 1.0
const MIN_SOLAR_EFFICIENCY = 0.0
const TRANSITION_DURATION = 0.5  # Half second transition

@onready var day_night_manager = get_parent().get_node("DayNightManager")
@onready var update_timer = Timer.new()
@onready var transition_timer = Timer.new()  # New timer for handling transitions

func _ready():
	add_child(update_timer)
	add_child(transition_timer)
	
	update_timer.wait_time = UPDATE_INTERVAL
	update_timer.timeout.connect(_on_update_timer_timeout)
	update_timer.start()
	
	transition_timer.one_shot = true
	transition_timer.timeout.connect(_on_transition_complete)
	
	if day_night_manager:
		day_night_manager.cycle_tick.connect(_on_cycle_tick)
		day_night_manager.day_started.connect(_on_day_started)
		day_night_manager.night_started.connect(_on_night_started)

func _on_cycle_tick(time_remaining: float, is_day: bool):
	current_time_remaining = time_remaining
	is_currently_day = is_day
	update_power_generation()

func _on_transition_complete():
	is_transitioning = false
	update_power_generation()
	print("Transition complete, resuming normal power operations")

func _on_day_started():
	print("Power Manager: Day started")
	is_transitioning = true
	is_currently_day = true
	
	# Force an immediate power update
	current_solar_power = 0.0  # Reset power during transition
	update_power_generation()
	
	# Start transition timer
	transition_timer.start(TRANSITION_DURATION)
	
	print("Solar efficiency at day start: ", get_current_solar_efficiency())
	print("Current solar power: ", current_solar_power)
	print("Total stored power _on_day_started: ", get_total_stored_power())

func _on_night_started():
	print("Power Manager: Night started")
	is_transitioning = true
	is_currently_day = false
	
	# Force an immediate power update
	current_solar_power = 0.0  # Reset power during transition
	update_power_generation()
	
	# Start transition timer
	transition_timer.start(TRANSITION_DURATION)
	
	print("Solar efficiency at night start: ", get_current_solar_efficiency())
	print("Current solar power: ", current_solar_power)
	print("Total stored power _on_night_started_on_night_started: ", get_total_stored_power())

func register_solar_panel(panel: Node2D) -> void:
	if panel is BaseTower and not panel is Battery:  # Make sure it's not a battery
		if panel not in solar_panels:
			solar_panels.append(panel)
			print("Registered new solar panel. Total panels: ", solar_panels.size())
			update_power_generation()

func register_battery(battery: Node2D) -> void:
	if battery is Battery:  # Explicitly check for Battery class
		if battery not in batteries:
			batteries.append(battery)
			print("Registered new battery. Total batteries: ", batteries.size())
			update_power_generation()

func unregister_solar_panel(panel: Node2D) -> void:
	solar_panels.erase(panel)
	update_power_generation()

func unregister_battery(battery: Node2D) -> void:
	batteries.erase(battery)
	update_power_generation()

func get_current_solar_efficiency() -> float:
	if not day_night_manager:
		return BASE_SOLAR_EFFICIENCY
		
	if not is_currently_day:
		return MIN_SOLAR_EFFICIENCY
		
	# Get the total duration of day
	var total_duration = day_night_manager.DAY_DURATION
	
	# Calculate progress through the day (0.0 to 1.0)
	var day_progress = (total_duration - current_time_remaining) / total_duration
	
	# Peak efficiency at middle of day (parabolic curve)
	var efficiency = BASE_SOLAR_EFFICIENCY * (1.0 - pow(2.0 * (day_progress - 0.5), 2))
	return max(0.0, efficiency) # Ensure we never return negative efficiency

func update_power_generation():
	var total_generation = 0.0
	var efficiency = get_current_solar_efficiency()
	
	# Calculate total power generation from all solar panels
	for panel in solar_panels:
		if is_instance_valid(panel):
			total_generation += panel.power_generation * efficiency
	
	current_solar_power = total_generation
	emit_signal("power_updated", current_solar_power, get_total_stored_power())

func _on_update_timer_timeout():
	if is_transitioning:
		return  # Skip power distribution during transitions
		
	var power_increment = (current_solar_power / 60.0) * UPDATE_INTERVAL
	if power_increment > 0:
		distribute_power(power_increment)
	emit_signal("power_updated", current_solar_power, get_total_stored_power())

func distribute_power(amount: float) -> void:
	# If no batteries, nowhere to store power
	if batteries.is_empty():
		return
		
	var remaining_power = amount
	
	# Try to distribute power evenly among batteries
	while remaining_power > 0:
		var power_per_battery = remaining_power / batteries.size()
		var total_added = 0.0
		
		for battery in batteries:
			if is_instance_valid(battery):
				var added = battery.add_charge(power_per_battery)
				total_added += added
		
		# If we couldn't add any more power, break
		if total_added == 0:
			break
			
		remaining_power -= total_added

func use_power(amount: float) -> bool:
	# During transition, only allow critical power usage
	if is_transitioning:
		# Either deny power requests during transition or limit them
		return false
	
	if batteries.is_empty():
		return false
		
	var power_needed = amount
	var power_drawn = 0.0
	
	# Try to draw power evenly from all batteries
	for battery in batteries:
		if is_instance_valid(battery):
			var drawn = battery.draw_charge(power_needed - power_drawn)
			power_drawn += drawn
			
			if power_drawn >= power_needed:
				emit_signal("power_updated", current_solar_power, get_total_stored_power())
				return true
	
	return false

func get_total_stored_power() -> float:
	var total = 0.0
	if batteries.is_empty():
		return total
		
	for battery in batteries:
		if is_instance_valid(battery):
			total += battery.current_charge
	return total

func get_max_storage() -> float:
	var total = 0.0
	for battery in batteries:
		if is_instance_valid(battery):
			total += battery.get_power_storage()
	return total
