extends Node2D

class_name OuterRimBehaviour

var core_holders:Array[Node2D]
var _held_cores: Array[MandalaCoreBehaviour]
@onready var _holders = $Holders
@onready var _frame:Sprite2D = $Frame

@export var rotation_speed = 0.025
# Called when the node enters the scene tree for the first time.
func _ready():
	for child in _holders.get_children():
		if child is Node2D:
			core_holders.append(child)
			
	_frame.material.set_shader_parameter("alpha", 0.0)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var current_rotation = _holders.get_rotation()
	_holders.set_rotation(current_rotation + (delta * rotation_speed))
	
func adopt_cores(new_cores:Array[MandalaCoreBehaviour]):
	# delete any current cores
	# take the the new cores and then move them under the wing of the core_holders
	# TODO - animate this
	for held_core in _held_cores:
		held_core.queue_free()
	
	_held_cores.clear()
		
	var move_tween = create_tween().set_parallel(true)
	for core_index in range(0, new_cores.size()):
		var core_holder = core_holders[core_index]
		var new_core = new_cores[core_index]
		
		prints("Adopting core", core_index)
		
		new_core.reparent(core_holder, true)
		move_tween.tween_property(new_core, "position", Vector2.ZERO, 1.0).set_ease(Tween.EASE_OUT)
		move_tween.tween_property(new_core, "scale", Vector2.ONE, 1.0)
		move_tween.tween_property(new_core, "rotation", 0, 1.0)
		move_tween.tween_method(new_core.alpha, 0.0, 1.0, 1.0)
 
		_held_cores.append(new_core)
		
	if new_cores.size() > 0:
		move_tween.tween_property(_frame, "material:shader_parameter/alpha", 1.0, 2.0)
		 


