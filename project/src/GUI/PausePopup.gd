extends Popup


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var _player = get_node("../../Player")
onready var _continue = $ColorRect/Continue
onready var _restart = $ColorRect/Restart
onready var _quit = $ColorRect/Quit

var paused = false
var selected_menu = 0

func _ready():
	add_to_group("Pause")

func _input(event):
	if Input.is_action_just_pressed("pause"):
		if paused:
			#Unpause game
			hide()
			paused = false
			get_tree().paused = false
			_player.set_process_input(true)
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			
		else:
			pause()
			
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		match selected_menu:
			0:
				pass
			1:
				#Unpause game
				hide()
				paused = false
				get_tree().paused = false
				_player.set_process_input(true)
				Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			2:
				#Restart
				get_tree().paused = false
				get_tree().change_scene("res://project//src//Levels/Level.tscn")
			3:
				#Quit
				get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)

func pause(): 
	#reset selection
	selected_menu = 0
	reset_color()
	#Pause game
	popup()
	paused = true
	get_tree().paused = true
	_player.set_process_input(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func reset_color():
	_continue.color = Color("9d0d1948")
	_restart.color = Color("9d0d1948")
	_quit.color = Color("9d0d1948")

func _on_Continue_mouse_entered():
	selected_menu = 1
	_continue.color = Color("9d19bcad")
	pass # Replace with function body.


func _on_Restart_mouse_entered():
	selected_menu = 2
	_restart.color = Color("9d19bcad")
	pass # Replace with function body.


func _on_Quit_mouse_entered():
	selected_menu = 3
	_quit.color = Color("9d19bcad")
	pass # Replace with function body.


func _on_Continue_mouse_exited():
	selected_menu = 0
	_continue.color = Color("9d0d1948")
	pass # Replace with function body.


func _on_Restart_mouse_exited():
	selected_menu = 0
	_restart.color = Color("9d0d1948")
	pass # Replace with function body.


func _on_Quit_mouse_exited():
	selected_menu = 0
	_quit.color = Color("9d0d1948")
	pass # Replace with function body.

