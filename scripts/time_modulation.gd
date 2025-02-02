extends CanvasModulate

# Day colors: Bright white -> Slight yellow -> Warm orange
var day_colors = [
	Color(1.0, 1.0, 1.0),  # Bright daylight
	Color(1.0, 0.95, 0.8),  # Warm afternoon
	Color(1.0, 0.85, 0.7)   # Evening/sunset
]

# Night colors: Deep blue -> Dark purple -> Dark blue
var night_colors = [
	Color(0.35, 0.35, 0.55),  # Twilight
	Color(0.25, 0.25, 0.45),  # Deep night
	Color(0.2, 0.2, 0.4) # Late night
]

var current_colors: Array
var current_index: int = 0
var transition_time: float = 0.0
var is_day: bool = true
var is_transitioning_cycle: bool = false
var cycle_transition_duration: float = 3.0  # Duration in seconds for day/night transition
var cycle_transition_time: float = 0.0
var previous_color: Color
var target_color: Color

@onready var day_night_manager = get_parent().get_node("DayNightManager")

func _ready():
	current_colors = day_colors
	color = current_colors[0]
	previous_color = color
	target_color = color
	
	if day_night_manager:
		day_night_manager.day_started.connect(_on_day_started)
		day_night_manager.night_started.connect(_on_night_started)
		day_night_manager.cycle_tick.connect(_on_cycle_tick)

func _on_day_started():
	start_cycle_transition(true)

func _on_night_started():
	start_cycle_transition(false)

func start_cycle_transition(to_day: bool):
	is_transitioning_cycle = true
	cycle_transition_time = 0.0
	is_day = to_day
	previous_color = color
	current_colors = day_colors if to_day else night_colors
	target_color = current_colors[0]
	current_index = 0
	transition_time = 0.0

func _process(delta):
	if is_transitioning_cycle:
		cycle_transition_time += delta
		var t = cycle_transition_time / cycle_transition_duration
		if t >= 1.0:
			is_transitioning_cycle = false
			color = target_color
		else:
			# Use ease_in_out for smoother transition
			var eased_t = ease(t, 2.0)  # You can adjust the 2.0 to change the easing curve
			color = previous_color.lerp(target_color, eased_t)

func _on_cycle_tick(time_remaining: float, _is_day: bool):
	if is_transitioning_cycle:
		return

	var total_duration = day_night_manager.DAY_DURATION if is_day else day_night_manager.NIGHT_DURATION
	var section_duration = total_duration / current_colors.size()
	
	# Calculate which color section we should be in
	var new_index = floor((total_duration - time_remaining) / section_duration)
	new_index = min(new_index, current_colors.size() - 1)
	
	if new_index != current_index:
		current_index = new_index
		transition_time = 0.0

	# Calculate transition between current and next color
	var current_color = current_colors[current_index]
	var next_color
	
	if current_index < current_colors.size() - 1:
		next_color = current_colors[current_index + 1]
	else:
		next_color = current_colors[current_index]  # Stay on last color
	
	# Update transition time
	transition_time += get_process_delta_time()
	var t = transition_time / section_duration
	t = min(t, 1.0)
	
	# Lerp between colors
	if not is_transitioning_cycle:
		color = current_color.lerp(next_color, t)
