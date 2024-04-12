extends Node

@export var mandala: MandalaBehaviour

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_H:
				print("Heart glyph")
				mandala.add_glyph("heart")
			if event.keycode == KEY_S:
				print("Star glyph")
				mandala.add_glyph("star")
			if  event.keycode == KEY_4:
				print("Filling up core with existing glyphs ")
				mandala.fill_inner_core()
			if 	event.keycode == KEY_UP:
				print("Cloning out")
				mandala.clone_core_outwards()
			if event.keycode == KEY_M:
				print("Moving clone out")
				mandala.move_core_outwards()
			if event.keycode == KEY_D:
				print("Clearing core")
				mandala.clear_core()
