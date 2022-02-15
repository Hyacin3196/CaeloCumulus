extends ImmediateGeometry

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var _trail_interval : float = 1
export var _trail_width : float = .5
var _trail_position = PoolVector3Array()
var _trail_direction = PoolVector3Array()
var _max_trail_length = 0

export var _frame_skips : int = 0
var _skipped_frames : int = _frame_skips

export var _color1 : Color = Color.from_hsv(1, 1, 1, 1)
export var _color2 : Color = Color.from_hsv(1, 1, 1, 1)
# true for goin up, false for going down in hue value
#export var _hue_polarity : bool
var _trail_colors = PoolColorArray()
var _color_cycle = PoolColorArray()
var _color_index = 0
var _color_cycle_length
export var _color_cycling : bool = true
export var _mirror_cycle : bool = false
export var _cycle_scale : float = 1.0
export var _cycle_speed : float = 1.0
var _cycle_speed_theta : float = 0

export var _hue1 : float = -1
export var _sat1 : float = -1
export var _val1 : float = -1
export var _alph1 : float = -1
export var _hue2 : float = -1
export var _sat2 : float = -1
export var _val2 : float = -1
export var _alph2 : float = -1


var debug
# Speed Trail is meant to to work as a child of the RigidBody producing the speed trail
onready var _trail_producer : RigidBody = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
	#Calculate _max_trail_length
	_max_trail_length = round(_trail_interval * 144.0 / float(_frame_skips + 1))
	
	for i in _max_trail_length:
		_trail_position.append(Vector3.ZERO)
		_trail_direction.append(Vector3.ZERO)
	
	if _hue1 == -1:
		_hue1 = _color1.h
	if _sat1 == -1:
		_sat1 = _color1.s
	if _val1 == -1:
		_val1 = _color1.v
	if _alph1 == -1:
		_alph1 = _color1.a
		
	if _hue2 == -1:
		_hue2 = _color2.h
	if _sat2 == -1:
		_sat2 = _color2.s
	if _val2 == -1:
		_val2 = _color2.v
	if _alph2 == -1:
		_alph2 = _color2.a
	
	_color_cycle_length = (_max_trail_length * _cycle_scale)
	for i in _color_cycle_length:
		var t = float(i) / float((_color_cycle_length) - 1)
		_color_cycle.append(Color.from_hsv(
			_hue2 * (1-t) + _hue1 * t,
			_sat2 * (1-t) + _sat1 * t,
			_val2 * (1-t) + _val1 * t,
			_alph2 * (1-t) + _alph1 * t
		))
	
	if _mirror_cycle:
		for i in range(_color_cycle_length, 0, -1):
			var t = float(i) / float((_color_cycle_length) - 1)
			_color_cycle.append(Color.from_hsv(
				_hue2 * (1-t) + _hue1 * t,
				_sat2 * (1-t) + _sat1 * t,
				_val2 * (1-t) + _val1 * t,
				_alph2 * (1-t) + _alph1 * t
			))
	
	for i in _max_trail_length:
		_trail_colors.append(get_color())
#	if _hue2 < _hue1 and _hue_polarity:
#		_hue2 += 1
#	if _hue2 > _hue1 and !_hue_polarity:
#		_hue2 -= 1
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#Array of left and right Vertex pairs 0 for left, 1 for right
	var trail_vertices = []
	for i in range(1, _trail_direction.size() - 1):
		var left_offset = Vector3(_trail_direction[i].z, 0, -_trail_direction[i].x)
		var right_offset = Vector3(-_trail_direction[i].z, 0, _trail_direction[i].x)
		var left_position = _trail_position[i] + left_offset * (_trail_width * (i / _max_trail_length))
		var right_position = _trail_position[i] + right_offset * (_trail_width * (i / _max_trail_length))
		trail_vertices.append([left_position, right_position])
		#Reference
#		[1,2], [-2,1], [2,-1]
#		[-1,-2], [2,-1], [-2,1]
#		[1,-2], [2,1], [-2,-1]
#		[-1,2], [-2,-1], [2,1]
	# Clean up before drawing
	clear()
	
	# Begin Draw
	begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	set_normal(Vector3(0, 1, 0))
	set_color(_trail_colors[0])
	add_vertex(_trail_position[0])
	for i in trail_vertices.size():
#		var t = float(i + 1) / (_max_trail_length - 1)
#		var color = Color.from_hsv(
#			_hue2 * (1-t) + _hue1 * t,
#			_sat2 * (1-t) + _sat1 * t,
#			_val2 * (1-t) + _val1 * t,
#			_alph2 * (1-t) + _alph1 * t
#		)
		var color = _trail_colors[i + 1]
		set_normal(Vector3(0, 1, 0))
		set_color(color)
		add_vertex(trail_vertices[i][0])
		set_normal(Vector3(0, 1, 0))
		set_color(color)
		add_vertex(trail_vertices[i][1])

	set_normal(Vector3(0, 1, 0))
	set_color(_trail_colors[_trail_colors.size() - 1])
	add_vertex(_trail_position[_trail_position.size() - 1] + (_trail_direction[_trail_position.size() - 1] * _trail_width))
	# End Draw
	end()

func _physics_process(delta):
	self.transform.origin = -_trail_producer.global_transform.origin
	_skipped_frames += 1
	if _skipped_frames > _frame_skips:
		_skipped_frames = 0
		# back end of the trail is at the index 0
		_trail_position.append(_trail_producer.global_transform.origin)
		while _trail_position.size() > _max_trail_length:
			_trail_position.remove(0)
		
		_trail_direction.append(_trail_producer.linear_velocity.normalized())
		while _trail_direction.size() > _max_trail_length:
			_trail_direction.remove(0)
		if _color_cycling:
			if _cycle_speed > 0:
				_cycle_speed_theta += _cycle_speed
				while _cycle_speed_theta > 0:
					_cycle_speed_theta -= 1
					_trail_colors.append(get_color())
				while _trail_colors.size() > _max_trail_length:
					_trail_colors.remove(0)
			else:
				_cycle_speed_theta += _cycle_speed
				while _cycle_speed_theta < 0:
					_cycle_speed_theta += 1
					_trail_colors.insert(0, get_color())
				while _trail_colors.size() > _max_trail_length:
					_trail_colors.remove(_max_trail_length)

func get_color():
	var color = _color_cycle[_color_index]
	_color_index = (_color_index + 1) % int(_color_cycle_length)
	return color
