extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if  delta > 1.0/144.0:
		#print(str(delta) + " - " + str(1.0/144.0))
		pass
		
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
		get_tree().call_group("Pause", "pause")
		queue_free()
		get_tree().quit()
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		queue_free()
		get_tree().quit()
