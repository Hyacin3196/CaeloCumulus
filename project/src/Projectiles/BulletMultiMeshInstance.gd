extends MultiMeshInstance


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var pool_size = {"bullet": 1000}

# array of indices
var inactive_bullet_pool = {}
var active_bullet_pool = {}

var velocities:Array
var max_vel= 1.0 # 1000.0

var material:Material

# Called when the node enters the scene tree for the first time.
func _ready():
	for key in pool_size.keys():
		var size = pool_size[key]
		inactive_bullet_pool[key] = []
		active_bullet_pool[key] = []
		for i in size:
			inactive_bullet_pool[key].append(i)
	
	for i in range(1000):
		
		velocities.append(Vector2(rand_range(-1, 1), rand_range(-1, 1)))
		var x = rand_range(-100,100)
		var z = rand_range(-100,100)
		self.multimesh.set_instance_transform(i, Transform(Basis(), Vector3(x, 0, z)))
	
	material = multimesh.mesh.surface_get_material(0)
	var img = Image.new()
	img.create(pool_size['bullet'], 1, false, Image.FORMAT_RGBAF)
	
	img.lock()
	for i in range(pool_size['bullet']):
		var vec = Color(velocities[i].x, velocities[i].y, 0, 0)
		img.set_pixel(i, 0, vec)
	img.unlock()
	#color has 4 float values, r ang g can be for velocity, b and a can be for things like sine
	
	var vel_tex = ImageTexture.new()
	vel_tex.create_from_image(img)
	material.set_shader_param("vel_tex", vel_tex)
	material.set_shader_param("max_vel", max_vel)


#set pixel for every time a bullet is armed, get texture, get image data, edit pixel.
func arm_bullet(bullet_type:String, vel: Vector3): #add vel parameter, add extra parameters later
	var bullet_id = inactive_bullet_pool[bullet_type].pop_back()
	
	active_bullet_pool[bullet_type].push_back(bullet_id)
	
	var img = material.get_shader_param("vel_tex").get_data()
	img.set_pixel(bullet_id, 0, Color(vel.x, vel.z, 0, 1.0))
	#look for inactive pixel by looking up indices of inactive bullets
	#if bullets exceed pool size, double pool and vector array
	# shader-side, bullet is active when Color.a is 1
	#shader needs a t parameter because they dont remember previous VERTEX values

func disarm_bullet(bullet_type:String, bullet_id:int):
	var index = active_bullet_pool[bullet_type].find(bullet_id)
	active_bullet_pool[bullet_type].remove(index)
	inactive_bullet_pool[bullet_type].push_back(bullet_id)
	
	var img = material.get_shader_param("vel_tex").get_data()
	img.set_pixel(bullet_id, 0, Color(0, 0, 0, 0))

func resize_vel_img():
	pass

func _process(delta):
	pass
