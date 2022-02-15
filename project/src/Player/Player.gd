extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var TOP_SPEED = 35
export var ACCELERATION_RATE = 2
export var NATURAL_DECELERATION_RATE = 0.99
export var BRAKE_DECELERATION_RATE = 0.90

var velocity_log = []
var log_duration = 1.25
var log_length = 0 # set in ready
var log_vel_ave : Vector3 = Vector3.ZERO
var log_delta : Vector3 = Vector3.ZERO

const MAX_HEALTH = 5.0
var health = MAX_HEALTH
var hits = 0

var offset_ship_angle_frames : float = 50
var current_offset = 0
var ship_angle_frame : float = 0
var offset_ship_angle : float = 0
var ship_angle : float = 0
var prev_ship_angle : float = 0
var ship_roll_delta : float = 0
var prev_ship_roll_delta : float = 0
var roll_x : float = 0
var prev_roll_x : float = 0


#Camera movement modifiers
const ANGULAR_SPEED_MULTIPLIER = 5.5
var angular_speed = 0
var angular_smoothing = 0.80 # 0.95
var old_angular_speed = 0

var camera_height = 150 # 80
var camera_distance = 20 # 30

var viewport_size
var viewport_half_size
var mousePos
var cursorPos

var camera_vertical_half_fov
var camera_horizontal_half_fov
var camera_projection_vertical_half_size
var camera_projection_horizontal_half_size
var camera_plane_distance = 1
var freeze_camera = false
var focus_cursor = false


onready var _camera =  get_node("../Camera")
onready var _cursor =  get_node("../Cursor")
#onready var _sphere =  get_node("../MeshInstance")
onready var _grid=  get_node("../VisualGrid")

func _ready():
	
	log_length = floor(144.0 * log_duration)
	
	viewport_size = get_viewport().get_visible_rect().size
	viewport_half_size = viewport_size / 2.0
	get_viewport().warp_mouse(viewport_half_size)
	mousePos = viewport_half_size
	
	camera_height = _camera.transform.origin.y
	camera_distance = _camera.transform.origin.z
	var fov_radians = (_camera.fov/180) * PI
	camera_vertical_half_fov = fov_radians / 2.0
	camera_projection_vertical_half_size = camera_plane_distance * tan(camera_vertical_half_fov)
	camera_projection_horizontal_half_size = camera_projection_vertical_half_size * 16.0 / 9.0
	camera_horizontal_half_fov = atan(camera_projection_horizontal_half_size)
	
	#Set turret target
	var weapons = $Weapons.get_children()
	for weapon in weapons:
		if(weapon.has_method("set_target")):
			weapon.set_target(_cursor)

func _integrate_forces(state):
	accelerate(state)
	log_velocity(state)
	pass

func _process(delta):
	spin(delta)
	focus()
	camera_movement(delta)

func _physics_process(delta):
	shift()
	shoot(delta)

func reset_camera_angle():
	pass

func get_mouse(position2D: Vector2):
	var dropPlane  = Plane(Vector3(0, 1, 0), 0)
	var position3D = dropPlane.intersects_ray(
		_camera.project_ray_origin(position2D),
		_camera.project_ray_normal(position2D))
	
	return position3D

func accelerate(state):
	if Input.is_action_pressed("control"):
		state.linear_velocity *= BRAKE_DECELERATION_RATE
	
	if Input.is_action_pressed("up") or Input.is_action_pressed("down") or Input.is_action_pressed("left") or Input.is_action_pressed("right"):
		
		var direction = Vector2(0, 0)
		if Input.is_action_pressed("up"):
			direction.y += 1
		elif Input.is_action_pressed("down"):
			direction.y -= 1
		if Input.is_action_pressed("left"):
			direction.x += 1
		elif Input.is_action_pressed("right"):
			direction.x -= 1
		direction = direction.normalized()
		
		var angle = _camera.rotation.y + atan2(direction.x, direction.y)
		state.linear_velocity.x += (-sin(angle)) * ACCELERATION_RATE
		state.linear_velocity.z += (-cos(angle)) * ACCELERATION_RATE
		
		if state.linear_velocity.length() > TOP_SPEED:
			state.linear_velocity = state.linear_velocity.normalized() * TOP_SPEED
			pass
	else:
		state.linear_velocity *= NATURAL_DECELERATION_RATE
		pass

func get_log_delta():
	return log_delta

func log_velocity(state):
	velocity_log.push_front(state.linear_velocity)
	if velocity_log.size() > log_length:
		velocity_log.pop_back()
	
	var ave = Vector3.ZERO
	for vel in velocity_log:
		ave = ave + vel
	
	log_vel_ave = ave / velocity_log.size()
	
	var diff_sum = Vector3.ZERO
	diff_sum = velocity_log[velocity_log.size()-1] - velocity_log[0]
#	for i in range(velocity_log.size()-1):
#		diff_sum = diff_sum + (velocity_log[i+1] - velocity_log[i])
#	diff_sum = diff_sum / velocity_log.size()
	log_delta = log_vel_ave
	get_tree().call_group("GUI","updateGUI_4", [
		log_vel_ave,
		log_vel_ave.length(),
		log_delta,
		log_delta.length()
	])

func spin(delta):
	var z = linear_velocity.z
	var x = linear_velocity.x
	
	
	var t = .05
	
	get_tree().call_group("GUI","updateGUI", [
		ship_angle, 
		self.linear_velocity.length(),
		ship_roll_delta
	])
	# Get the angle when the rotation is locked
	if Input.is_action_just_pressed("lock_rotation"):
		offset_ship_angle = ship_angle + current_offset
		ship_angle_frame = offset_ship_angle_frames
	
	# Get the diffenence between old and new angles
	if Input.is_action_just_released("lock_rotation"):
		offset_ship_angle = offset_ship_angle - ship_angle
		#Make sure the new difference is within workable values, otherwise the angle jitters
		offset_ship_angle = fmod(offset_ship_angle + PI, 2*PI) - PI
		if offset_ship_angle > PI:
			offset_ship_angle -= 2*PI
		elif offset_ship_angle < -PI:
			offset_ship_angle += 2*PI
	
	if !Input.is_action_pressed("lock_rotation"):
		var offset = 0
		if ship_angle_frame > 0:
			offset = offset_ship_angle * pow(ship_angle_frame/offset_ship_angle_frames, 2)
			ship_angle_frame = ship_angle_frame - 1
#		var angle = ship_angle + offset
		var i = 0.7
		var diff = prev_ship_angle - ship_angle
		while(diff < -PI):
			diff += 2*PI
		while(diff > PI):
			diff -= 2*PI
#		if abs(diff) > PI/2:
#			get_tree().call_group("GUI","updateGUI_3", [
#					diff
#				])
		ship_angle = ship_angle * (1-i) + (ship_angle + diff) * i
		var angle = ship_angle + offset
		current_offset = offset
		$Body.rotation.y = angle
		
		prev_ship_angle = ship_angle
		if (self.linear_velocity.length_squared () > 0.00000001):
			ship_angle = atan2(x, z) - PI
		ship_angle = fmod(ship_angle + PI, 2*PI) - PI

		prev_ship_roll_delta = ship_roll_delta
		ship_roll_delta = (clamp((ship_angle - prev_ship_angle) * 10.0, -PI/4, PI/4) * t) + (prev_ship_roll_delta * (1.0 - t))
		$Body.rotation.z = ship_roll_delta
#		if ship_angle - prev_ship_angle > PI || ship_angle - prev_ship_angle < -PI:
#			get_tree().call_group("GUI","updateGUI_4", [
#				ship_angle - prev_ship_angle
#			])
		$CollisionShape.rotation.y = angle
		$Weapons.rotation.y = angle
	else:
		prev_roll_x = roll_x
		roll_x = -x * cos(ship_angle) + z * sin(ship_angle)
		
		prev_ship_roll_delta = ship_roll_delta
		ship_roll_delta = (clamp(((roll_x / TOP_SPEED) + (roll_x - prev_roll_x)) * PI/4, -PI/4, PI/4) * t) + (prev_ship_roll_delta * (1.0 - t))
		$Body.rotation.z = ship_roll_delta

func shift():
	if Input.is_action_just_pressed("shift"):
		freeze_camera = true
	if Input.is_action_just_released("shift"):
		freeze_camera = false

func shoot(delta):
	var weapons = $Weapons.get_children()
	
	if Input.is_action_pressed("secondary_shoot"):
		for weapon in weapons:
			if(weapon.has_method("_shoot")):
				weapon._shoot(delta)
			
	
	if Input.is_action_pressed("primary_shoot"):
		get_mouse(get_viewport().get_mouse_position())
		for weapon in weapons:
			if(weapon.has_method("_aim_shoot")):
				weapon._aim_shoot(delta)

func focus():
	if Input.is_action_just_pressed("focus"):
		focus_cursor = !focus_cursor

func camera_movement(delta): 
	#Get the difference between the angle in degrees, then convert into radians
	var position3D = _cursor.translation
	var angular_diff = atan2(self.global_transform.origin.x - position3D.x, 
		 self.global_transform.origin.z - position3D.z) - _camera.rotation.y
	
	#Make sure the new difference is within workable values, otherwise the angle jitters
	angular_diff = fmod(angular_diff + PI, 2*PI) - PI
	if angular_diff > PI:
		angular_diff -= 2*PI
	elif angular_diff < -PI:
		angular_diff += 2*PI
	
	var rotation_threshold = 0
	rotation_threshold = (rotation_threshold * PI) / (180 * 2)
	if abs(angular_diff) < rotation_threshold:
		angular_diff = 0
	elif angular_diff > 0:
		angular_diff -= rotation_threshold
	elif angular_diff < 0:
		angular_diff += rotation_threshold
	
	if freeze_camera:
		angular_diff = 0
	
	angular_speed = angular_diff * delta * ANGULAR_SPEED_MULTIPLIER
	angular_speed = (angular_speed * (1 - angular_smoothing)) + (old_angular_speed * angular_smoothing)
	
	_camera.rotation.y += angular_speed
	old_angular_speed = angular_speed
	
	_camera.translation = Vector3(
		translation.x + camera_distance * sin(_camera.rotation.y),
		camera_height, 
		translation.z + camera_distance * cos(_camera.rotation.y))
	
	if !focus_cursor:
		_cursor.translation += self.linear_velocity * delta
	
	#Camera view plane, 1m from the camera will receive the projection from the new mouse location while the camera turns
	var distance = -camera_plane_distance
	var camera_view_plane_origin = Vector3(_camera.transform.origin.x + distance * _camera.transform.basis.z.x,
	_camera.transform.origin.y + distance * _camera.transform.basis.z.y,
	_camera.transform.origin.z + distance * _camera.transform.basis.z.z)
	var camera_view_plane_normal = (camera_view_plane_origin - _camera.transform.origin)
	var d = camera_view_plane_normal.x * camera_view_plane_origin.x + camera_view_plane_normal.y * camera_view_plane_origin.y + camera_view_plane_normal.z * camera_view_plane_origin.z
	var camera_view_plane = Plane(camera_view_plane_normal, d)
	var new_mouse_position3D = camera_view_plane.intersects_ray(_cursor.transform.origin, (_camera.transform.origin - _cursor.transform.origin))
#	_sphere.transform.origin = new_mouse_position3D
	
	# Get the transform matrix of the camera, get the position of the point relative to the projection plane origin
	var a = _camera.transform.basis
	var projection_position3D = new_mouse_position3D - camera_view_plane_origin
	
	# Get the point position in the plane vector space, should have z = 0
	var new_mouse_plane_coordinates = Vector3()
	new_mouse_plane_coordinates.x =  projection_position3D.x * a.x.x + projection_position3D.y * a.x.y + projection_position3D.z * a.x.z
	new_mouse_plane_coordinates.y =  projection_position3D.x * a.y.x + projection_position3D.y * a.y.y + projection_position3D.z * a.y.z
	new_mouse_plane_coordinates.z =  projection_position3D.x * a.z.x + projection_position3D.y * a.z.y + projection_position3D.z * a.z.z
	
	#Get the viewport coordinates of the point
	var x = ((new_mouse_plane_coordinates.x + camera_projection_horizontal_half_size) / (camera_projection_horizontal_half_size * 2)) * 1920
	var y = ((new_mouse_plane_coordinates.y + camera_projection_vertical_half_size) / (camera_projection_vertical_half_size * -2) + 1) * 1080
	
	var mousePos_delta = (get_viewport().get_mouse_position() - viewport_half_size) * (1.0/144.0) * 80
	get_viewport().warp_mouse(viewport_half_size)
	
	# the speed at which the cursor will not get dragged along with the camera
	var ignore_cursor_correction_speed = 10
	if mousePos_delta.length() < ignore_cursor_correction_speed:
		var t = mousePos_delta.length() / ignore_cursor_correction_speed
		t = pow(t, 0.5)
		mousePos =  (1 - t) * Vector2(x, y) + t * mousePos
	
	mousePos += mousePos_delta
	mousePos = Vector2(clamp(mousePos.x, 0, viewport_size.x), clamp(mousePos.y, 0, viewport_size.y))
	
	_cursor.transform.origin = self.get_mouse(mousePos)

func damage(damage : float):
	health -= damage


func _on_Player_body_entered(body):
	hits += 1
#	get_tree().call_group("GUI", "updateGUI_4", [
#		hits
#	])
