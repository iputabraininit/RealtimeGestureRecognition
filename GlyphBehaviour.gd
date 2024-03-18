extends Node2D
class_name GlyphBehaviour

@onready var glyph_sprite:Sprite2D = $GlyphSprite
@onready var _sparks = $RisingSparks

var _tint:Color

func _ready():
	pass


func _process(delta):
	pass
	
func get_glyph_tint() -> Color:
	return _tint
	
func set_glyph_sprite(sprite:CompressedTexture2D, tint:Color):
	if (glyph_sprite == null):
		glyph_sprite = $GlyphSprite
	glyph_sprite.texture = sprite
	glyph_sprite.material.set_shader_parameter("color", tint)
	_tint = tint 

func get_glyph_sprite() -> CompressedTexture2D:
	return glyph_sprite.texture
	
func set_emitting(emitting:bool):
	if (_sparks == null):
		print("Sparks particule is null")
		return
	_sparks.emitting = emitting

func alpha(alpha_value:float):
	glyph_sprite.material.set_shader_parameter("alpha", alpha_value)
	
