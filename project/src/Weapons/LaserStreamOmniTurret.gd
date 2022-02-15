  extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const M_PI_4 = PI / 4.0
export var _active = true
export var _color : Color = Color(1, 1, 1, 1)
export var _shot_interval = 0.01
export var _bullet_speed_max : float = 40
export var _bullet_speed_min : float = 30
export var _bullet_range : float = 75
export var _bullet_spread = 0.05
export var _bullet_mass = 0.05
export var _collision_mask = 0b0
export var _leading_shots = false
export var _max_rot_speed = 0.001

var _previous_angle = 0;
var _laser_stream_index = -1
var _laser_stream_was_shot = true
var _bullet_delay = _shot_interval

onready var _owner = get_parent().get_parent()
onready var temp = get_tree().get_root().get_child(0).get_node("./Cursor2")
onready var _parent = get_parent()
#onready var _bullet_pool = get_tree().get_root().get_child(0).get_node("./BulletPool")
onready var _laser_stream_factory = get_tree().get_root().get_child(0).get_node("./LaserStreamFactory")

var _target = {}
var _cone = {}

func _ready():
	
	_cone['obj'] = _owner
	_cone['pos'] = Vector3(_cone['obj'].translation.x, 0, _cone['obj'].translation.z)
	_cone['axis'] = Vector3(0, 1, 0)
	_cone['cosThetaSqr'] = pow(cos(atan2(_bullet_speed_max, 1)), 2)
	_cone['isFinite'] = false
	_cone['hmin'] = 0
	_cone['hmax'] = INF
	
	_previous_angle = _parent.rotation.y

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float):
	if _target['obj'] != null:
		var target_coord = _target['obj'].translation
		
		if _leading_shots && _target['obj'] is RigidBody:
			var vel = _target['obj'].get("linear_velocity")
			
#			_target['vel'] = Vector3(
#				_target['obj'].linear_velocity.x,
#				1,
#				_target['obj'].linear_velocity.z)
			_target['vel'] = Vector3(
				_target['obj'].get_log_delta().x,
				1,
				_target['obj'].get_log_delta().z)
			_target['pos'] = _target['obj'].translation
			
			var values = $Spotter.FindIntersection(_target, _cone, [0.0, 0.0], [Vector3.ZERO, Vector3.ZERO])
			var t = values[0]
			var intersection = values[1]
			
			if intersection[0] != null: 
				temp.translation = Vector3(intersection[0].x, 0, intersection[0].z)
			elif intersection[1] != null: 
				temp.translation = Vector3(intersection[1].x, 0, intersection[1].z)
			
			target_coord = Vector3(intersection[0].x, 0, intersection[0].z)
		
#		var angular_diff = atan2(
#			self.global_transform.origin.x - target_coord.x, 
#			self.global_transform.origin.z - target_coord.z 
#			) - _parent.rotation.y - _previous_angle
#
#		angular_diff = fmod(angular_diff + PI, 2*PI) - PI
#		if angular_diff > PI:
#			angular_diff -= 2*PI
#		elif angular_diff < -PI:
#			angular_diff += 2*PI
##
#		angular_diff = clamp(angular_diff, -_max_rot_speed * delta, _max_rot_speed * delta)
		
		
#		self.rotation = Vector3(0, angular_diff, 0)
		
#		_previous_angle = self.rotation.y;
		#self.global_transform = Transform(Basis(Vector3(0,1,0), angular_diff + self.rotation.y), self.global_transform.origin) 
		
		
		var target_angle = atan2(
			self.global_transform.origin.x - target_coord.x, 
			self.global_transform.origin.z - target_coord.z 
			)
		
		var angular_diff = target_angle - _previous_angle
		angular_diff = fmod(angular_diff + PI, 2*PI) - PI
		if angular_diff > PI:
			angular_diff -= 2*PI
		elif angular_diff < -PI:
			angular_diff += 2*PI
		angular_diff = clamp(angular_diff, -_max_rot_speed * delta, _max_rot_speed * delta)
		
		self.global_transform = Transform(Basis(Vector3(0,1,0), angular_diff + _previous_angle), self.global_transform.origin) 
		
		_previous_angle = atan2(
			self.global_transform.basis.z.x, 
			self.global_transform.basis.z.z
			)
		
	else:
		_target['pos'] = Vector3.ZERO
	
	if _bullet_delay > 0:
		_bullet_delay -= delta
	pass

func _physics_process(delta):
	
	if(!_laser_stream_was_shot && _laser_stream_index > -1):
#		var angle = atan2(-(self.global_transform.basis.z.x),-(self.global_transform.basis.z.z))
		var angle = _previous_angle + PI
		var spread = rand_range(-1, 1)
		spread = pow(abs(spread), 1.75) * _bullet_spread * sign(spread)
		angle += spread
		
		var t = 1 - pow(randf(), 1.5)
		var bullet_speed = _bullet_speed_max * t + _bullet_speed_min * (1-t)
		var velocity = Vector3(
			sin(angle) * bullet_speed,
			0,
			cos(angle) * bullet_speed)
		
		var position = velocity * delta + _owner.translation + Vector3(
			_parent.global_transform.basis.x.x * self.translation.x + _parent.global_transform.basis.z.x * self.translation.z,
			self.translation.y,
			_parent.global_transform.basis.x.z * self.translation.x + _parent.global_transform.basis.z.z * self.translation.z)
		
		var bullet_lifespan = _bullet_range / bullet_speed
		_laser_stream_index = _laser_stream_factory.ShootLaser(self, _laser_stream_index, position, velocity, _color, bullet_lifespan, _collision_mask, false)
	_laser_stream_was_shot = false

func set_target(obj):
	_target['obj'] = obj


func _aim_shoot(delta : float):
	if(_active):
		while(_bullet_delay <= 0):
			_bullet_delay += _shot_interval
			$AudioStreamPlayer3D.play()
			
	#		var angle = atan2(-(self.global_transform.basis.z.x),-(self.global_transform.basis.z.z))
			var angle = _previous_angle + PI
			var spread = rand_range(-1, 1)
			spread = pow(abs(spread), 1.75) * _bullet_spread * sign(spread)
			angle += spread
			
			var t = 1 - pow(randf(), 1.5)
			var bullet_speed = _bullet_speed_max * t + _bullet_speed_min * (1-t)
			var velocity = Vector3(
				sin(angle) * bullet_speed,
				0,
				cos(angle) * bullet_speed)
			
			var position = velocity * delta + _owner.translation + Vector3(
				_parent.global_transform.basis.x.x * self.translation.x + _parent.global_transform.basis.z.x * self.translation.z,
				self.translation.y,
				_parent.global_transform.basis.x.z * self.translation.x + _parent.global_transform.basis.z.z * self.translation.z)
			
			var bullet_lifespan = _bullet_range / bullet_speed
			
			_laser_stream_index = _laser_stream_factory.ShootLaser(self, _laser_stream_index, position, velocity, _color, bullet_lifespan, _collision_mask, true)
		
		# flag for laser was fired but not shot 
		_laser_stream_was_shot = true

func fast_atan(x):
	return M_PI_4*x - x*(abs(x) - 1.0)*(0.2447 + 0.0663*abs(x));

