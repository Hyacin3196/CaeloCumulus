extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var RADIANS_PER_SECOND = PI * 1
onready var _player = get_node("../Player")
onready var _camera2 = get_node("../ViewportContainer/Viewport/Camera")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.rotation.y += RADIANS_PER_SECOND * delta
	var pos = self.translation
	if _camera2 != null:
		_camera2.translation = Vector3(pos.x, pos.y + 20, pos.z)
	pass
