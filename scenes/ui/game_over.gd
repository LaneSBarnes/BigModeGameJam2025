extends Control

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("Game over screen ready")
	print("Initial visibility: ", visible)
	print("Process mode: ", process_mode)

func show_game_over():
	print("Show game over called")
	visible = true
	print("Setting visibility to: ", visible)
	print("Current tree paused state: ", get_tree().paused)
	get_tree().paused = true
	print("New tree paused state: ", get_tree().paused)

func _on_restart_button_pressed():
	print("Restart pressed")
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_button_pressed():
	print("Quit pressed")
	get_tree().quit()
