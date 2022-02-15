extends CanvasLayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("GUI")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if delta > 0:
		$Control/VBoxContainer/FPS.text = str((1/delta))
	pass

func updateGUI(data):
	$Control/VBoxContainer/Data1.text = ""
	for string in data:
		$Control/VBoxContainer/Data1.text += str(string , "\n")

func updateGUI_2(data):
	$Control/VBoxContainer/Data2.text = ""
	for string in data:
		$Control/VBoxContainer/Data2.text += str(string , "\n")

func updateGUI_3(data):
	$Control/VBoxContainer/Data3.text = ""
	for string in data:
		$Control/VBoxContainer/Data3.text += str(string , "\n")
	
func updateGUI_4(data):
	$Control/VBoxContainer/Data4.text = ""
	for string in data:
		$Control/VBoxContainer/Data4.text += str(string , "\n")
	
