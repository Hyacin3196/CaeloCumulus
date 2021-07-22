extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const BULLET_LIFESPAN = 1.5
var damage = 5
var velocity
var timer

func _init():
	timer = Timer.new()
	add_child(timer)
	timer.autostart = true
	timer.wait_time = BULLET_LIFESPAN
	timer.connect("timeout", self, "_timeout")

func _ready():
	linear_velocity = velocity
	pass
	#velocity * frame rate because its too slow otherwise

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	pass

func _timeout():
	timer.queue_free()
	$AnimationPlayer.play("die")
	collision_mask = 0b0
	$Yellow.hide()
	$Red.show()

func _is_bullet():
	return true

func die():
	queue_free()

func _on_Bullet_body_entered(body):
	$AnimationPlayer.play("die")
	$Yellow.hide()
	$Red.show()
	pass # Replace with function body.
