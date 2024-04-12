extends Node2D
class_name MandalaBehaviour

@export var glpyhs:Dictionary
@export var glyph_colors:Dictionary

@export var packed_core: PackedScene

@onready var core:MandalaCoreBehaviour = $Core
@onready var inner_rim:InnerRimBehaviour = $InnerRim
@onready var outer_rim:OuterRimBehaviour = $OuterRim

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func add_glyph(glyph_name:String):
	var image_name = glpyhs[glyph_name]
	var image:CompressedTexture2D = load(image_name)
	var image_tint = glyph_colors[glyph_name]
	print("Adding image", image)

	core.add_glyph(image, image_tint)
	
func fill_inner_core():
	core.fill_inner_core()

func clone_core_outwards():
	outer_rim.adopt_cores(inner_rim.remove_held_cores())
	inner_rim.clone_core(core, packed_core)

func move_core_outwards():
	outer_rim.adopt_cores(inner_rim.remove_held_cores())
	inner_rim.clone_core(core, packed_core)
	core.clear_glyphs()
	
func clear_core():
	core.clear_glyphs()
