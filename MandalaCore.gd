extends Node2D

class_name MandalaCoreBehaviour

@export var glyph_packed_scene:PackedScene
@onready var circular_frame:Sprite2D = $CircularFrame
#@onready var original_glyph:GlyphBehaviour = $Glyph 
@export var rotation_speed = 0.1

var _alpha = 0.0
var _glyphs:Array[GlyphBehaviour] = []
var _rotating:bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	circular_frame.visible = false
	pass # Replace with function body.

func get_glyphs() -> Array[GlyphBehaviour]:
	return _glyphs

func alpha(alpha_value:float):
	_alpha = alpha_value
	circular_frame.material.set_shader_parameter("alpha", alpha_value)
	
	for glyph in _glyphs:
		glyph.alpha(alpha_value)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _rotating:
		var current_rotation = get_rotation()
		set_rotation(current_rotation + (delta * rotation_speed))

func clear_glyphs():
	for glyph in _glyphs:
		glyph.queue_free()
	
	_glyphs.clear()
	
	var clear_glyph_tween = create_tween()
	clear_glyph_tween.tween_property(circular_frame, "material:shader_parameter/alpha", 0.0, 3.0)
	
func clone_from(original_core: MandalaCoreBehaviour):
	var original_glypys = original_core.get_glyphs()
	for original_glyph in original_glypys:
		add_glyph(original_glyph.get_glyph_sprite(), original_glyph.get_glyph_tint())
	
	alpha(original_core._alpha)

func add_glyph(glyph_image:CompressedTexture2D, glyph_tint:Color= Color.CORAL):
	var original_glyph = glyph_packed_scene.instantiate()

	add_child(original_glyph)
	_glyphs.append(original_glyph)
	
	var glyph_count = _glyphs.size()
	original_glyph.rotation_degrees = (glyph_count - 1) * 90
	
	
	original_glyph.set_emitting(true)
	original_glyph.set_glyph_sprite(glyph_image, glyph_tint)
	
	original_glyph.alpha(0.0)
	var frame_tween = create_tween() 
	#clone_glyph_tween.tween_property(original_glyph, "rotation_degrees",  (i * 90) + 90, 0.5 * i).set_delay(0.5 *i).set_ease(Tween.EASE_OUT)
	frame_tween.tween_method(original_glyph.alpha, 0.0,  1.0, 0.5 * (glyph_count -1 )).set_delay(0.5 * (glyph_count - 1)).set_ease(Tween.EASE_OUT)
	
	if glyph_count >= 4:
		_rotating = true
		circular_frame.visible = true
		
		frame_tween.tween_property(circular_frame, "material:shader_parameter/alpha", 1.0, 2.0)
		frame_tween.tween_property(circular_frame, "material:shader_parameter/blur", 0.0, 1)
		
	
func fill_inner_core():
	if _glyphs.is_empty() || _glyphs.size() >= 4:
		return 
	
	_rotating = true
	circular_frame.visible = true
	#circular_frame.modulate.a = 0
	circular_frame.material.set_shader_parameter("alpha", 0)
	circular_frame.material.set_shader_parameter("blur", 7)
	var clone_glyph_tween = create_tween().set_parallel(true)	
#
	var first_glyph = _glyphs[0] 
	if _glyphs.size() == 1:
		
		add_glyph(first_glyph.get_glyph_sprite(), first_glyph.get_glyph_tint())
		add_glyph(first_glyph.get_glyph_sprite(), first_glyph.get_glyph_tint())
		add_glyph(first_glyph.get_glyph_sprite(), first_glyph.get_glyph_tint())
	elif  _glyphs.size() == 2:
		var second_glyph = _glyphs[1]
		add_glyph(first_glyph.get_glyph_sprite(), first_glyph.get_glyph_tint())
		add_glyph(second_glyph.get_glyph_sprite(), second_glyph.get_glyph_tint())
	
	elif  _glyphs.size() == 3:
		var second_glyph = _glyphs[1]
		add_glyph(second_glyph.get_glyph_sprite(), second_glyph.get_glyph_tint())
	
	#clone_glyph_tween.tween_property(circular_frame, "modulate:a", 1, 5)
	clone_glyph_tween.tween_property(circular_frame, "material:shader_parameter/alpha", 1.0, 2.0)
	clone_glyph_tween.tween_property(circular_frame, "material:shader_parameter/blur", 0.0, 1)
