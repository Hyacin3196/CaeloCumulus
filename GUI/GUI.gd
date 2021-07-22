extends CanvasLayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("GUI")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func updateGUI(velocity, mousePos, angle,angle2):
	$Control/VBoxContainer/Velocity.text = str(velocity)
	$Control/VBoxContainer/MouseLocation.text = str(mousePos)
	$Control/VBoxContainer/CameraAngle2.text = str(angle)
	$Control/VBoxContainer/CameraAngle.text = str(angle2)
	
