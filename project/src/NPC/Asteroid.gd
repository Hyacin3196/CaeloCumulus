extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const MAX_HEALTH = 50.0
var _sprite_length = 500.0
var _health = MAX_HEALTH

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	pass

func damage(damage: float):
	_health -= damage
	var health_remaining = _health / MAX_HEALTH
	$Sprite3D.show()
	$Sprite3D.scale.y = _sprite_length * health_remaining
	
	if _health <= 0:
		$Sprite3D.hide()
		$AnimationPlayer.play("die")
		$CollisionShape.disabled = true

func die():
	queue_free()
