extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var initial_pool_size = {"bullet": 500}
var inactive_bullet_pool = {}
var active_bullet_pool = {}

onready var _BULLET = preload("res://project//src//Projectiles/Bullet.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	for key in initial_pool_size.keys():
		var pool_size = initial_pool_size[key]
		inactive_bullet_pool[key] = []
		active_bullet_pool[key] = []
		for i in pool_size:
			var bullet = _BULLET.instance()
			inactive_bullet_pool[key].append(bullet)
			bullet.connect("disarm_signal", self, "disarm_bullet")
	
	pass # Replace with function body.

func _process(delta):
	
	get_tree().call_group("GUI","updateGUI_2", [
		active_bullet_pool["bullet"].size() + inactive_bullet_pool["bullet"].size(),
		active_bullet_pool["bullet"].size(),
		inactive_bullet_pool["bullet"].size(),
	])

func arm_bullet(bullet_type: String):
	var bullet = inactive_bullet_pool[bullet_type].pop_front()
	
	if bullet == null:
		bullet = _BULLET.instance()
		bullet.connect("disarm_signal", self, "disarm_bullet")
	active_bullet_pool[bullet_type].append(bullet)
	bullet.set_process(true)
	get_tree().get_root().get_child(0).add_child(bullet)
	##https://godotengine.org/qa/49696/how-to-disable-enable-a-node
	return bullet

func disarm_bullet(bullet_type, bullet):
	var i = active_bullet_pool[bullet_type].find_last(bullet)
	if i != -1:
		active_bullet_pool[bullet_type].remove(i)
		inactive_bullet_pool[bullet_type].append(bullet)
		bullet.set_process(false)
		get_tree().get_root().get_child(0).remove_child(bullet)
	
	##https://godotengine.org/qa/49696/how-to-disable-enable-a-node
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _notification(what):
	pass
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
#		for bullet in active_bullet_pool['bullet']:
#			call_deferred("remove_child", bullet)
#		for bullet in inactive_bullet_pool['bullet']:
#			bullet.queue_free()
		queue_free()
#		get_tree().get_root().get_child(0).call_deferred("remove_child", self)


