extends Node2D

class_name InnerRimBehaviour

var core_holders:Array[Node2D]
var held_cores: Array[MandalaCoreBehaviour]
@onready var _holders_node = $Holders
@onready var _frame:Sprite2D = $Frame
@export var rotation_speed = 0.05
# Called when the node enters the scene tree for the first time.
func _ready():
	for child in _holders_node.get_children():
		if child is Node2D:
			core_holders.append(child)
	
	_frame.material.set_shader_parameter("alpha", 0.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var current_rotation = _holders_node.get_rotation()
	_holders_node.set_rotation(current_rotation + (delta * rotation_speed))
	
func clone_core(core_to_clone:MandalaCoreBehaviour, packed_core_scene:PackedScene):
	var move_tween = create_tween().set_parallel(true)
	
	var holder_index = 0
	for holder in core_holders:
		var cloned_core = packed_core_scene.instantiate()
		holder.add_child(cloned_core)
		#var cloned_core = core_to_clone.clone()
		cloned_core.clone_from(core_to_clone)
		cloned_core._rotating = false
		cloned_core.rotation = 0
	
		held_cores.append(cloned_core)
		cloned_core.set_global_position(core_to_clone.get_global_position())
		cloned_core.scale = Vector2(1.4, 1.4)
		
		cloned_core.alpha(0)
		move_tween.tween_property(cloned_core, "scale", Vector2.ONE, 0.7).set_delay(holder_index * 0.1)
		move_tween.tween_method(cloned_core.alpha, 0.0, 1.0, 0.7).set_delay(holder_index * 0.1)
		move_tween.tween_property(cloned_core, "position", Vector2.ZERO, 0.7).set_delay(holder_index * 0.1)
		holder_index += 1
	
	move_tween.tween_property(_frame, "material:shader_parameter/alpha", 1.0, 2.0)
	

func remove_held_cores() -> Array[MandalaCoreBehaviour]:
	var removed_cores:Array[MandalaCoreBehaviour] = []
	for held_core in held_cores:
		var core_holder = held_core.get_parent()
		#core_holder.remove_child(held_core)
		removed_cores.append(held_core)
		
	held_cores.clear()
	
	return removed_cores


