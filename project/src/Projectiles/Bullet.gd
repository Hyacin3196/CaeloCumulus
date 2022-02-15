extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const DAMAGE = .5
var _collision_mask : int
var _damage = DAMAGE

# sets the color of the bullet
var _alive = false
onready var _timer = $Timer

signal disarm_signal(bullet_type, bullet)

func _init():
	pass

func _ready():
	_alive = true
	_timer.connect("timeout", self, "_timeout")
	#velocity * frame rate because its too slow otherwise

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	pass

func _timeout():
	self.on_collision()

func set_collision_mask(mask):
	_collision_mask = mask
	collision_mask = mask

func set_bullet_lifespan(lifespan):
	if lifespan < 0.01:
		lifespan = 0.01
	_timer.wait_time = lifespan

func start():
	_timer.start()

func on_collision():
	#queue_free()
	#emit signal to call bulletpool
	self.reset()
	self.emit_signal("disarm_signal", "bullet", self)

func reset():
	collision_mask = _collision_mask
	_damage = DAMAGE
	_alive = true
	self.angular_velocity = Vector3(0, 0, 0)
	_timer.start()

func _on_Bullet_body_entered(body):
	
	if body.has_method("damage"):
		body.damage(_damage)
	
	self.on_collision()
	pass # Replace with function body.
