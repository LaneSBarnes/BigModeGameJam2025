extends Node

signal day_started
signal night_started
signal cycle_tick(time_remaining: float, is_day: bool)

const DAY_DURATION = 30.0  # 30 seconds for testing
const NIGHT_DURATION = 30.0  # 30 seconds for testing

var is_day: bool = true
var time_remaining: float = DAY_DURATION
var cycle_count: int = 1

func _ready():
	start_day()

func _process(delta):
	time_remaining -= delta
	emit_signal("cycle_tick", time_remaining, is_day)
	
	if time_remaining <= 0:
		if is_day:
			start_night()
		else:
			start_day()

func start_day():
	is_day = true
	time_remaining = DAY_DURATION
	emit_signal("day_started")
	print("Day " + str(cycle_count) + " started")

func start_night():
	is_day = false
	time_remaining = NIGHT_DURATION
	emit_signal("night_started")
	print("Night " + str(cycle_count) + " started")
	cycle_count += 1

func get_cycle_progress() -> float:
	var total_duration = is_day if DAY_DURATION else NIGHT_DURATION
	return 1.0 - (time_remaining / total_duration)

func get_current_cycle() -> int:
	return cycle_count
