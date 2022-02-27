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

onready var _owner = get_parent().get_parent()
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
			
			var bullet = _bullet_factory.GetBullet()
			
			var angle = self.calculate_angle(self.global_transform.basis, _bullet_spread)
			
			var t = 1 - pow(randf(), 1.5)
			var bullet_speed = _bullet_speed_max * t + _bullet_speed_min * (1-t)
			var velocity = set_bullet_velocity(bullet, bullet_speed, angle)
			
			bullet.Position = velocity * delta + _owner.translation + Vector3(
				_parent.global_transform.basis.x.x * self.translation.x + _parent.global_transform.basis.z.x * self.translation.z,
				self.translation.y,
				_parent.global_transform.basis.x.z * self.translation.x + _parent.global_transform.basis.z.z * self.translation.z
			)
			
			var bullet_lifespan = _bullet_range / bullet_speed
			bullet.LifeSpan = bullet_lifespan
			
			bullet.Mask = _collision_mask
			bullet.Mass = _bullet_mass
			
			_bullet_factory.ShootBullet(bullet)

func calculate_angle(basis:Basis, max_spread:float) -> float:
	var angle = atan2(-(basis.z.x),-(basis.z.z))
	var spread = rand_range(-1, 1)
	spread = pow(abs(spread), 1.75) * max_spread * sign(spread)
	return angle + spread

func set_bullet_velocity(bullet, bullet_speed:float, angle:float) -> Vector3:
	var velocity = Vector3(
		sin(angle) * bullet_speed,
		0,
		cos(angle) * bullet_speed)
	bullet.Velocity = velocity
	return velocity
