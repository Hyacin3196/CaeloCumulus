extends KinematicBody

enum RookState {
	DETRANSFORMATION,
	CHARGE,
	TRANSFORMATION,
	ATTACK
}
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
# How long it take to transform and detransform
export var TRANSFORMATION_INTERVAL : float = 1.0
var _transformation_phase = 0

var _state = RookState.ATTACK

onready var _target_player = get_node("../Player")

# Called when the node enters the scene tree for the first time.
func _ready():
	#Set turret target
	var weapons = $Weapons.get_children()
	for weapon in weapons:
		if(weapon.has_method("set_target")):
			weapon.set_target(get_tree().get_root().get_child(0).get_node("./Player"))
	pass # Replace with function body.


func _physics_process(delta):
	var distance_to_target = _target_player.translation - self.translation
	if distance_to_target.length() > 20:
		move_and_slide(distance_to_target.normalized() * 0)
	
	
	var weapons = $Weapons.get_children()
	if distance_to_target.length() < 300:
		for weapon in weapons:
			if(weapon.has_method("_aim_shoot")):
				weapon._aim_shoot(delta)
	pass
