extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var _player = get_node("../Player")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var position = _player.translation
	position.x = 64.0 * floor(position.x / 64.0)
	position.z = 64.0 * floor(position.z / 64.0)
	translation = position
	pass
