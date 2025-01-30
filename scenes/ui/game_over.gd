extends Control

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS  # Allow this UI to work while game is paused

func show_game_over():
	visible = true
	get_tree().paused = true

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_button_pressed():
	get_tree().quit()
