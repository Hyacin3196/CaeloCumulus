extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const ROTATION_SPEED = 300
const BULLET_SHOOT_INTERVAL = 0.01
const BULLET_SPEED = 3
const SLOW_BRAKE_DECAY = 0.98
const FAST_BRAKE_DECAY = 0.96
const SLOW_ACCELERATION_RATE = 0.15
const FAST_ACCELERATION_RATE = 0.4
const TOP_SPEED = 75
var acceleration_rate = SLOW_ACCELERATION_RATE
var brake_decay = SLOW_BRAKE_DECAY

var rotation_direction = 0

var bullet_delay = BULLET_SHOOT_INTERVAL

var is_spiralling = false
var spiral_camera_intensity = 0.005

const ANGULAR_SPEED_MULTIPLIER = 5
var angular_speed = 0
var angular_smoothing = 0.7
var old_angular_speed = 0
var camera_height = 150
var camera_distance = 20

onready var _camera =  get_node("../Camera")
onready var _grid=  get_node("../VisualGrid")

func _ready():
	camera_height = _camera.transform.origin.y
	camera_distance = _camera.transform.origin.z

func _process(delta):
	#Get the difference between the angle in degrees, then convert into radians
	var angular_diff = rotation_degrees.y- _camera.rotation_degrees.y
	angular_diff = fmod(angular_diff + 180,360)  - 180
	angular_diff = angular_diff/180 * PI

	#Make sure the new difference is within workable values
	if angular_diff > PI:
		angular_diff -= 2*PI
	elif angular_diff < -PI:
		angular_diff += 2*PI

	
	angular_speed = angular_diff * delta * ANGULAR_SPEED_MULTIPLIER
	angular_speed = (angular_speed * (1 - angular_smoothing)) + (old_angular_speed * angular_smoothing)
	if not is_spiralling:
		_camera.rotation.y += angular_speed
		old_angular_speed = angular_speed
	else:
		_camera.rotation.y += old_angular_speed
	_camera.translation = Vector3(
		translation.x + camera_distance * sin(_camera.rotation.y),
		camera_height, 
		translation.z + camera_distance * cos(_camera.rotation.y))
	
	
	get_tree().call_group("GUI","updateGUI", linear_velocity, get_mouse(),0, 0)

func _physics_process(delta):
	accelerate()
	spin(delta)
	shift()
	shoot(delta)
	

func reset_camera_angle():
	pass

func get_mouse():
	var position2D = get_viewport().get_mouse_position()
	var dropPlane  = Plane(Vector3(0, 1, 0), 0)
	var position3D = dropPlane.intersects_ray(
		_camera.project_ray_origin(position2D),
		_camera.project_ray_normal(position2D))
	
	return position3D

func accelerate():
	#print(velocity.length())
	if Input.is_action_pressed("forward"):
		linear_velocity.x += (-sin(rotation.y)) * acceleration_rate
		linear_velocity.z += (-cos(rotation.y)) * acceleration_rate
		if linear_velocity.length() > TOP_SPEED:
			linear_velocity = linear_velocity.normalized() * TOP_SPEED
			pass
	
	if Input.is_action_pressed("brake"):
		linear_velocity = linear_velocity * brake_decay

func spin(delta):
	if Input.is_action_pressed("left"):
		is_spiralling = false
		rotation_direction = 1
		angular_velocity = Vector3( 0, ROTATION_SPEED * delta, 0)
#		rotation.y += ROTATION_SPEED * delta
	elif Input.is_action_pressed("right"):
		is_spiralling = false
		rotation_direction = -1
		angular_velocity = Vector3( 0, -ROTATION_SPEED * delta, 0)
#		rotation.y -= ROTATION_SPEED * delta
	elif Input.is_action_just_released("left") and rotation_direction == 1:
		rotation_direction = 0
		angular_velocity = Vector3( 0, 0, 0)
	elif Input.is_action_just_released("right") and rotation_direction == -1:
		rotation_direction = 0
		angular_velocity = Vector3( 0, 0, 0)

func shift():
	if Input.is_action_just_pressed("shift"):
		acceleration_rate = FAST_ACCELERATION_RATE
		brake_decay = FAST_BRAKE_DECAY
	if Input.is_action_just_released("shift"):
		acceleration_rate = SLOW_ACCELERATION_RATE
		brake_decay = SLOW_BRAKE_DECAY

func shoot(delta):
	if Input.is_action_pressed("secondary_shoot") || Input.is_mouse_button_pressed(BUTTON_RIGHT):
		var weapons = get_node("Weapons").get_children()
		for weapon in weapons:
			if(weapon.has_method("_shoot")):
				weapon._shoot()
			
	
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		get_mouse()
		var weapons = get_node("Weapons").get_children()
		for weapon in weapons:
			if(weapon.has_method("_aim_shoot")):
				weapon._aim_shoot()
	

func _on_RigidBodyPlayer_body_entered(body):
	is_spiralling = true
	
	old_angular_speed = rand_range(-spiral_camera_intensity, spiral_camera_intensity)
	pass # Replace with function body.
