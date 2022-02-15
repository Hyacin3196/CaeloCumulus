extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var _active = true
export var _shot_interval = 0.05
export var _bullet_speed_max : float = 40
export var _bullet_speed_min : float = 30
export var _bullet_range : float = 75
export var _bullet_spread = 0.05
export var _bullet_mass = 0.05
export var _collision_layer = 0b0
export var _collision_mask = 0b0 

var _bullet_delay = _shot_interval

onready var _player = get_parent().get_parent()
onready var _parent = get_parent()
onready var _bullet_factory = get_tree().get_root().get_child(0).get_node("./BulletFactory")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	if(_bullet_delay > 0):
		_bullet_delay -= delta
	pass


func _shoot(delta : float):
	if(_active):
		while(_bullet_delay <= 0):
			_bullet_delay += _shot_interval
			$AudioStreamPlayer3D.play()

			var angle = get_parent().rotation.y
			var spread = rand_range(-1, 1)
			spread = pow(rand_range(-1, 1), 2) * _bullet_spread * sign(spread)
			angle += spread

			var t = 1 - pow(randf(), 1.5)
			var bullet_speed = _bullet_speed_max * t + _bullet_speed_min * (1-t)
			var velocity = Vector3(
				-sin(angle) * bullet_speed,
				0,
				-cos(angle) * bullet_speed)
				
			var position =  velocity * delta + _player.translation + Vector3(
				_parent.transform.basis.x.x*self.translation.x + _parent.transform.basis.z.x*self.translation.z,
				self.translation.y,
				_parent.transform.basis.x.z*self.translation.x + _parent.transform.basis.z.z*self.translation.z)

			var bullet_lifespan = _bullet_range / bullet_speed

			_bullet_factory.ShootBullet("wave_bullet", position, velocity, bullet_lifespan, _collision_mask, _bullet_mass)
