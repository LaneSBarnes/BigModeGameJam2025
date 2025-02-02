extends Node

signal power_updated(solar_power: float, stored_power: float)

var solar_panels: Array[SolarPanel] = []
var batteries: Array[Battery] = []
var current_solar_power: float = 0.0
var current_time_remaining: float = 0.0
var is_currently_day: bool = true
var is_transitioning: bool = false

const UPDATE_INTERVAL = 0.5
const BASE_SOLAR_EFFICIENCY = 1.0
const MIN_SOLAR_EFFICIENCY = 0.0
const MIN_USABLE_POWER = 0.3  
const TRANSITION_DURATION = 0.5

@onready var day_night_manager = get_parent().get_node("DayNightManager")
@onready var update_timer = Timer.new()
@onready var transition_timer = Timer.new()

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
	print("Transition complete")
	print("Current solar power: ", current_solar_power)
	print("Solar efficiency: ", get_current_solar_efficiency())
	is_transitioning = false
	update_power_generation()
	print("Power after transition: ", current_solar_power)
	print("Total stored power: ", get_total_stored_power())

func _on_day_started():
	print("Day started - Transitioning: ", is_transitioning)
	print("Current solar power before: ", current_solar_power)
	is_transitioning = true
	is_currently_day = true
	update_power_generation()
	transition_timer.start(TRANSITION_DURATION)
	print("Current solar power after update: ", current_solar_power)
	print("Total stored power: ", get_total_stored_power())


func _on_night_started():
	is_transitioning = true
	is_currently_day = false
	update_power_generation()
	transition_timer.start(TRANSITION_DURATION)

func register_solar_panel(panel: Node2D) -> void:
	if panel is SolarPanel:
		if panel not in solar_panels:
			solar_panels.append(panel)
			update_power_generation()

func register_battery(battery: Node2D) -> void:
	if battery is Battery:
		if battery not in batteries:
			batteries.append(battery)
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
		
	var total_duration = day_night_manager.DAY_DURATION
	
	var day_progress = (total_duration - current_time_remaining) / total_duration
	
	var efficiency = BASE_SOLAR_EFFICIENCY * (1.0 - pow(2.0 * (day_progress - 0.5), 2))
	efficiency = max(0.0, efficiency)
	return efficiency
func update_power_generation():
	var total_generation = 0.0
	var efficiency = get_current_solar_efficiency()
	
	for panel in solar_panels:
		if is_instance_valid(panel):
			total_generation += panel.power_generation * efficiency
	
	current_solar_power = total_generation
	emit_signal("power_updated", current_solar_power, get_total_stored_power())

func _on_update_timer_timeout():
	var power_increment = (current_solar_power / 60.0) * UPDATE_INTERVAL
	print("Update timer - Power increment: ", power_increment)
	print("Current solar power: ", current_solar_power)
	print("Is transitioning: ", is_transitioning)
	
	if power_increment > 0:
		var before_stored = get_total_stored_power()
		distribute_power(power_increment)
		var after_stored = get_total_stored_power()
		print("Power distributed - Before: ", before_stored, " After: ", after_stored)
	
	emit_signal("power_updated", current_solar_power, get_total_stored_power())

func distribute_power(amount: float) -> void:
	if batteries.is_empty():
		return
		
	var remaining_power = amount
	var total_added = 0.0
	
	# Sort batteries by how much space they have left
	var sorted_batteries = batteries.duplicate()
	sorted_batteries.sort_custom(func(a, b): 
		return (a.power_storage - a.current_charge) > (b.power_storage - b.current_charge)
	)
	
	# Distribute power to batteries with most space first
	for battery in sorted_batteries:
		if is_instance_valid(battery):
			var added = battery.add_charge(remaining_power)
			total_added += added
			remaining_power -= added
			
			if remaining_power <= 0:
				break

func use_power(amount: float) -> bool:
	if batteries.is_empty():
		return false
		
	# Don't allow power usage if total stored power is too low
	if get_total_stored_power() < MIN_USABLE_POWER:
		return false
		
	var power_needed = amount
	var power_drawn = 0.0
	
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
