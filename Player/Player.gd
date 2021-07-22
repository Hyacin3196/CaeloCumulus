extends KinematicBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const ROTATION_SPEED = 4
const BULLET_SHOOT_INTERVAL = 0.01
const BULLET_SPEED = 3
const SLOW_BRAKE_DECAY = 0.98
const FAST_BRAKE_DECAY = 0.96
const SLOW_ACCELERATION_RATE = 0.0015
const FAST_ACCELERATION_RATE = 0.003
const TOP_SPEED = 1
var acceleration_rate = SLOW_ACCELERATION_RATE
var brake_decay = SLOW_BRAKE_DECAY
var velocity = Vector3(0,0,0)


var bullet_delay = BULLET_SHOOT_INTERVAL

var camera_distance = 120

onready var _camera =  get_node("../Camera")

func _physics_process(delta):
	accelerate()
	spin(delta)
	shift()
	shoot(delta)
	get_tree().call_group("GUI","updateGUI", velocity, get_mouse())
	if move_and_collide(velocity) != null:
		print("Collision OMG!@$^%")
	_camera.translation = Vector3(translation.x, camera_distance, translation.z)
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
		
		velocity.x += (cos(rotation.y)) * acceleration_rate
		velocity.z += (-sin(rotation.y)) * acceleration_rate
		if velocity.length() > TOP_SPEED:
			velocity = velocity.normalized() * TOP_SPEED
			pass
	
	if Input.is_action_pressed("brake"):
		velocity = velocity * brake_decay

func spin(delta):
	if Input.is_action_pressed("left"):
		rotation.y += ROTATION_SPEED * delta
	elif Input.is_action_pressed("right"):
		rotation.y -= ROTATION_SPEED * delta
	

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
	
