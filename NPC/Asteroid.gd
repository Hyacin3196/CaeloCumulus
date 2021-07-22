extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const MAX_HEALTH = 50.0
var sprite_length = 500.0
var health = MAX_HEALTH

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	pass



func _on_Asteroids_body_entered(body):
	if body.get("damage"):
		health -= body.damage
		body.damage = 0
		var health_remaining = health / MAX_HEALTH
		$Sprite3D.show()
		$Sprite3D.scale.y = sprite_length * health_remaining
	
	if health <= 0:
		$Sprite3D.hide()
		$AnimationPlayer.play("die")
		$CollisionShape.disabled = true
	pass # Replace with function body.

func die():
	queue_free()
