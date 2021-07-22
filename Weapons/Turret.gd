extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const BULLET_SHOOT_INTERVAL = 0.15
const BULLET_SPEED = 125

var bullet_delay = BULLET_SHOOT_INTERVAL

onready var _player = get_parent().get_parent()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	if(bullet_delay > 0):
		bullet_delay -= delta
	pass


func _shoot():
	if(bullet_delay <= 0):
		$AudioStreamPlayer3D.play()
		bullet_delay = BULLET_SHOOT_INTERVAL
		var new_bullet = load("res://Projectiles/Bullet.tscn").instance()
		new_bullet.rotation =  _player.rotation
		new_bullet.velocity = Vector3(
			-sin(_player.rotation.y) * BULLET_SPEED,
			0,
			-cos(_player.rotation.y)* BULLET_SPEED)
		new_bullet.translation =  new_bullet.velocity/120 + _player.translation + Vector3(
			_player.transform.basis.x.x*self.translation.x + _player.transform.basis.z.x*self.translation.z,
			self.translation.y,
			_player.transform.basis.x.z*self.translation.x + _player.transform.basis.z.z*self.translation.z)
#		new_bullet.velocity = _player.velocity + Vector3(
#			cos(_player.rotation.y) * BULLET_SPEED,
#			0,
#			-sin(_player.rotation.y)* BULLET_SPEED)
#		new_bullet.velocity = new_bullet.velocity.normalized() * BULLET_SPEED
#		new_bullet.rotation = Vector3(0, atan2(new_bullet.velocity.x, new_bullet.velocity.z),0)
		get_tree().get_root().get_child(0).add_child(new_bullet)
	
